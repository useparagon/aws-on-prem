import * as commander from 'commander';
import { BaseCLI } from '../base.cli';
import { TerraformEnv, TerraformWorkspace } from '../../types';
import { execAsync } from '../../utils';
import { TERRAFORM_WORKSPACES_DIR } from '../../constants';
import * as fs from 'fs';
import * as path from 'path';

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
     * Migrates the tfvars file to match the new variable structure
     */
    private migrateTfvars(currentVars: Record<string, string>, outputs: Record<string, any>): Record<string, string> {
        const newVars: Record<string, string> = {};

        // Default values from source workspace
        const defaultValues: Record<string, string> = {
            'k8_version': '1.31',
            'k8_ondemand_node_instance_type': 't3a.medium,t3.medium',
            'k8_spot_node_instance_type': 't3a.medium,t3.medium',
            'k8_spot_instance_percent': '75',
            'k8_min_node_count': '12',
            'k8_max_node_count': '20',
            'postgres_version': '12.7',
            'multi_postgres': 'false',
            'multi_redis': 'false',
            'multi_az_enabled': 'true',
            'rds_instance_class': 'db.t3.small',
            'elasticache_node_type': 'cache.r6g.large',
            'az_count': '2',
            'vpc_cidr': '10.0.0.0/16',
            'vpc_cidr_newbits': '8',
            'disable_cloudtrail': 'false',
            'disable_deletion_protection': 'false',
            'app_bucket_expiration': '365',
            'eks_addon_ebs_csi_driver_enabled': 'true',
            'create_autoscaling_linked_role': 'true'
        };

        // 1:1 mappings with different names
        const mappings: Record<string, string> = {
            'k8_version': 'k8s_version',
            'k8_ondemand_node_instance_type': 'eks_ondemand_node_instance_type',
            'k8_spot_node_instance_type': 'eks_spot_node_instance_type',
            'k8_spot_instance_percent': 'eks_spot_instance_percent',
            'k8_min_node_count': 'eks_min_node_count',
            'k8_max_node_count': 'eks_max_node_count',
            'postgres_version': 'rds_postgres_version',
            'multi_postgres': 'rds_multiple_instances',
            'multi_redis': 'elasticache_multiple_instances',
            'multi_az_enabled': 'rds_multi_az'
        };

        // Direct 1:1 mappings (no name change)
        const directMappings = [
            'aws_region',
            'aws_access_key_id',
            'aws_secret_access_key',
            'aws_session_token',
            'organization',
            'az_count',
            'vpc_cidr',
            'vpc_cidr_newbits',
            'rds_instance_class',
            'elasticache_node_type',
            'master_guardduty_account_id',
            'mfa_enabled',
            'ssh_whitelist',
            'disable_cloudtrail',
            'disable_deletion_protection',
            'app_bucket_expiration',
            'cloudflare_api_token',
            'cloudflare_tunnel_enabled',
            'cloudflare_tunnel_subdomain',
            'cloudflare_tunnel_zone_id',
            'cloudflare_tunnel_account_id',
            'cloudflare_tunnel_email_domain'
        ];

        // Handle renamed variables
        Object.entries(mappings).forEach(([oldName, newName]) => {
            if (oldName in currentVars) {
                newVars[newName] = currentVars[oldName];
            } else if (oldName in defaultValues) {
                newVars[newName] = defaultValues[oldName];
            }
        });

        // Handle direct mappings
        directMappings.forEach(name => {
            if (name in currentVars) {
                newVars[name] = currentVars[name];
            } else if (name in defaultValues) {
                newVars[name] = defaultValues[name];
            }
        });

        // Handle eks_admin_arns (combines eks_admin_user_arns and eks_admin_role_arns)
        const userArns = currentVars['eks_admin_user_arns']?.split(',').map(arn => arn.trim()).filter(Boolean) || [];
        const roleArns = currentVars['eks_admin_role_arns']?.split(',').map(arn => arn.trim()).filter(Boolean) || [];
        if (userArns.length > 0 || roleArns.length > 0) {
            newVars['eks_admin_arns'] = JSON.stringify([...userArns, ...roleArns]);
        }

        // Preserve the workspace naming conventions
        if (outputs.workspace?.value) {
            newVars['migrated_workspace'] = outputs.workspace.value;
        }

        // Handle random_string to random_password migration
        const passwordOverrides: Record<string, string> = {};

        // Add MinIO password if available
        if (outputs.minio_microservice_pass?.value) {
            console.log('minio_microservice_pass', outputs.minio_microservice_pass.value);
            passwordOverrides.minio = outputs.minio_microservice_pass.value;
        }

        // Add PostgreSQL passwords based on available databases
        const postgresValue = outputs.postgres?.value as Record<string, { password: string }>;
        if (postgresValue) {
            Object.entries(postgresValue).forEach(([dbName, dbConfig]) => {
                if (dbConfig.password) {
                    console.log(dbName, dbConfig.password);
                    passwordOverrides[dbName] = dbConfig.password;
                }
            });
        }

        // Only add the migrated_passwords if we have any passwords
        if (Object.keys(passwordOverrides).length > 0) {
            newVars['migrated_passwords'] = JSON.stringify(passwordOverrides);
        }

        return newVars;
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

            // Create a backup of the original state
            const backupPath = path.join(TERRAFORM_WORKSPACES_DIR, this.workspace, 'backup.tfstate');
            fs.writeFileSync(backupPath, JSON.stringify(stateData, null, 2));
            console.log(`Original state backed up to ${backupPath}`);

            // Migrate tfvars
            const tfvarsPath = path.join(TERRAFORM_WORKSPACES_DIR, this.workspace, 'vars.auto.tfvars');
            const currentVars = this.parseTfvarsFile(tfvarsPath);
            const newVars = this.migrateTfvars(currentVars, stateData.outputs);

            // Save the new tfvars
            const newTfvarsPath = path.join(TERRAFORM_WORKSPACES_DIR, this.workspace, 'migrated.tfvars');
            this.writeTfvarsFile(newTfvarsPath, newVars);

            // Update Terraform version and increment serial
            stateData.terraform_version = "1.9.6";
            stateData.serial = (stateData.serial || 0) + 1;

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

            // Preserve resources and their provider configurations
            const resources = stateData.resources || [];
            const newResources = resources.map((resource: { module?: string; provider?: string; provider_config_key?: string; type?: string; name?: string; instances?: any[] }) => {
                // Update module names
                let newModule = resource.module;
                if (newModule === 'module.s3') {
                    newModule = 'module.storage';
                }
                // Add more module renames as needed

                // Update provider references
                let newProvider = resource.provider;
                if (newProvider) {
                    if (newProvider.includes("registry.terraform.io/hashicorp/aws")) {
                        // Use top level AWS provider instead of redefining the module provider
                        newProvider = 'provider["registry.terraform.io/hashicorp/aws"]';
                    } else if (newProvider.includes('module.s3.provider') && newModule === 'module.storage') {
                        // Update provider references to match new module names
                        newProvider = newProvider.replace('module.s3.provider', 'module.storage.provider');
                    }
                    // Keep all other provider references as they are
                }

                // Create new resource without provider_config_key
                const { provider_config_key, ...resourceWithoutKey } = resource;
                return {
                    ...resourceWithoutKey,
                    module: newModule,
                    provider: newProvider
                };
            });

            // Reconstruct state with all components
            stateData.outputs = reshapedOutputs;
            stateData.resources = newResources;
            // Remove provider_configs section as it's not used in Terraform 1.9.6
            delete stateData.provider_configs;

            // Save the modified state to a file
            const statePath = path.join(TERRAFORM_WORKSPACES_DIR, this.workspace, 'migrated.tfstate');
            fs.writeFileSync(statePath, JSON.stringify(stateData, null, 2));

            console.log(`Modified state saved to ${statePath}`);
            console.log(`New tfvars saved to ${newTfvarsPath}`);
            console.log('You can apply these changes with:');
            console.log('1. terraform state push migrated.tfstate');
            console.log('2. mv migrated.tfvars vars.auto.tfvars');
            console.log('3. terraform plan');
            console.log('4. terraform apply');

            console.log('✅ Executed runMigration.');
        } catch (error: unknown) {
            console.error(`❌ runMigration Failed: ${error instanceof Error ? error.message : String(error)}`);
            console.error(error instanceof Error ? error.stack : 'No stack trace available');
        }
    }

    /**
     * Parses a tfvars file into a Record<string, string>
     */
    private parseTfvarsFile(filePath: string): Record<string, string> {
        const content = fs.readFileSync(filePath, 'utf-8');
        const vars: Record<string, string> = {};

        content.split('\n').forEach(line => {
            line = line.trim();
            if (line && !line.startsWith('#')) {
                const match = line.match(/^([^=]+)=["']([^"']*)["']$/);
                if (match) {
                    const [, key, value] = match;
                    vars[key.trim()] = value.trim();
                }
            }
        });

        return vars;
    }

    /**
     * Writes a Record<string, string> to a tfvars file
     */
    private writeTfvarsFile(filePath: string, vars: Record<string, string>): void {
        const content = Object.entries(vars)
            .sort(([keyA], [keyB]) => keyA.localeCompare(keyB))
            .map(([key, value]) => {
                // Try to parse the value as JSON to handle complex values
                try {
                    const parsed = JSON.parse(value);
                    // If it's an object or array, output it as HCL
                    if (typeof parsed === 'object' && parsed !== null) {
                        return `${key} = ${JSON.stringify(parsed, null, 2)}`;
                    }
                } catch {
                    // If it's not valid JSON, treat it as a string
                }
                return `${key}="${value}"`;
            })
            .join('\n');

        fs.writeFileSync(filePath, content + '\n');
    }
}

const migrateInfraCLI = new InfraMigrateCLI();
export default migrateInfraCLI;
