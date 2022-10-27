import infraCLI from './infra.cli';
import paragonCLI from './paragon.cli';
import program from './program';

infraCLI.configureProgram(program);
paragonCLI.configureProgram(program);

program.parse(process.argv);

export default program;
