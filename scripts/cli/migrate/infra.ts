import * as commander from 'commander';
import { BaseCLI } from '../base.cli';
import { TerraformEnv, TerraformWorkspace } from '../../types';
import { execAsync } from '../../utils';
import { TERRAFORM_WORKSPACES_DIR } from '../../constants';

/**
 * CLI for infra migration
 */
class InfraMigrateCLI extends BaseCLI {
    get workspace(): TerraformWorkspace {
        return TerraformWorkspace.INFRA;
    }

    /**
     * Configures the program with migrate-infra command
     * @param program Commander program instance
     */
    configureProgram(program: commander.Command): void {
        program.addCommand(
            new commander.Command('migrate-infra')
                .description('Migrate infrastructure resources.')
                .action(async (): Promise<void> => {
                    await this.runMigration();
                }),
        );
    }

    /**
     * prints the terraform state as json
     */
    async runMigration(): Promise<void> {
        console.log('ℹ️  Executing runMigration...');

        const env: TerraformEnv = await this.getTerraformEnv();
        await this.configureTerraformToken(env);
        await this.prepareTerraformMainFile(env);
        const result = await execAsync(
            `terraform -chdir=${TERRAFORM_WORKSPACES_DIR}/${this.workspace} state pull`,
            process.env,
            false
        );

        try {
            // Parse the state data
            const stateData = JSON.parse(result.stdout);

            // Update Terraform version
            stateData.terraform_version = "1.9.6";

            // Reshape outputs
            const outputs = stateData.outputs;
            const reshapedOutputs = {
                bastion: {
                    value: {
                        private_key: outputs.bastion_private_key.value,
                        public_dns: outputs.bastion_public_dns.value
                    },
                    type: [
                        "object",
                        {
                            private_key: "string",
                            public_dns: "string"
                        }
                    ],
                    sensitive: true
                },
                cluster_name: outputs.cluster_name,
                logs_bucket: outputs.logs_bucket,
                minio: {
                    value: {
                        microservice_pass: outputs.minio_microservice_pass.value,
                        microservice_user: outputs.minio_microservice_user.value,
                        private_bucket: outputs.minio_private_bucket.value,
                        public_bucket: outputs.minio_public_bucket.value,
                        root_password: outputs.minio_root_password.value,
                        root_user: outputs.minio_root_user.value
                    },
                    type: [
                        "object",
                        {
                            microservice_pass: "string",
                            microservice_user: "string",
                            private_bucket: "string",
                            public_bucket: "string",
                            root_password: "string",
                            root_user: "string"
                        }
                    ],
                    sensitive: true
                },
                postgres: {
                    value: {} as Record<string, {
                        database: string;
                        host: string;
                        password: string;
                        port: number;
                        user: string;
                    }>,
                    type: [
                        "object",
                        {
                            cerberus: [
                                "object",
                                {
                                    database: "string",
                                    host: "string",
                                    password: "string",
                                    port: "number",
                                    user: "string"
                                }
                            ],
                            hermes: [
                                "object",
                                {
                                    database: "string",
                                    host: "string",
                                    password: "string",
                                    port: "number",
                                    user: "string"
                                }
                            ],
                            zeus: [
                                "object",
                                {
                                    database: "string",
                                    host: "string",
                                    password: "string",
                                    port: "number",
                                    user: "string"
                                }
                            ]
                        }
                    ],
                    sensitive: true
                },
                redis: {
                    value: {} as Record<string, {
                        cluster: boolean;
                        host: string;
                        port: number;
                    }>,
                    type: [
                        "map",
                        [
                            "object",
                            {
                                cluster: "bool",
                                host: "string",
                                port: "number"
                            }
                        ]
                    ],
                    sensitive: true
                },
                workspace: outputs.workspace
            };

            // Handle postgres databases
            const postgresValue = outputs.postgres.value;
            const existingPostgresDbs = Object.keys(postgresValue);
            if (existingPostgresDbs.length === 1) {
                // Single database case
                const singleDb = existingPostgresDbs[0];
                reshapedOutputs.postgres.value = {
                    cerberus: postgresValue[singleDb],
                    hermes: postgresValue[singleDb],
                    zeus: postgresValue[singleDb]
                };
            } else {
                // Multiple databases case - map existing databases to target databases
                const targetDbs = ['cerberus', 'hermes', 'zeus'];

                // Map existing databases to target databases, cycling through if we have fewer existing databases
                targetDbs.forEach((targetDb, index) => {
                    const sourceDb = existingPostgresDbs[index % existingPostgresDbs.length];
                    reshapedOutputs.postgres.value[targetDb] = postgresValue[sourceDb];
                });
            }

            // Handle redis instances
            const redisValue = outputs.redis.value;
            const existingRedisInstances = Object.keys(redisValue);
            if (existingRedisInstances.length === 1) {
                // Single instance case
                const singleInstance = existingRedisInstances[0];
                reshapedOutputs.redis.value = {
                    cache: { ...redisValue[singleInstance], cluster: true },
                    queue: { ...redisValue[singleInstance], cluster: false },
                    system: { ...redisValue[singleInstance], cluster: false }
                };
            } else {
                // Multiple instances case - map existing instances to target instances
                const targetInstances = ['cache', 'queue', 'system'];

                // Map existing instances to target instances, cycling through if we have fewer existing instances
                targetInstances.forEach((targetInstance, index) => {
                    const sourceInstance = existingRedisInstances[index % existingRedisInstances.length];
                    reshapedOutputs.redis.value[targetInstance] = {
                        ...redisValue[sourceInstance],
                        cluster: targetInstance === 'cache'
                    };
                });
            }

            stateData.outputs = reshapedOutputs;

            // Save the modified state to a file
            const fs = require('fs');
            const path = require('path');
            const statePath = path.join(TERRAFORM_WORKSPACES_DIR, this.workspace, 'modified.tfstate');

            fs.writeFileSync(statePath, JSON.stringify(stateData, null, 2));

            console.log(`Modified state saved to ${statePath}`);
            console.log('You can apply this state with: terraform state push modified.tfstate');
        } catch (parseError) {
            console.error(`Error parsing terraform state: ${parseError}`);
        }

        console.log('✅ Executed runMigration.');
    }
}

const migrateInfraCLI = new InfraMigrateCLI();
export default migrateInfraCLI;
