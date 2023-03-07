import * as os from 'os';
import * as path from 'path';

import chalk from 'chalk';
import * as commander from 'commander';
import { compareVersions } from 'compare-versions';
import * as fs from 'fs-extra';

import { ROOT_DIR, TERRAFORM_DIR, TERRAFORM_WORKSPACES_DIR } from '../constants';
import {
  DeployCLIOptions,
  SubchartEnablementOverrides,
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
              initialize: _initialize = 'true',
              plan: _plan = 'true',
              apply: _apply = 'true',
              destroy: _destroy = 'false',
              target,
              args: _args,
            } = options;
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
      );
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

    // await sleep(1000 * 60 * 5);

    if (initialize) {
      await this.executeTerraformInit();
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

    if (!isDocker()) {
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
    await fs.createFile(filePath);
    await fs.writeFile(filePath, file, { encoding: 'utf8' });

    console.log('✅ Configured Terraform token.');
  }

  /**
   * copies the `main.tpl.tf` file into the workspace and replaces the placeholders
   * @param env
   */
  async prepareTerraformMainFile(env: TerraformEnv): Promise<void> {
    const { TF_ORGANIZATION, TF_WORKSPACE } = env;
    const templateFilePath: string = `${TERRAFORM_DIR}/templates/main.tpl.tf`;
    const inputFile: string = await fs.readFile(templateFilePath, 'utf8');
    const outputFile: string = inputFile
      .replace(new RegExp('__TF_ORGANIZATION__', 'g'), TF_ORGANIZATION)
      .replace(new RegExp('__TF_WORKSPACE__', 'g'), TF_WORKSPACE);
    const outputFilePath: string = `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/main.tf`;

    await fs.writeFile(outputFilePath, outputFile);
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
      const helmValues: Record<string, any> = await getVariablesFromEnvFile(
        `${ROOT_DIR}/.secure/.env-helm`,
      );
      variables['helm_values'] = {
        subchart: this.getSubchartEnablementOverrides(helmValues.VERSION),
        global: {
          env: helmValues,
        },
      };
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
    await fs.writeFile(
      `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/vars.auto.tfvars`,
      outputFile,
    );
  }

  /**
   * configuration for whether subcharts are enabled based on semver
   */
  getSubchartEnablementOverrides(version: string | undefined): SubchartEnablementOverrides {
    const LATEST_VERSION: 'latest' = 'latest';
    const _version: string = version ?? LATEST_VERSION;
    const isLatestVersion: boolean = _version === LATEST_VERSION;

    return {
      chronos: {
        enabled: isLatestVersion || compareVersions(_version, '2.57.0') >= 0,
      },
      hades: {
        enabled: isLatestVersion || compareVersions(_version, '2.67.0') >= 0,
      },
      pheme: {
        enabled: isLatestVersion || compareVersions(_version, '2.64.1') >= 0,
      },
      plato: {
        enabled: isLatestVersion || compareVersions(_version, '2.67.0') >= 0,
      },
    };
  }

  /**
   * initializes the terraform workspace
   */
  async executeTerraformInit(): Promise<void> {
    console.log('ℹ️  Executing `terraform init`...');
    await execAsync(
      `terraform -chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace} init`,
      process.env,
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
      ...args,
      ...targets.map((target: string): string => `-target=${target}`),
    ];
    await spawnAsync('terraform', [
      `-chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace}`,
      'plan',
      ...formattedArgs,
    ]);
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
      ...args,
      ...targets.map((target: string): string => `-target=${target}`),
    ];
    await spawnAsync('terraform', [
      `-chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace}`,
      operation,
      ...formattedArgs,
    ]);
    console.log('✅ Executed `terraform apply`.');
  }
}
