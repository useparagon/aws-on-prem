import * as commander from 'commander';
import { Command } from 'commander';

import infra from './infra.cli';
import paragon from './paragon.cli';

const program: commander.Command = new Command()
  .addCommand(infra)
  .addCommand(paragon)
  .parse(process.argv);

export default program;
