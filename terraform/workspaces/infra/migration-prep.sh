#!/bin/bash

# This script is used to prepare AWS and the Terraform state for migration to the enterprise workspace.
# It attempts to manually address state issues that will cause the migration to fail.

# The enterprise workspace will attempt to create duplicate egress rules for 0.0.0.0/0 and ::/0.
# This script removes the duplicate rules they can be recreated without errors like below.
#
# │ Error: [WARN] A duplicate Security Group rule was found on (sg-0112ab8daab4d6f33). This may be
# │ a side effect of a now-fixed Terraform issue causing two security groups with
# │ identical attributes but different source_security_group_ids to overwrite each
# │ other in the state. See https://github.com/hashicorp/terraform/pull/2376 for more
# │ information and instructions for recovery.

set -e

# Get script directory to locate vars.auto.tfvars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARS_FILE="${SCRIPT_DIR}/vars.auto.tfvars"

if [ ! -f "$VARS_FILE" ]; then
  echo "Error: Could not find vars.auto.tfvars at ${VARS_FILE}"
  exit 1
fi

# Extract AWS credentials from vars.auto.tfvars
export AWS_ACCESS_KEY_ID=$(grep -E '^\s*aws_access_key_id\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')
export AWS_SECRET_ACCESS_KEY=$(grep -E '^\s*aws_secret_access_key\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')
REGION=$(grep -E '^\s*aws_region\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')

# Session token is optional - check if it exists in the file or environment
SESSION_TOKEN=$(grep -E '^\s*aws_session_token\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')
if [ -n "$SESSION_TOKEN" ]; then
  export AWS_SESSION_TOKEN="$SESSION_TOKEN"
elif [ -n "$AWS_SESSION_TOKEN" ]; then
  # Use existing environment variable if set
  export AWS_SESSION_TOKEN
fi

# Use environment variable if REGION wasn't found in file
REGION="${REGION:-${AWS_REGION:-us-east-1}}"

export AWS_PAGER=""

# Security group cleanup section (non-fatal - will continue even if this fails)
echo "Attempting to clean up security group rules..."
SG_CLEANUP_SUCCESS=true

# Get security group ID from command line argument or extract from Terraform state
if [ -n "$1" ]; then
  SG_ID="$1"
  echo "Using provided security group ID: ${SG_ID}"
else
  echo "Extracting security group ID from Terraform state..."
  SG_ID=$(terraform state show 'module.cluster.module.eks.aws_security_group_rule.node["egress_all"]' 2>/dev/null | grep -E '^\s+security_group_id\s+=' | awk '{print $3}' | tr -d '"')
  
  if [ -z "$SG_ID" ]; then
    echo "  ⚠ Could not determine security group ID from Terraform state (skipping security group cleanup)"
    SG_CLEANUP_SUCCESS=false
  fi
fi

if [ "$SG_CLEANUP_SUCCESS" = true ]; then
  # Query AWS directly for IPv4 (0.0.0.0/0) and IPv6 egress rules for this security group
  echo "Querying AWS for IPv4 (0.0.0.0/0) and IPv6 egress security group rules in ${SG_ID}..."

  RULE_IDS=$(aws ec2 describe-security-group-rules \
    --filters "Name=group-id,Values=${SG_ID}" \
    --query "SecurityGroupRules[?IsEgress == \`true\` && (CidrIpv6 != null || CidrIpv4 == \`0.0.0.0/0\`)].SecurityGroupRuleId" \
    --output text \
    --region "${REGION}" 2>/dev/null || true)

  if [ -z "$RULE_IDS" ]; then
    echo "  ⚠ Could not find any matching security group rule IDs in AWS (skipping security group cleanup)"
    SG_CLEANUP_SUCCESS=false
  else
    echo "Found group-id: ${SG_ID}, security-group-rule-ids: ${RULE_IDS}"
    echo ""

    # Convert space-separated rule IDs to array and revoke all rules at once
    read -ra RULE_ID_ARRAY <<< "$RULE_IDS"

    if aws ec2 revoke-security-group-egress \
        --group-id "${SG_ID}" \
        --security-group-rule-ids "${RULE_ID_ARRAY[@]}" \
        --region "${REGION}" \
        --output json >/dev/null 2>&1; then
        echo "  ✓ Successfully deleted all rules from ${SG_ID}"
    else
        echo "  ✗ Failed to delete rules from AWS (they might have been deleted already or don't exist)"
        SG_CLEANUP_SUCCESS=false
    fi

    echo ""
    echo "Removing rule from Terraform state..."
    if terraform state rm 'module.cluster.module.eks.aws_security_group_rule.node["egress_all"]' 2>/dev/null; then
        echo "  ✓ Successfully removed from Terraform state"
        echo ""
    else
        echo "  ✗ Failed to remove from Terraform state (it might have been removed already)"
        SG_CLEANUP_SUCCESS=false
    fi
  fi
fi

if [ "$SG_CLEANUP_SUCCESS" = false ]; then
  echo "  ⚠ Security group cleanup skipped or failed, continuing with EKS access entry import..."
  echo ""
fi

echo ""
echo "Extracting caller ARN and cluster name for EKS access entry import..."
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text --region "${REGION}")

if [ -z "$CALLER_ARN" ]; then
  echo "Error: Could not determine caller ARN from AWS STS."
  exit 1
fi

# Get cluster name from Terraform state
CLUSTER_NAME=$(terraform state show 'module.cluster.module.eks.aws_eks_cluster.this[0]' 2>/dev/null | grep -E '^\s+name\s+=' | awk '{print $3}' | tr -d '"')

if [ -z "$CLUSTER_NAME" ]; then
  # Fallback: try to get from organization in vars.auto.tfvars
  ORGANIZATION=$(grep -E '^\s*organization\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')
  if [ -n "$ORGANIZATION" ]; then
    CLUSTER_NAME="paragon-enterprise-${ORGANIZATION}"
    echo "  Using cluster name from organization: ${CLUSTER_NAME}"
  else
    echo "Error: Could not determine cluster name from Terraform state or vars.auto.tfvars."
    exit 1
  fi
fi

echo "Found caller-arn: ${CALLER_ARN}, cluster-name: ${CLUSTER_NAME}"

echo ""
echo "Importing EKS access entry into Terraform state..."
if terraform import "module.cluster.module.eks.aws_eks_access_entry.this[\"${CALLER_ARN}\"]" "${CLUSTER_NAME}:${CALLER_ARN}" 2>/dev/null; then
    echo "  ✓ Successfully imported EKS access entry"
    echo ""
else
    echo "  ✗ Failed to import EKS access entry (it might have been imported already or doesn't exist)"
    exit 1
fi

echo ""
echo "================================================================================"
echo "Generating vars.auto.tfvars for the new enterprise workspace..."
echo "================================================================================"
echo ""

# Helper function to extract value from vars.auto.tfvars
extract_var() {
    local var_name="$1"
    local default_value="${2:-}"
    local value=$(grep -E "^\s*${var_name}\s*=" "$VARS_FILE" | awk -F'"' '{print $2}' || echo "")
    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Helper function to extract value from terraform state
extract_state() {
    local resource_path="$1"
    local attribute="$2"
    local default_value="${3:-}"
    terraform state show "$resource_path" 2>/dev/null | grep -E "^\s+${attribute}\s+=" | awk '{print $3}' | tr -d '"' || echo "$default_value"
}

# Extract 1:1 mappings from vars.auto.tfvars
AWS_ACCESS_KEY_ID=$(extract_var "aws_access_key_id")
AWS_SECRET_ACCESS_KEY=$(extract_var "aws_secret_access_key")
AWS_REGION=$(extract_var "aws_region")
CLOUDFLARE_API_TOKEN=$(extract_var "cloudflare_api_token")
CLOUDFLARE_TUNNEL_ACCOUNT_ID=$(extract_var "cloudflare_tunnel_account_id")
CLOUDFLARE_TUNNEL_EMAIL_DOMAIN=$(extract_var "cloudflare_tunnel_email_domain")
CLOUDFLARE_TUNNEL_ENABLED=$(extract_var "cloudflare_tunnel_enabled")
CLOUDFLARE_TUNNEL_SUBDOMAIN=$(extract_var "cloudflare_tunnel_subdomain")
CLOUDFLARE_TUNNEL_ZONE_ID=$(extract_var "cloudflare_tunnel_zone_id")
DISABLE_CLOUDTRAIL=$(extract_var "disable_cloudtrail")
DISABLE_DELETION_PROTECTION=$(extract_var "disable_deletion_protection")
ORGANIZATION=$(extract_var "organization")

# Extract EKS admin role ARNs (will be formatted in output section)
EKS_ADMIN_ROLE_ARNS_RAW=$(extract_var "eks_admin_role_arns")

# Extract values from terraform state or use defaults
# Note: az_count and vpc_cidr_newbits are variables, not state resources, so use defaults or vars file
AZ_COUNT=$(extract_var "az_count" "2")
VPC_CIDR=$(extract_state "module.network.aws_vpc.app" "cidr_block" "10.0.0.0/16")
VPC_CIDR_NEWBITS=$(extract_var "vpc_cidr_newbits" "8")

# Extract EKS values from terraform state or use defaults
K8_VERSION=$(extract_state "module.cluster.module.eks.aws_eks_cluster.this[0]" "version" "1.32")
# Remove 'v' prefix if present
K8_VERSION=$(echo "$K8_VERSION" | sed 's/^v//')
K8_MIN_NODE_COUNT=$(extract_var "k8_min_node_count" "4")
K8_MAX_NODE_COUNT=$(extract_var "k8_max_node_count" "20")
K8_ONDEMAND_NODE_INSTANCE_TYPE=$(extract_var "k8_ondemand_node_instance_type" "m6a.xlarge")
K8_SPOT_NODE_INSTANCE_TYPE=$(extract_var "k8_spot_node_instance_type" "t3a.xlarge,t3.xlarge,m5a.xlarge,m5.xlarge,m6a.xlarge,m6i.xlarge,m7a.xlarge,m7i.xlarge,r5a.xlarge,m4.xlarge")
K8_SPOT_INSTANCE_PERCENT=$(extract_var "k8_spot_instance_percent" "75")

# Extract RDS values from terraform state or use defaults
RDS_INSTANCE_CLASS=$(extract_state "module.postgres.aws_db_instance.postgres[\"postgres\"]" "instance_class" "")
# Try alternative resource path if first one fails
if [ -z "$RDS_INSTANCE_CLASS" ]; then
    RDS_INSTANCE_CLASS=$(extract_state "module.postgres.aws_db_instance.postgres[0]" "instance_class" "")
fi
# Fallback to default if not found
if [ -z "$RDS_INSTANCE_CLASS" ]; then
    RDS_INSTANCE_CLASS="db.t4g.small"
fi

RDS_POSTGRES_VERSION=$(extract_state "module.postgres.aws_db_instance.postgres[\"postgres\"]" "engine_version" "")
if [ -z "$RDS_POSTGRES_VERSION" ]; then
    RDS_POSTGRES_VERSION=$(extract_state "module.postgres.aws_db_instance.postgres[0]" "engine_version" "")
fi
# Extract from vars file as fallback
if [ -z "$RDS_POSTGRES_VERSION" ]; then
    RDS_POSTGRES_VERSION=$(extract_var "postgres_version" "16")
fi

RDS_MULTI_AZ=$(extract_state "module.postgres.aws_db_instance.postgres[\"postgres\"]" "multi_az" "")
if [ -z "$RDS_MULTI_AZ" ]; then
    RDS_MULTI_AZ=$(extract_state "module.postgres.aws_db_instance.postgres[0]" "multi_az" "")
fi
# Convert boolean to string, default to true if not found
if [ -z "$RDS_MULTI_AZ" ]; then
    RDS_MULTI_AZ="true"
elif [ "$RDS_MULTI_AZ" = "true" ] || [ "$RDS_MULTI_AZ" = "1" ]; then
    RDS_MULTI_AZ="true"
else
    RDS_MULTI_AZ="false"
fi
RDS_MULTIPLE_INSTANCES=$(extract_var "multi_postgres" "false")

# Extract ElastiCache values from terraform state or use defaults
ELASTICACHE_NODE_TYPE=$(extract_state "module.redis.aws_elasticache_replication_group.redis[0]" "node_type" "")
if [ -z "$ELASTICACHE_NODE_TYPE" ]; then
    ELASTICACHE_NODE_TYPE=$(extract_state "module.redis.aws_elasticache_cluster.redis[\"cache\"]" "node_type" "")
fi
# Fallback to vars file if not found in state
if [ -z "$ELASTICACHE_NODE_TYPE" ]; then
    ELASTICACHE_NODE_TYPE=$(extract_var "elasticache_node_type" "cache.r6g.large")
fi
ELASTICACHE_MULTIPLE_INSTANCES=$(extract_var "multi_redis" "false")

# Extract workspace name
MIGRATED_WORKSPACE="$CLUSTER_NAME"

# Extract passwords from terraform state
# Try to extract postgres password
POSTGRES_PASSWORD=$(extract_state "module.postgres.random_string.postgres_root_password[\"postgres\"]" "result" "")
# Note: minio and paragon passwords may need to be manually set or extracted from secrets/helm values
MINIO_PASSWORD=""
PARAGON_PASSWORD=""

# Try to extract minio password from terraform state (if it exists)
MINIO_PASSWORD=$(extract_state "module.storage.random_string.minio_root_password" "result" "")

# Output the vars.auto.tfvars content
echo ""
echo "# Generated vars.auto.tfvars for enterprise workspace migration"
echo "# Generated on: $(date)"
echo ""
echo "aws_access_key_id              = \"${AWS_ACCESS_KEY_ID}\""
echo "aws_region                     = \"${AWS_REGION}\""
echo "aws_secret_access_key          = \"${AWS_SECRET_ACCESS_KEY}\""
echo "az_count                       = \"${AZ_COUNT}\""
echo "cloudflare_api_token           = \"${CLOUDFLARE_API_TOKEN}\""
echo "cloudflare_tunnel_account_id   = \"${CLOUDFLARE_TUNNEL_ACCOUNT_ID}\""
echo "cloudflare_tunnel_email_domain = \"${CLOUDFLARE_TUNNEL_EMAIL_DOMAIN}\""
echo "cloudflare_tunnel_enabled      = \"${CLOUDFLARE_TUNNEL_ENABLED}\""
echo "cloudflare_tunnel_subdomain    = \"${CLOUDFLARE_TUNNEL_SUBDOMAIN}\""
echo "cloudflare_tunnel_zone_id      = \"${CLOUDFLARE_TUNNEL_ZONE_ID}\""
echo "disable_cloudtrail             = \"${DISABLE_CLOUDTRAIL}\""
echo "disable_deletion_protection    = \"${DISABLE_DELETION_PROTECTION}\""
echo "eks_admin_arns = ["
if [ -n "$EKS_ADMIN_ROLE_ARNS_RAW" ]; then
    echo "$EKS_ADMIN_ROLE_ARNS_RAW" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^/  "/;s/$/"/'
fi
echo "]"
echo "eks_max_node_count              = \"${K8_MAX_NODE_COUNT}\""
echo "eks_min_node_count              = \"${K8_MIN_NODE_COUNT}\""
echo "eks_ondemand_node_instance_type = \"${K8_ONDEMAND_NODE_INSTANCE_TYPE}\""
echo "eks_spot_instance_percent       = \"${K8_SPOT_INSTANCE_PERCENT}\""
echo "eks_spot_node_instance_type     = \"${K8_SPOT_NODE_INSTANCE_TYPE}\""
echo "elasticache_multiple_instances  = \"${ELASTICACHE_MULTIPLE_INSTANCES}\""
echo "elasticache_node_type           = \"${ELASTICACHE_NODE_TYPE}\""
echo "k8s_version                     = \"${K8_VERSION}\""
echo "migrated_passwords = {"

# Output passwords section
if [ -n "$MINIO_PASSWORD" ] || [ -n "$PARAGON_PASSWORD" ] || [ -n "$POSTGRES_PASSWORD" ]; then
    echo "  \"minio\" : \"${MINIO_PASSWORD:-<MANUALLY_SET>}\","
    echo "  \"paragon\" : \"${PARAGON_PASSWORD:-<MANUALLY_SET>}\""
    if [ -n "$POSTGRES_PASSWORD" ]; then
        echo "  # Note: postgres password extracted from state: ${POSTGRES_PASSWORD:0:4}..."
    fi
else
    echo "  \"minio\" : \"<MANUALLY_SET>\","
    echo "  \"paragon\" : \"<MANUALLY_SET>\""
fi
echo "}"
echo "migrated_workspace     = \"${MIGRATED_WORKSPACE}\""
echo "organization           = \"${ORGANIZATION}\""
echo "rds_instance_class     = \"${RDS_INSTANCE_CLASS}\""
echo "rds_multi_az           = \"${RDS_MULTI_AZ}\""
echo "rds_multiple_instances = \"${RDS_MULTIPLE_INSTANCES}\""
echo "rds_postgres_version   = \"${RDS_POSTGRES_VERSION}\""
echo "vpc_cidr               = \"${VPC_CIDR}\""
echo "vpc_cidr_newbits       = \"${VPC_CIDR_NEWBITS}\""
echo ""
