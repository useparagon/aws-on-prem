import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

import chalk from 'chalk';
import * as commander from 'commander';
import { compareVersions } from 'compare-versions';
import { load as parseYaml } from 'js-yaml';

import { Microservice, ROOT_DIR, TERRAFORM_DIR, TERRAFORM_WORKSPACES_DIR } from '../constants';
import {
  DeployCLIOptions,
  HelmValues,
  TerraformEnv,
  TerraformOptions,
  TerraformWorkspace,
} from '../types';
import { execAsync, getVariablesFromEnvFile, isDocker, spawnAsync } from '../utils';

export abstract class BaseCLI {
  /**
   * the workspace to execute the Terraform commands on
   *
   * @abstract
   * @type {TerraformWorkspace}
   * @memberof BaseCLI
   */
  abstract workspace: TerraformWorkspace;

  /**
   * configures the cli program
   * @param program
   */
  configureProgram(program: commander.Command): void {
    program
      .addCommand(
        new commander.Command(`deploy-${this.workspace}`)
          .description('Deploy to AWS.')
          .requiredOption(
            '--debug [debug]',
            'Print additional debugging information',
            process.env.debug ?? 'false',
          )
          .requiredOption(
            '--initialize [initialize]',
            'Run `terraform init` before the deployment',
            process.env.initialize || 'true',
          )
          .requiredOption(
            '--plan [plan]',
            'Run `terraform plan` before the deployment',
            process.env.plan || 'true',
          )
          .requiredOption(
            '--apply [apply]',
            'Run `terraform apply`',
            process.env.destroy === 'true' ? 'false' : process.env.apply || 'true',
          )
          .requiredOption(
            '--destroy [destroy]',
            'Run `terraform destroy`',
            process.env.destroy || 'false',
          )
          .requiredOption(
            '--target [target]',
            'Optional target for operation',
            process.env.target || '',
          )
          .requiredOption(
            '--args [args]',
            'Optional arguments to pass to the operation',
            process.env.args ?? '',
          )
          .action(async (options: DeployCLIOptions): Promise<void> => {
            console.log(`ℹ️  Running deploy-${this.workspace}`, options);
            const {
              debug: _debug = 'false',
              initialize: _initialize = 'true',
              plan: _plan = 'true',
              apply: _apply = 'true',
              destroy: _destroy = 'false',
              target,
              args: _args,
            } = options;
            const debug: boolean = _debug === 'true' ? true : false;
            const initialize: boolean = _initialize === 'false' ? false : true;
            const plan: boolean = _plan === 'false' ? false : true;
            const apply: boolean = _apply === 'false' ? false : true;
            const destroy: boolean = _destroy === 'true' ? true : false;
            const args: string[] = _args.trim().length ? _args.trim().split(',') : [];
            const targets: string[] = target
              .trim()
              .split(',')
              .filter((target: string): boolean => target.length > 0)
              .map((target: string): string => target.trim());

            await this.runDeploy({
              debug,
              initialize,
              plan,
              apply,
              destroy,
              args,
              targets,
            });
          }),
      )
      .addCommand(
        new commander.Command(`state-${this.workspace}`)
          .description('Print the Terraform state as json.')
          .action(async (): Promise<void> => {
            await this.runStateOutput();
          }),
      )
      .addCommand(
        new commander.Command(`prepare-${this.workspace}`)
          .description('Prepare the Terraform vars.auto.tfvars file.')
          .action(async (): Promise<void> => {
            await this.runPrepare();
          }),
      );
  }

  /**
   * prepares Terraform vars for execution outside of Docker
   */
  async runPrepare(): Promise<void> {
    console.log('ℹ️  Executing runPrepare...');

    const env: TerraformEnv = await this.getTerraformEnv();
    await this.prepareTerraformVariables(env);

    console.log('✅ Executed runPrepare.');
  }

  /**
   * prints the terraform state as json
   */
  async runStateOutput(): Promise<void> {
    console.log('ℹ️  Executing runStateOutput...');

    const env: TerraformEnv = await this.getTerraformEnv();
    await this.configureTerraformToken(env);
    await this.prepareTerraformMainFile(env);
    await execAsync(
      `terraform -chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace} output -json`,
      process.env,
    );

    console.log('✅ Executed runStateOutput.');
  }

  /**
   * executes the deployment
   * @param options
   */
  async runDeploy(options: TerraformOptions): Promise<void> {
    console.log('ℹ️  Executing runDeploy...', options);

    const { initialize, plan, apply, destroy } = options;

    const env: TerraformEnv = await this.getTerraformEnv();
    await this.configureTerraformToken(env);
    await this.prepareTerraformMainFile(env);
    await this.prepareTerraformVariables(env);

    if (initialize) {
      await this.executeTerraformInit(options);
    } else {
      console.log('ℹ️  Skipping `terraform init`.');
    }

    if (plan && !destroy) {
      await this.executeTerraformPlan(options);
    } else {
      console.log('ℹ️  Skipping `terraform plan`.');
    }

    if (apply || destroy) {
      await this.executeTerraformApply(options);
    } else {
      console.log('ℹ️  Skipping `terraform apply`.');
    }
  }

  /**
   * gets the values from `.secure/.env-tf-{infra,paragon}` as an object
   */
  async getTerraformEnv(): Promise<TerraformEnv> {
    const values: TerraformEnv = (await getVariablesFromEnvFile(
      `${ROOT_DIR}/.secure/.env-tf-${this.workspace}`,
    )) as TerraformEnv;
    return values;
  }

  /**
   * writes the Terraform token to `~/.terraformrc`
   * @param env
   */
  async configureTerraformToken(env: TerraformEnv): Promise<void> {
    console.log('ℹ️  Configuring Terraform token...');

    if (!env.DISABLE_DOCKER_VERIFICATION && !isDocker()) {
      const errorMessage: string = chalk.red(
        'Please run this within docker to prevent overwriting your Terraform token.',
      );
      throw new Error(chalk.red(errorMessage));
    }

    const token: string = env.TF_TOKEN;
    const file: string = `
credentials "app.terraform.io" {
  token = "${token}"
}
    `.trim();
    const filePath: string = path.join(os.homedir(), '/.terraformrc');
    await fs.promises.writeFile(filePath, '');
    await fs.promises.writeFile(filePath, file, { encoding: 'utf8' });

    console.log('✅ Configured Terraform token.');
  }

  /**
   * copies the `main.tpl.tf` file into the workspace and replaces the placeholders
   * @param env
   */
  async prepareTerraformMainFile(env: TerraformEnv): Promise<void> {
    const { TF_ORGANIZATION, TF_WORKSPACE } = env;
    const templateFilePath: string = `${TERRAFORM_DIR}/templates/main.tpl.tf`;
    const inputFile: string = await fs.promises.readFile(templateFilePath, 'utf8');
    const outputFile: string = inputFile
      .replace(new RegExp('__TF_ORGANIZATION__', 'g'), TF_ORGANIZATION)
      .replace(new RegExp('__TF_WORKSPACE__', 'g'), TF_WORKSPACE);
    const outputFilePath: string = `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/main.tf`;

    await fs.promises.writeFile(outputFilePath, outputFile);
  }

  /**
   * writes the terraform config as variables in
   * @param env
   */
  async prepareTerraformVariables(env: TerraformEnv): Promise<void> {
    const variables: Record<string, any> = Object.keys(env).reduce(
      (transformed: Record<string, any>, key: string): Record<string, any> => ({
        ...transformed,
        [key.toLowerCase()]: (env as Record<string, any>)[key] as string,
      }),
      {},
    );

    // the helm workspace additionally needs a `helm_values` object
    if (this.workspace === TerraformWorkspace.PARAGON) {
      const helmValuesPath: string = `${ROOT_DIR}/.secure/values.yaml`;
      const helmValuesExists: boolean = fs.existsSync(helmValuesPath);
      if (helmValuesExists) {
        const helmValues: string = await fs.promises.readFile(helmValuesPath, 'utf-8');
        variables['helm_values'] = Buffer.from(helmValues).toString('base64');

        // periodically new microservices are introduced or removed
        // we need to provide which microservices are supported in the current version
        const paragonVersion: string | undefined = ((parseYaml(helmValues) as HelmValues) ?? {})
          .global?.env?.VERSION;
        variables['supported_microservices'] = this.getSupportedMicroservices(
          paragonVersion ? paragonVersion : 'latest',
        );
      }

      const helmEnvValues: Record<string, any> = await getVariablesFromEnvFile(
        `${ROOT_DIR}/.secure/.env-helm`,
      ).catch(() => ({}));
      variables['helm_env'] = Buffer.from(JSON.stringify(helmEnvValues)).toString('base64');
    }

    const outputFile: string = Object.keys(variables)
      .map((key: string): string => {
        const value: string =
          typeof variables[key] === 'string'
            ? `"${variables[key]}"`
            : JSON.stringify(variables[key], null, 2);
        return `${key}=${value}`;
      })
      .join('\n');
    await fs.promises.writeFile(
      `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/vars.auto.tfvars`,
      outputFile,
    );
  }

  /**
   * returns the microservices supported in the current Paragon version
   * @param paragonVersion the current Paragon version being deployed
   */
  getSupportedMicroservices(paragonVersion: string): Microservice[] {
    // if deploying a release candidate (e.g. `v2.77.0-rc-abc3d3`) or unstable version (e.g. `v2.77.0-unstable-abc3d3`)
    // we need to strip the end to compare the version
    const LATEST: 'latest' = 'latest';
    const isLatest: boolean = paragonVersion === LATEST;
    const sanitizedParagonVersion: string = paragonVersion.split('-rc')[0].split('-unstable')[0];
    const microservices: Microservice[] = Object.values(Microservice);
    return microservices.filter((microservice: Microservice): boolean => {
      // account was added in v3.4.3
      const hasAccount: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v3.4.3') >= 0;
      if (!hasAccount && Microservice.ACCOUNT === microservice) {
        return false;
      }

      // chronos was removed in v3.4.3
      const hasChronos: boolean =
        !isLatest && compareVersions(sanitizedParagonVersion, 'v3.4.3') < 0;
      if (!hasChronos && Microservice.CHRONOS === microservice) {
        return false;
      }

      // pheme was added in v2.64.1
      const hasPheme: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v2.64.0') >= 0;
      if (!hasPheme && Microservice.PHEME === microservice) {
        return false;
      }

      // hades was added in v2.67.1
      const hasHades: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v2.67.0') >= 0;
      if (!hasHades && Microservice.HADES === microservice) {
        return false;
      }

      // plato was added in v2.67.1 and removed in v2.94.3
      const hasPlato: boolean =
        !isLatest &&
        compareVersions(sanitizedParagonVersion, 'v2.67.0') >= 0 &&
        compareVersions(sanitizedParagonVersion, 'v2.94.3') < 0;
      if (!hasPlato && Microservice.PLATO === microservice) {
        return false;
      }

      // in v2.77.0, hercules was replaced with `worker-actions`, `worker-credentials`, etc
      const workersV1: Microservice[] = [
        Microservice.WORKER_ACTIONS,
        Microservice.WORKER_CREDENTIALS,
        Microservice.WORKER_CRONS,
        Microservice.WORKER_PROXY,
        Microservice.WORKER_TRIGGERS,
        Microservice.WORKER_WORKFLOWS,
      ];
      const hasWorkersV1: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v2.77.0') >= 0;
      if (!hasWorkersV1 && workersV1.includes(microservice)) {
        return false;
      } else if (hasWorkersV1 && microservice === Microservice.HERCULES) {
        return false;
      }

      // `release` and `worker-deployments` were introduced in v2.82.2
      const hasReleaseAndWorkerDeployments: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v2.82.2') >= 0;

      // filter unused microservices
      if (
        !hasReleaseAndWorkerDeployments &&
        [Microservice.RELEASE, Microservice.WORKER_DEPLOYMENTS].includes(microservice)
      ) {
        return false;
      }

      // `worker-actionkit` was introduced in v2024.1223.0735-1b63051b
      const hasWorkerActionKit: boolean =
        isLatest || compareVersions(sanitizedParagonVersion, 'v2024.1223.0735') >= 0;
      if (!hasWorkerActionKit && Microservice.WORKER_ACTIONKIT === microservice) {
        return false;
      }

      return true;
    });
  }

  private terraformEnv(debug: boolean): NodeJS.ProcessEnv {
    return debug ? { ...process.env, TF_LOG: 'DEBUG' } : process.env;
  }

  /**
   * initializes the terraform workspace
   */
  async executeTerraformInit(options: TerraformOptions): Promise<void> {
    const upgrade: boolean = options.args.includes('-upgrade');
    console.log('ℹ️  Executing `terraform init`...');
    await execAsync(
      `terraform -chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace} init${
        upgrade ? ' -upgrade' : ''
      }`,
      this.terraformEnv(options.debug),
    );
    console.log('✅ Executed `terraform init`.');
  }

  /**
   * executes Terraform plan
   */
  async executeTerraformPlan(options: TerraformOptions): Promise<void> {
    console.log('ℹ️  Executing `terraform plan`...');

    const { args, targets } = options;
    const formattedArgs: string[] = [
      ...args.filter((arg: string): boolean => arg !== '-upgrade'),
      ...targets.map((target: string): string => `-target=${target}`),
    ];
    await spawnAsync(
      'terraform',
      [`-chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace}`, 'plan', ...formattedArgs],
      this.terraformEnv(options.debug),
    );
    console.log('✅ Executed `terraform plan`.');
  }

  /**
   * executes Terraform plan
   */
  async executeTerraformApply(options: TerraformOptions): Promise<void> {
    const { destroy } = options;
    const operation: 'apply' | 'destroy' = destroy ? 'destroy' : 'apply';
    console.log(`ℹ️  Executing \`terraform ${operation}\`...`);

    const { args, targets } = options;
    const formattedArgs: string[] = [
      ...args.filter((arg: string): boolean => arg !== '-upgrade'),
      ...targets.map((target: string): string => `-target=${target}`),
    ];
    await spawnAsync(
      'terraform',
      [`-chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace}`, operation, ...formattedArgs],
      this.terraformEnv(options.debug),
    );
    console.log('✅ Executed `terraform apply`.');
  }
}
