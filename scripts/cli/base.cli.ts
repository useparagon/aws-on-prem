import * as os from 'os';
import * as path from 'path';

import chalk from 'chalk';
import * as commander from 'commander';
import * as fs from 'fs-extra';

import { ROOT_DIR, TERRAFORM_DIR, TERRAFORM_WORKSPACES_DIR } from '../constants';
import { DeployCLIOptions, TerraformEnv, TerraformOptions, TerraformWorkspace } from '../types';
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
   * commander CLI
   *
   * @private
   * @type {(commander.Command | undefined)}
   * @memberof BaseCLI
   */
  private _program: commander.Command | undefined;

  /**
   * prepares the commander CLI
   *
   * @readonly
   * @type {commander.Command}
   * @memberof BaseCLI
   */
  get program(): commander.Command {
    if (this._program) {
      return this._program;
    }

    this._program = new commander.Command(`deploy-${this.workspace}`)
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
      .requiredOption('--apply [apply]', 'Run `terraform apply`', process.env.apply || 'true')
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
          target,
          args: _args,
        } = options;
        const initialize: boolean = _initialize === 'false' ? false : true;
        const plan: boolean = _plan === 'false' ? false : true;
        const apply: boolean = _apply === 'false' ? false : true;
        const args: string[] = _args.trim().length ? _args.trim().split(',') : [];
        const targets: string[] = target
          .trim()
          .split(',')
          .filter((target: string): boolean => target.length > 0)
          .map((target: string): string => target.trim());

        await this.run({
          initialize,
          plan,
          apply,
          args,
          targets,
        });
      });

    return this._program;
  }

  /**
   * executes the deployment
   * @param options
   */
  async run(options: TerraformOptions): Promise<void> {
    console.log('ℹ️  Executing run...', options);

    const { initialize, plan, apply } = options;

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

    if (plan) {
      await this.executeTerraformPlan(options);
    } else {
      console.log('ℹ️  Skipping `terraform plan`.');
    }

    if (apply) {
      await this.executeTerraformApply(options);
    } else {
      console.log('ℹ️  Skipping `terraform apply`.');
    }
  }

  /**
   * gets the values from `.secure/.env-tf` as an object
   */
  async getTerraformEnv(): Promise<TerraformEnv> {
    const values: TerraformEnv = (await getVariablesFromEnvFile(
      `${ROOT_DIR}/.secure/.env-tf`,
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
    const { TF_ORGANIZATION, TF_INFRA_WORKSPACE, TF_PARAGON_WORKSPACE } = env;
    const workspace: string =
      this.workspace === TerraformWorkspace.INFRA ? TF_INFRA_WORKSPACE : TF_PARAGON_WORKSPACE;
    const templateFilePath: string = `${TERRAFORM_DIR}/templates/main.tpl.tf`;
    const inputFile: string = await fs.readFile(templateFilePath, 'utf8');
    const outputFile: string = inputFile
      .replace(new RegExp('__TF_ORGANIZATION__', 'g'), TF_ORGANIZATION)
      .replace(new RegExp('__TF_WORKSPACE__', 'g'), workspace);
    const outputFilePath: string = `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/main.tf`;

    await fs.writeFile(outputFilePath, outputFile);
  }

  /**
   * writes the terraform config as variables in
   * @param env
   */
  async prepareTerraformVariables(env: TerraformEnv): Promise<void> {
    const variables: Record<string, string> = Object.keys(env).reduce(
      (transformed: Record<string, string>, key: string): Record<string, string> => ({
        ...transformed,
        [key.toLowerCase()]: (env as Record<string, string>)[key] as string,
      }),
      {},
    );
    const outputFile: string = Object.keys(variables)
      .map((key: string): string => {
        return `${key}="${variables[key]}"`;
      })
      .join('\n');
    await fs.writeFile(
      `${TERRAFORM_WORKSPACES_DIR}/${this.workspace}/vars.auto.tfvars`,
      outputFile,
    );
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
    console.log('ℹ️  Executing `terraform apply`...');

    const { args, targets } = options;
    const formattedArgs: string[] = [
      ...args,
      ...targets.map((target: string): string => `-target=${target}`),
    ];
    await spawnAsync('terraform', [
      `-chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace}`,
      'apply',
      ...formattedArgs,
    ]);
    console.log('✅ Executed `terraform apply`.');
  }
}
