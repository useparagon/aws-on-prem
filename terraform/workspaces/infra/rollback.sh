#!/bin/bash
# This script was auto-generated to perform Terraform state migrations
# It uses terraform mv commands to safely move resources without editing state directly
set -e

cd "$(dirname "$0")"

# Verify with the user
echo "This script will move resources in the Terraform state."
echo "This is a ROLLBACK script that will attempt to restore previous state."
echo -n "Do you want to continue? (y/N): "
read confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Operation cancelled."
  exit 1
fi

# Create state backup
terraform state pull > state-backup-$(date +%Y%m%d%H%M%S).json
echo "State backup created."

# Helper function to safely execute terraform mv
safe_mv() {
  echo "Moving: $1 -> $2"
  if terraform state list "$1" &>/dev/null; then
    terraform state mv "$1" "$2" || { echo "Failed to move $1 to $2"; exit 1; }
  else
    if terraform state list "$2" &>/dev/null; then
      echo "⚠️  Resource already at destination: $2"
    else
      echo "⚠️  Resource not found: $1"
    fi
  fi
}

# Helper function for rollback that continues on error
safe_rollback_mv() {
  echo "Rolling back: $1 -> $2"
  if terraform state list "$1" &>/dev/null; then
    terraform state mv "$1" "$2" || echo "⚠️  Failed to move $1 to $2, continuing..."
  else
    if terraform state list "$2" &>/dev/null; then
      echo "⚠️  Resource already at destination: $2"
    else
      echo "⚠️  Resource not found: $1"
    fi
  fi
}

# Begin rollback - only reverse the specific moves made by migrate.sh
safe_rollback_mv "module.storage.aws_iam_access_key.app" "module.s3.aws_iam_access_key.app"
safe_rollback_mv "module.storage.aws_iam_user_policy.app" "module.s3.aws_iam_user_policy.app"
safe_rollback_mv "module.storage.aws_iam_user.app" "module.s3.aws_iam_user.app"
safe_rollback_mv "module.storage.aws_s3_bucket_lifecycle_configuration.expiration" "module.s3.aws_s3_bucket_lifecycle_configuration.expiration"
safe_rollback_mv "module.storage.aws_s3_bucket_lifecycle_configuration.logs[0]" "module.s3.aws_s3_bucket_lifecycle_configuration.logs[0]"
safe_rollback_mv "module.storage.aws_s3_bucket_ownership_controls.cdn" "module.s3.aws_s3_bucket_ownership_controls.cdn"
safe_rollback_mv "module.storage.aws_s3_bucket_ownership_controls.logs[0]" "module.s3.aws_s3_bucket_ownership_controls.logs[0]"
safe_rollback_mv "module.storage.aws_s3_bucket_policy.app_bucket" "module.s3.aws_s3_bucket_policy.app_bucket"
safe_rollback_mv "module.storage.aws_s3_bucket_policy.cdn" "module.s3.aws_s3_bucket_policy.cdn"
safe_rollback_mv "module.storage.aws_s3_bucket_policy.logs_bucket[0]" "module.s3.aws_s3_bucket_policy.logs_bucket[0]"
safe_rollback_mv "module.storage.aws_s3_bucket_public_access_block.app" "module.s3.aws_s3_bucket_public_access_block.app"
safe_rollback_mv "module.storage.aws_s3_bucket_public_access_block.cdn" "module.s3.aws_s3_bucket_public_access_block.cdn"
safe_rollback_mv "module.storage.aws_s3_bucket_server_side_encryption_configuration.cdn" "module.s3.aws_s3_bucket_server_side_encryption_configuration.cdn"
safe_rollback_mv "module.storage.aws_s3_bucket_server_side_encryption_configuration.logs[0]" "module.s3.aws_s3_bucket_server_side_encryption_configuration.logs[0]"
safe_rollback_mv "module.storage.aws_s3_bucket.app" "module.s3.aws_s3_bucket.app"
safe_rollback_mv "module.storage.aws_s3_bucket.cdn" "module.s3.aws_s3_bucket.cdn"
safe_rollback_mv "module.storage.aws_s3_bucket.logs[0]" "module.s3.aws_s3_bucket.logs[0]"
safe_rollback_mv "module.storage.data.aws_caller_identity.current" "module.s3.data.aws_caller_identity.current"
safe_rollback_mv "module.storage.data.aws_elb_service_account.main" "module.s3.data.aws_elb_service_account.main"
safe_rollback_mv "module.storage.data.aws_iam_policy_document.app_bucket_policy" "module.s3.data.aws_iam_policy_document.app_bucket_policy"
safe_rollback_mv "module.storage.data.aws_iam_policy_document.logs_bucket_policy[0]" "module.s3.data.aws_iam_policy_document.logs_bucket_policy[0]"
safe_rollback_mv "module.storage.random_string.minio_microservice_pass" "module.s3.random_string.minio_microservice_pass"
safe_rollback_mv "module.storage.random_string.minio_microservice_user" "module.s3.random_string.minio_microservice_user"

echo "Rollback completed successfully."
