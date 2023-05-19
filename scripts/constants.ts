import * as path from 'path';

export const ROOT_DIR: string = path.join(__dirname, '/../').replace(new RegExp('//', 'g'), '/');
export const TERRAFORM_DIR: string = `${ROOT_DIR}/terraform`;
export const TERRAFORM_WORKSPACES_DIR: string = `${TERRAFORM_DIR}/workspaces`;
export const INFRA_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/infra`;
export const PARAGON_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/paragon`;

/**
 * old and current microservices
 */
export enum Microservice {
  CERBERUS = 'cerberus',
  CHRONOS = 'chronos',
  CONNECT = 'connect',
  DASHBOARD = 'dashboard',
  HADES = 'hades',
  HERCULES = 'hercules',
  HERMES = 'hermes',
  MINIO = 'minio',
  PASSPORT = 'passport',
  PHEME = 'pheme',
  PLATO = 'plato',
  ZEUS = 'zeus',
  WORKER_ACTIONS = 'worker-actions',
  WORKER_CREDENTIALS = 'worker-credentials',
  WORKER_CRONS = 'worker-crons',
  WORKER_PROXY = 'worker-proxy',
  WORKER_TRIGGERS = 'worker-triggers',
  WORKER_WORKFLOWS = 'worker-workflows',
}
