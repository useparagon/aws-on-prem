/**
 * the workspaces
 */
export enum TerraformWorkspace {
  INFRA = 'infra',
  PARAGON = 'paragon',
}

/**
 * configuration options for aws and azure deploy clis
 */
export type DeployCLIOptions = {
  initialize: string;
  plan: string;
  apply: string;
  args: string;
  target: string;
};

/**
 * configuration options for terraform
 */
export type TerraformOptions = {
  initialize: boolean;
  plan: boolean;
  apply: boolean;
  args: string[];
  targets: string[];
};

/**
 * the values stored in `.env-tf`
 */
export type TerraformEnv = {
  AWS_ACCESS_KEY_ID: string;
  AWS_SECRET_ACCESS_KEY: string;
  AWS_REGION: string;
  TF_TOKEN: string;
  TF_ORGANIZATION: string;
  TF_WORKSPACE: string;
};
