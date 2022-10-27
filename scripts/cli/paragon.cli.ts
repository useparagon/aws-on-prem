import { BaseCLI } from './base.cli';
import { TerraformWorkspace } from '../types';

/**
 * cli for infra workspace
 */
class ParagonCLI extends BaseCLI {
  get workspace(): TerraformWorkspace {
    return TerraformWorkspace.PARAGON;
  }
}

const cli: ParagonCLI = new ParagonCLI();
export default cli.program;
