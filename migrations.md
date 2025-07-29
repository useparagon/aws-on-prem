# Terraform State Migration Guide

This document describes the migration process for updating the Terraform state to match the new infrastructure module structure.

## Overview

The migration involves:
1. Moving resources from old module names to new module names using `terraform state mv`
2. Updating provider references
3. Migrating tfvars to new variable structure
4. Updating Terraform version and state format

## Prerequisites

- Ensure you have the latest version of the codebase
- Verify you have proper AWS credentials configured
- Make sure you're in the correct Terraform workspace
- Have a backup of your current state

## Migration Steps

### Step 1: Run the Migration Command

Execute the migration using the CLI:

```bash
make migrate-infra
```

This command will:
- Pull the current Terraform state
- Create a backup of the original state
- Generate migration files with updated state and tfvars
- Clean provider references
- Update module names and resource paths

### Step 2: Review Generated Files

The migration creates several files:

- `migrated.tfstate` - Updated state file with cleaned provider references (needed to fix "Provider configuration not present" errors)
- `migrated.tfvars` - Updated variables file with new variable names
- `backup.tfstate` - Original state backup

Review these files to ensure the changes are correct.

### Step 3: Apply the Migration

If the generated files look correct, apply the migration:

```bash
# Navigate to the infra workspace
cd terraform/workspaces/infra

# Ensure latest configs deployed
terraform apply

# Prep for migration (destroys bastion and tunnel)
Set migration_prep=true in vars.auto.tfvars
terraform apply

# Run the migration script to backup state and create migratable state
./migrate.sh

# Push the cleaned state file to fix provider references
terraform state push migrated.tfstate

# Copy the tfvars to the enterprise repo
cp migrated.tfvars <?>/aws/workspaces/infra/vars.auto.tfvars

# Navigate to the enterprise infra workspace
cd <?>/aws/workspaces/infra

# Plan to verify changes
terraform plan

# Apply if the plan looks correct
terraform apply
```

The migration process uses both approaches for maximum safety:

1. **`migrate.sh` script**: Uses `terraform state mv` commands to safely move resources one by one
2. **`migrated.tfstate` file**: Contains the cleaned provider references that fix the "Provider configuration not present" errors

This two-step approach ensures:
- Resources are moved safely using Terraform's built-in state management
- Provider references are properly cleaned to avoid orphaned resource errors
- The process can be easily rolled back if issues occur

### Step 4: Verify Migration

After applying, verify that:

1. All resources are properly migrated
2. No resources were lost
3. The infrastructure is functioning correctly
4. All outputs are available and correct

## Migration Details

### Module Name Changes

The following module renames occur:

- `module.s3` → `module.storage`
- `module.compute.module.eks` → `module.cluster`
- `module.network.module.bastion` → `module.bastion`

### Variable Name Changes

Key variable renames include:

- `k8_version` → `k8s_version`
- `k8_ondemand_node_instance_type` → `eks_ondemand_node_instance_type`
- `k8_spot_node_instance_type` → `eks_spot_node_instance_type`
- `k8_spot_instance_percent` → `eks_spot_instance_percent`
- `k8_min_node_count` → `eks_min_node_count`
- `k8_max_node_count` → `eks_max_node_count`
- `postgres_version` → `rds_postgres_version`
- `multi_postgres` → `rds_multiple_instances`
- `multi_redis` → `elasticache_multiple_instances`
- `multi_az_enabled` → `rds_multi_az`

### Provider Reference Updates

Provider references are cleaned to use the top-level AWS provider instead of module-specific providers.

### State Format Updates

- Terraform version updated to 1.9.6
- State serial number incremented
- Provider configs section removed (not used in Terraform 1.9.6)

## Rollback Procedure

If issues occur during migration, use the rollback script:

```bash
# Navigate to the infra workspace
cd terraform/workspaces/infra

# Run the rollback script
./rollback.sh

# Restore the original state with proper provider references
terraform state push backup.tfstate
```

The rollback script will:
- Create a backup of the current state
- Move resources back to their original module names using `terraform state mv`
- Continue on errors to ensure maximum rollback coverage
- Provide detailed progress tracking

**Note**: After running the rollback script, you need to restore the original state file to fix provider reference issues. The `backup.tfstate` contains the original provider references that will resolve any "Provider configuration not present" errors.

### Manual Rollback Steps

If the rollback script fails, you can manually restore:

1. Restore the original state backup:
   ```bash
   terraform state push backup.tfstate
   ```

2. Restore the original tfvars:
   ```bash
   # If you have a backup of the original vars.auto.tfvars
   cp vars.auto.tfvars.backup vars.auto.tfvars
   ```

3. Run terraform plan to verify the rollback:
   ```bash
   terraform plan
   ```

## Troubleshooting

### Common Issues

1. **Provider Configuration Errors**
   - Ensure AWS credentials are properly configured
   - Check that the AWS provider is configured in the root module

2. **State Lock Issues**
   - If another process is using the state, wait for it to complete
   - Use `terraform force-unlock <lock-id>` if necessary

3. **Resource Not Found Errors**
   - Some resources may already be at the destination
   - This is normal and can be safely ignored

4. **Variable Validation Errors**
   - Check that all required variables are present in the new tfvars file
   - Verify variable types match the expected format

### Getting Help

If you encounter issues:

1. Check the migration logs for specific error messages
2. Review the generated files for any obvious issues
3. Compare the backup state with the migrated state
4. Use `terraform state list` to verify resource locations
5. Run `terraform plan` to identify any remaining issues

## Post-Migration Tasks

After successful migration:

1. Update any CI/CD pipelines to use the new variable names
2. Update documentation to reflect the new module structure
3. Test all infrastructure functionality
4. Update any external references to the old module names

## Safety Notes

- Always create backups before running migrations
- Test migrations in a non-production environment first
- Have a rollback plan ready
- Monitor the infrastructure closely after migration
- Keep the backup files until you're confident the migration is stable
- The `migrate.sh` script uses `terraform state mv` which is the recommended safe approach
- Each resource move is performed individually with error checking

## File Locations

- Migration script: `terraform/workspaces/infra/migrate.sh`
- Rollback script: `terraform/workspaces/infra/rollback.sh`
- Migration CLI: `scripts/cli/migrate/infra.ts`
- Generated files: `terraform/workspaces/infra/` 
