#!/bin/bash
# This script uses terraform mv commands to safely move resources without editing state directly
set -e

cd "$(dirname "$0")"

# Verify with the user
echo "This script will move resources in the Terraform state."
echo "Each move is performed individually and the script will stop on any error."
echo -n "Do you want to continue? (y/N): "
read confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Operation cancelled."
  exit 1
fi

# Create state backup with provider reference cleaning
echo "Creating state backup with cleaned provider references..."
STATE_BACKUP_FILE="state-backup-$(date +%Y%m%d%H%M%S).json"
terraform state pull > "$STATE_BACKUP_FILE.raw"
node -e '
  const fs = require("fs");
  const stateJson = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  
  // Clean provider references
  let cleanedResources = 0;
  const providerMap = {
    "module.s3.provider[\"registry.terraform.io/hashicorp/aws\"]": "provider[\"registry.terraform.io/hashicorp/aws\"]",
    "module.bastion.provider[\"registry.terraform.io/hashicorp/aws\"]": "provider[\"registry.terraform.io/hashicorp/aws\"]",
    "module.cluster.provider[\"registry.terraform.io/hashicorp/aws\"]": "provider[\"registry.terraform.io/hashicorp/aws\"]",
    "module.postgres.provider[\"registry.terraform.io/hashicorp/aws\"]": "provider[\"registry.terraform.io/hashicorp/aws\"]"
  };
  
  if (stateJson.resources && Array.isArray(stateJson.resources)) {
    for (const resource of stateJson.resources) {
      if (resource.provider && providerMap[resource.provider]) {
        const oldProviderRef = resource.provider;
        resource.provider = providerMap[oldProviderRef];
        cleanedResources++;
      }
      if (resource.module && resource.provider) {
        for (const [oldRef, newRef] of Object.entries(providerMap)) {
          if (resource.provider.includes(oldRef)) {
            resource.provider = newRef;
            cleanedResources++;
            break;
          }
        }
      }
    }
  }
  
  fs.writeFileSync(process.argv[2], JSON.stringify(stateJson, null, 2));
  console.log(`Cleaned provider references for ${cleanedResources} resources`);
' "$STATE_BACKUP_FILE.raw" "$STATE_BACKUP_FILE"
rm "$STATE_BACKUP_FILE.raw"
echo "State backup created with cleaned provider references."

TOTAL_MOVES=23

# Check if there are any moves to perform
if [ "$TOTAL_MOVES" -eq 0 ]; then
  echo "No resources need to be moved."
  exit 0
fi

# Progress tracking variables
CURRENT_MOVE=0
START_TIME=$(date +%s)

# Helper function to safely execute terraform mv
safe_mv() {
  echo ""
  echo "➡️ Moving: $1 -> $2"
  if terraform state list "$1" &>/dev/null; then
    # Allow Ctrl-C to terminate
    terraform state mv "$1" "$2" || { echo "❌ Failed to move $1 to $2"; exit 1; }
  else
    if terraform state list "$2" &>/dev/null; then
      echo "⚠️ Resource already at destination: $2"
    else
      echo "⚠️ Resource not found: $1"
    fi
  fi
  CURRENT_MOVE=$((CURRENT_MOVE + 1))
  report_progress "$CURRENT_MOVE" "$TOTAL_MOVES"
}

# Function to display progress
report_progress() {
  if [ "$2" -eq 0 ]; then
    echo "No resources to move."
    return
  fi
  PERCENT=$(( $1 * 100 / $2 ))
  echo "⏱️ Progress: $1/$2 resources (${PERCENT}%)"
}

# Begin migration
safe_mv "module.s3.aws_iam_access_key.app" "module.storage.aws_iam_access_key.app"
safe_mv "module.s3.aws_iam_user_policy.app" "module.storage.aws_iam_user_policy.app"
safe_mv "module.s3.aws_iam_user.app" "module.storage.aws_iam_user.app"
safe_mv "module.s3.aws_s3_bucket_lifecycle_configuration.expiration" "module.storage.aws_s3_bucket_lifecycle_configuration.expiration"
safe_mv "module.s3.aws_s3_bucket_lifecycle_configuration.logs[0]" "module.storage.aws_s3_bucket_lifecycle_configuration.logs[0]"
safe_mv "module.s3.aws_s3_bucket_ownership_controls.cdn" "module.storage.aws_s3_bucket_ownership_controls.cdn"
safe_mv "module.s3.aws_s3_bucket_ownership_controls.logs[0]" "module.storage.aws_s3_bucket_ownership_controls.logs[0]"
safe_mv "module.s3.aws_s3_bucket_policy.app_bucket" "module.storage.aws_s3_bucket_policy.app_bucket"
safe_mv "module.s3.aws_s3_bucket_policy.cdn" "module.storage.aws_s3_bucket_policy.cdn"
safe_mv "module.s3.aws_s3_bucket_policy.logs_bucket[0]" "module.storage.aws_s3_bucket_policy.logs_bucket[0]"
safe_mv "module.s3.aws_s3_bucket_public_access_block.app" "module.storage.aws_s3_bucket_public_access_block.app"
safe_mv "module.s3.aws_s3_bucket_public_access_block.cdn" "module.storage.aws_s3_bucket_public_access_block.cdn"
safe_mv "module.s3.aws_s3_bucket_server_side_encryption_configuration.cdn" "module.storage.aws_s3_bucket_server_side_encryption_configuration.cdn"
safe_mv "module.s3.aws_s3_bucket_server_side_encryption_configuration.logs[0]" "module.storage.aws_s3_bucket_server_side_encryption_configuration.logs[0]"
safe_mv "module.s3.aws_s3_bucket.app" "module.storage.aws_s3_bucket.app"
safe_mv "module.s3.aws_s3_bucket.cdn" "module.storage.aws_s3_bucket.cdn"
safe_mv "module.s3.aws_s3_bucket.logs[0]" "module.storage.aws_s3_bucket.logs[0]"
safe_mv "module.s3.data.aws_caller_identity.current" "module.storage.data.aws_caller_identity.current"
safe_mv "module.s3.data.aws_elb_service_account.main" "module.storage.data.aws_elb_service_account.main"
safe_mv "module.s3.data.aws_iam_policy_document.app_bucket_policy" "module.storage.data.aws_iam_policy_document.app_bucket_policy"
safe_mv "module.s3.data.aws_iam_policy_document.logs_bucket_policy[0]" "module.storage.data.aws_iam_policy_document.logs_bucket_policy[0]"
safe_mv "module.s3.random_string.minio_microservice_pass" "module.storage.random_string.minio_microservice_pass"
safe_mv "module.s3.random_string.minio_microservice_user" "module.storage.random_string.minio_microservice_user"

echo ""
echo "🏁 Migration completed successfully."
END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
TOTAL_MINUTES=$((TOTAL_ELAPSED / 60))
TOTAL_SECONDS=$((TOTAL_ELAPSED % 60))
echo "Total time: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
echo "You should now run: terraform plan"
