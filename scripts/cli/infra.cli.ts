import { BaseCLI } from './base.cli';
import { TerraformWorkspace } from '../types';

/**
 * cli for infra workspace
 */
class InfraCLI extends BaseCLI {
  get workspace(): TerraformWorkspace {
    return TerraformWorkspace.INFRA;
  }
}

const cli: InfraCLI = new InfraCLI();
export default cli.program;
