import * as path from 'path';

export const ROOT_DIR: string = path.join(__dirname, '/../').replace(new RegExp('//', 'g'), '/');
export const TERRAFORM_DIR: string = `${ROOT_DIR}/terraform`;
export const TERRAFORM_WORKSPACES_DIR: string = `${TERRAFORM_DIR}/workspaces`;
export const INFRA_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/infra`;
export const PARAGON_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/paragon`;
