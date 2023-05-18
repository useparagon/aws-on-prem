/**
 * the workspaces
 */
export enum TerraformWorkspace {
  INFRA = 'infra',
  PARAGON = 'paragon',
}

/**
 * configuration options for deploy command
 */
export type DeployCLIOptions = {
  debug: string;
  initialize: string;
  plan: string;
  apply: string;
  destroy: string;
  args: string;
  target: string;
};

/**
 * configuration options for terraform
 */
export type TerraformOptions = {
  debug: boolean;
  initialize: boolean;
  plan: boolean;
  apply: boolean;
  destroy: boolean;
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
  DISABLE_DOCKER_VERIFICATION: string;
};

/**
 * format for helm values file
 */
export type HelmValues = {
  global?: {
    env?: Record<string, string>;
  };
  [key: string]: any;
};
