#!/bin/bash

# This script is used to generate a vars.auto.tfvars file for the enterprise workspace migration.
# It extracts values from tthis workspace's vars.auto.tfvars and Terraform state to create a new 
# vars-migrated.auto.tfvars file for the enterprise workspace.
#
# IMPORTANT: This script must be run in this workspace directory where the resources currently exist.
# The script reads from the current workspace's Terraform state and vars.auto.tfvars file.

# Helper function to extract value from vars.auto.tfvars
# Handles both simple string values and list values (e.g., ["val1", "val2"])
extract_var() {
    local var_name="$1"
    local default_value="${2:-}"
    
    # Find the line number with the variable assignment
    local start_line=$(grep -n -E "^\s*${var_name}\s*=" "$VARS_FILE" | head -1 | cut -d: -f1)
    
    if [ -z "$start_line" ]; then
        echo "$default_value"
        return
    fi
    
    # Get the first line and check if it's a list
    local first_line=$(sed -n "${start_line}p" "$VARS_FILE")
    local value_part=$(echo "$first_line" | sed -E 's/^[^=]*=[[:space:]]*//')
    
    # Check if it's a list (starts with [)
    if echo "$value_part" | grep -q '^\['; then
        # If list closes on same line, use that; otherwise find closing bracket
        if echo "$value_part" | grep -q '\]'; then
            # Single-line list
            echo "$value_part" | grep -o '"[^"]*"' | sed 's/"//g' | tr '\n' ',' | sed 's/,$//'
        else
            # Multiline list: read until we find closing bracket
            local end_line=$(awk -v start="$start_line" 'NR >= start && /\]/ {print NR; exit}' "$VARS_FILE")
            if [ -n "$end_line" ]; then
                sed -n "${start_line},${end_line}p" "$VARS_FILE" | grep -o '"[^"]*"' | sed 's/"//g' | tr '\n' ',' | sed 's/,$//'
            else
                echo "$default_value"
            fi
        fi
    else
        # Simple string value: trim whitespace and extract quoted value if present
        echo "$value_part" | sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//'
    fi
}

# Helper function to extract value from terraform state
extract_state() {
    local resource_path="$1"
    local attribute="$2"
    local default_value="${3:-}"
    local result=$(terraform state show "$resource_path" 2>/dev/null | grep -E "^\s+${attribute}\s+=" | awk '{print $3}' | tr -d '"')
    if [ -z "$result" ]; then
        echo "$default_value"
    else
        echo "$result"
    fi
}

# Helper function to find the postgres DB instance resource path
find_postgres_resource_path() {
    terraform state list 2>/dev/null | grep -E '^module\.postgres\.aws_db_instance\.postgres(\[.+\])?$' | head -1
}

# Helper function to extract all database passwords from terraform output
# Returns a newline-separated list of "database_name=password" pairs
extract_all_database_passwords() {
    # Get terraform output as JSON
    local output_json=$(terraform output -json 2>/dev/null)
    
    if [ -z "$output_json" ]; then
        return
    fi
    
    # Extract all database names and their passwords
    # jq will output: "database_name=password" for each database
    echo "$output_json" | jq -r '.postgres.value | to_entries[] | "\(.key)=\(.value.password)"' 2>/dev/null
}

# Get script directory to locate vars.auto.tfvars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARS_FILE="${SCRIPT_DIR}/vars.auto.tfvars"

if [ ! -f "$VARS_FILE" ]; then
  echo "✗ ERROR: Could not find vars.auto.tfvars at ${VARS_FILE}"
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

# Get cluster name from Terraform state (needed for migrated_workspace variable)
CLUSTER_NAME=$(terraform state show 'module.cluster.module.eks.aws_eks_cluster.this[0]' 2>/dev/null | grep -E '^\s+name\s+=' | awk '{print $3}' | tr -d '"')

if [ -z "$CLUSTER_NAME" ]; then
  # Fallback: try to get from organization in vars.auto.tfvars
  ORGANIZATION=$(grep -E '^\s*organization\s*=' "$VARS_FILE" | awk -F'"' '{print $2}')
  if [ -n "$ORGANIZATION" ]; then
    CLUSTER_NAME="paragon-enterprise-${ORGANIZATION}"
    echo "✓ Using cluster name from organization: ${CLUSTER_NAME}"
  fi
fi

echo ""
echo "Generating vars.auto.tfvars for the new enterprise workspace..."

# Extract 1:1 mappings from vars.auto.tfvars
AWS_ACCESS_KEY_ID=$(extract_var "aws_access_key_id")
AWS_SECRET_ACCESS_KEY=$(extract_var "aws_secret_access_key")
AWS_REGION=$(extract_var "aws_region")
CLOUDFLARE_API_TOKEN=$(extract_var "cloudflare_api_token")
CLOUDFLARE_TUNNEL_ACCOUNT_ID=$(extract_var "cloudflare_tunnel_account_id")
CLOUDFLARE_TUNNEL_EMAIL_DOMAIN=$(extract_var "cloudflare_tunnel_email_domain")
CLOUDFLARE_TUNNEL_ENABLED=$(extract_var "cloudflare_tunnel_enabled" "true")
CLOUDFLARE_TUNNEL_SUBDOMAIN=$(extract_var "cloudflare_tunnel_subdomain")
CLOUDFLARE_TUNNEL_ZONE_ID=$(extract_var "cloudflare_tunnel_zone_id")
DISABLE_CLOUDTRAIL=$(extract_var "disable_cloudtrail" "true")
DISABLE_DELETION_PROTECTION=$(extract_var "disable_deletion_protection" "false")
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
POSTGRES_RESOURCE_PATH=$(find_postgres_resource_path)
if [ -n "$POSTGRES_RESOURCE_PATH" ]; then
    RDS_INSTANCE_CLASS=$(extract_state "$POSTGRES_RESOURCE_PATH" "instance_class" "")
else
    RDS_INSTANCE_CLASS=""
fi
# Fallback to default if not found
if [ -z "$RDS_INSTANCE_CLASS" ]; then
    RDS_INSTANCE_CLASS="db.t4g.small"
fi

if [ -n "$POSTGRES_RESOURCE_PATH" ]; then
    RDS_POSTGRES_VERSION=$(extract_state "$POSTGRES_RESOURCE_PATH" "engine_version" "")
else
    RDS_POSTGRES_VERSION=""
fi
# Extract from vars file as fallback
if [ -z "$RDS_POSTGRES_VERSION" ]; then
    RDS_POSTGRES_VERSION=$(extract_var "postgres_version" "16")
fi

if [ -n "$POSTGRES_RESOURCE_PATH" ]; then
    RDS_MULTI_AZ=$(extract_state "$POSTGRES_RESOURCE_PATH" "multi_az" "")
else
    RDS_MULTI_AZ=""
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

# Extract MSK values from vars.auto.tfvars or use defaults
MANAGED_SYNC_ENABLED=$(extract_var "managed_sync_enabled" "false")
MSK_KAFKA_VERSION=$(extract_var "msk_kafka_version" "3.6.0")
MSK_KAFKA_NUM_BROKER_NODES=$(extract_var "msk_kafka_num_broker_nodes" "2")
MSK_AUTOSCALING_ENABLED=$(extract_var "msk_autoscaling_enabled" "true")
MSK_INSTANCE_TYPE=$(extract_var "msk_instance_type" "kafka.t3.small")

# Extract workspace name (use cluster name if available, otherwise use organization)
if [ -n "$CLUSTER_NAME" ]; then
    MIGRATED_WORKSPACE="$CLUSTER_NAME"
else
    # Fallback to organization-based name
    MIGRATED_WORKSPACE="paragon-enterprise-${ORGANIZATION}"
fi

# Extract passwords from terraform output (sensitive values are available in output JSON)
# Extract all database passwords (supports multiple databases)
DATABASE_PASSWORDS=$(extract_all_database_passwords)

# Output the vars.auto.tfvars content to file
OUTPUT_FILE="${SCRIPT_DIR}/vars.auto.tfvars-migrated"

{
echo ""
echo "# Generated vars.auto.tfvars for enterprise workspace migration"
echo "# Generated on: $(date)"
echo ""
echo "aws_access_key_id              = \"${AWS_ACCESS_KEY_ID}\""
echo "aws_region                     = \"${AWS_REGION}\""
echo "aws_secret_access_key          = \"${AWS_SECRET_ACCESS_KEY}\""
echo "az_count                       = ${AZ_COUNT}"
echo "cloudflare_api_token           = \"${CLOUDFLARE_API_TOKEN}\""
echo "cloudflare_tunnel_account_id   = \"${CLOUDFLARE_TUNNEL_ACCOUNT_ID}\""
echo "cloudflare_tunnel_email_domain = \"${CLOUDFLARE_TUNNEL_EMAIL_DOMAIN}\""
echo "cloudflare_tunnel_enabled      = ${CLOUDFLARE_TUNNEL_ENABLED}"
echo "cloudflare_tunnel_subdomain    = \"${CLOUDFLARE_TUNNEL_SUBDOMAIN}\""
echo "cloudflare_tunnel_zone_id      = \"${CLOUDFLARE_TUNNEL_ZONE_ID}\""
echo "disable_cloudtrail             = ${DISABLE_CLOUDTRAIL}"
echo "disable_deletion_protection    = ${DISABLE_DELETION_PROTECTION}"
echo "eks_admin_arns = ["
if [ -n "$EKS_ADMIN_ROLE_ARNS_RAW" ]; then
    echo "$EKS_ADMIN_ROLE_ARNS_RAW" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^/  "/;s/$/"/'
fi
echo "]"
echo "eks_max_node_count              = ${K8_MAX_NODE_COUNT}"
echo "eks_min_node_count              = ${K8_MIN_NODE_COUNT}"
echo "eks_ondemand_node_instance_type = \"${K8_ONDEMAND_NODE_INSTANCE_TYPE}\""
echo "eks_spot_instance_percent       = ${K8_SPOT_INSTANCE_PERCENT}"
echo "eks_spot_node_instance_type     = \"${K8_SPOT_NODE_INSTANCE_TYPE}\""
echo "elasticache_multiple_instances  = ${ELASTICACHE_MULTIPLE_INSTANCES}"
echo "elasticache_node_type           = \"${ELASTICACHE_NODE_TYPE}\""
echo "k8s_version                     = \"${K8_VERSION}\""
echo "managed_sync_enabled             = ${MANAGED_SYNC_ENABLED}"
echo "msk_autoscaling_enabled          = ${MSK_AUTOSCALING_ENABLED}"
echo "msk_instance_type                = \"${MSK_INSTANCE_TYPE}\""
echo "msk_kafka_num_broker_nodes       = ${MSK_KAFKA_NUM_BROKER_NODES}"
echo "msk_kafka_version                = \"${MSK_KAFKA_VERSION}\""

# Output passwords section
echo "migrated_passwords = {"
if [ -n "$DATABASE_PASSWORDS" ]; then
    # Count total entries to handle trailing comma
    total_entries=$(echo "$DATABASE_PASSWORDS" | grep -c '=' || echo "0")
    current_entry=0
    
    # Iterate through each database=password pair
    while IFS='=' read -r db_name db_password; do
        if [ -n "$db_name" ] && [ -n "$db_password" ]; then
            current_entry=$((current_entry + 1))
            if [ "$current_entry" -eq "$total_entries" ]; then
                # Last entry, no trailing comma
                echo "  \"${db_name}\" : \"${db_password}\""
            else
                # Not last entry, include comma
                echo "  \"${db_name}\" : \"${db_password}\","
            fi
        fi
    done <<< "$DATABASE_PASSWORDS"
else
    echo "  # No database passwords found"
fi
echo "}"

echo "migrated_workspace     = \"${MIGRATED_WORKSPACE}\""
echo "organization           = \"${ORGANIZATION}\""
echo "rds_instance_class     = \"${RDS_INSTANCE_CLASS}\""
echo "rds_multi_az           = ${RDS_MULTI_AZ}"
echo "rds_multiple_instances = ${RDS_MULTIPLE_INSTANCES}"
echo "rds_postgres_version   = \"${RDS_POSTGRES_VERSION}\""
echo "vpc_cidr               = \"${VPC_CIDR}\""
echo "vpc_cidr_newbits       = ${VPC_CIDR_NEWBITS}"
echo ""
} > "$OUTPUT_FILE"

echo "✓ Generated migrated variables file at ${OUTPUT_FILE}"
echo ""
