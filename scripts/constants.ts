import * as path from 'path';

export const ROOT_DIR: string = path
  .join(__dirname, '/../')
  .replace(new RegExp('//', 'g'), '/')
  .replace(/\/+$/, '');
export const TERRAFORM_DIR: string = `${ROOT_DIR}/terraform`;
export const TERRAFORM_WORKSPACES_DIR: string = `${TERRAFORM_DIR}/workspaces`;
export const INFRA_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/infra`;
export const PARAGON_WORKSPACE_DIR: string = `${TERRAFORM_WORKSPACES_DIR}/paragon`;

/**
 * old and current microservices
 */
export enum Microservice {
  ACCOUNT = 'account',
  CACHE_REPLAY = 'cache-replay',
  CERBERUS = 'cerberus',
  CHRONOS = 'chronos',
  CONNECT = 'connect',
  DASHBOARD = 'dashboard',
  FLIPT = 'flipt',
  HADES = 'hades',
  HERCULES = 'hercules',
  HERMES = 'hermes',
  MINIO = 'minio',
  PASSPORT = 'passport',
  PHEME = 'pheme',
  PLATO = 'plato',
  RELEASE = 'release',
  ZEUS = 'zeus',
  WORKER_ACTIONKIT = 'worker-actionkit',
  WORKER_ACTIONS = 'worker-actions',
  WORKER_CREDENTIALS = 'worker-credentials',
  WORKER_CRONS = 'worker-crons',
  WORKER_DEPLOYMENTS = 'worker-deployments',
  WORKER_PROXY = 'worker-proxy',
  WORKER_TRIGGERS = 'worker-triggers',
  WORKER_WORKFLOWS = 'worker-workflows',
  WORKER_EVENT_LOGS = 'worker-eventlogs',
}
