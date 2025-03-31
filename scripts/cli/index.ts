import infraCLI from './infra.cli';
import migrateInfraCLI from './migrate/infra';
import paragonCLI from './paragon.cli';
import program from './program';

infraCLI.configureProgram(program);
migrateInfraCLI.configureProgram(program);
paragonCLI.configureProgram(program);

program.parse(process.argv);

export default program;
