# Enterprise Migration Instructions for `infra`

## Preparation

### Upgrade Terraform

`aws-on-prem` used Terraform 1.2.4 but `enterprise` uses 1.9.6. This must generally be done on Terraform Cloud either through the UI settings for the workspace or via an API call like below. It requires a Terraform API key as the bearer and the workspace ID.

```
curl \
  --header "Authorization: Bearer <terraform key>" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  --data '{
    "data": {
      "type": "workspaces",
      "attributes": {
        "terraform-version": "1.9.6",
        "execution-mode": "local"
      }
    }
  }' \
  https://app.terraform.io/api/v2/workspaces/<workspace id>
```

### Apply Latest Infrastructure

Ensure that the infrastructure is up to date with latest Terraform configs. This will minimize any non-migration related changes later on in the process that could cause issues.

The manual `terraform state mv` steps are required to avoid `Cross-package move statement` errors.

```
git pull
make deploy-infra apply=false
cd terraform/workspaces/infra
terraform init
terraform state mv 'module.cluster.module.eks.aws_eks_addon.this["coredns"]' 'module.cluster.aws_eks_addon.addons["coredns"]'
terraform state mv 'module.cluster.module.eks.aws_eks_addon.this["kube-proxy"]' 'module.cluster.aws_eks_addon.addons["kube-proxy"]'
terraform state mv 'module.cluster.module.eks.aws_eks_addon.this["vpc-cni"]' 'module.cluster.aws_eks_addon.addons["vpc-cni"]'
terraform plan
terraform apply
```

## Migration

### Remove Incompatible Resources

Set `migration_prep = true` in [vars.auto.tfvars](./terraform/workspaces/infra/vars.auto.tfvars). This will destroy the bastion and cloudflare tunnel. These modules are incompatible with those used in the `enterprise` repo and too complex to attempt to migrate piecemeal. So they will be destroyed and recreated.

```
cd terraform/workspaces/infra
terraform plan
terraform apply
```

*NOTE: this will result in a new bastion private key and instance so any previous connections will have to be recreated.*

The bastion log bucket may have to be manually emptied and deleted if Terraform fails to do that.

### Create Variables for `enterprise`

The tfvars file that the `enterprise` infra workspace uses should be created from this repo to ensure that all of the configurations match. This will produce a `vars.auto.tfvars-migrated` that should be moved to `enterprise/aws/workspaces/infra/vars.auto.tfvars`.

```
cd terraform/workspaces/infra
./migrate-tfvars.sh
```

### Switch to enterprise repo

The remaining steps should be executed in the `enterprise/aws/workspaces/infra` workspace. This repo will have to be cloned separately and use the same remote settings in `main.tf` as `aws-on-prem`'s `infra` workspace.

### Fix State Conflicts

There will be several resources in AWS that the `enterprise` repo will attempt to recreate that result in conflicts. These can be addressed prior to applying the `enterprise` workspace with this script.

```
cd aws/workspaces/infra
terraform init
./migrate-state.sh
```

### Apply Changes

Plan and apply Terraform as normal. The `apply` step can be retried if there are initial failures.

```
cd aws/workspaces/infra
terraform plan
terraform apply
```

If EKS access entries fail with this error:

```
│ Error: creating EKS Access Entry (<ACCESS_ENTRY_KEY>): operation error EKS: CreateAccessEntry, https response error StatusCode: 409, RequestID: <uuid>, ResourceInUseException: The specified access entry resource is already in use on this cluster.
```

Then the entry can be fixed by running the `enterprise/aws/workspaces/infra/migrate-state.sh <ACCESS_ENTRY_KEY>` like below.

```
cd aws/workspaces/infra
./migrate-state.sh 'paragon-enterprise:arn:aws:iam::024680246802:role/paragon-installer'
```

### Prepare for `paragon` Migration

```
./prepare.sh -p aws -t <PARAGON_VERSION>

cd aws/workspaces/infra
terraform output -json > ../paragon/.secure/infra-output.json
```

---

# Enterprise Migration Instructions for `paragon`

## Upgrade Terraform

`aws-on-prem` used Terraform 1.2.4 but `enterprise` uses 1.9.6. This must generally be done on Terraform Cloud either through the UI settings for the workspace or via an API call like below. It requires a Terraform API key as the bearer and the workspace ID.

```
curl \
  --header "Authorization: Bearer <terraform key>" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  --data '{
    "data": {
      "type": "workspaces",
      "attributes": {
        "terraform-version": "1.9.6",
        "execution-mode": "local"
      }
    }
  }' \
  https://app.terraform.io/api/v2/workspaces/<workspace id>
```

### Switch to enterprise repo

The remaining steps should be executed in the `enterprise/aws/workspaces/paragon` workspace. This use the same remote settings in `main.tf` as `aws-on-prem`'s `paragon` workspace.

### Create Variables for `paragon`

Copy the `aws-on-prem/.secure/values.yaml` to `enterprise/aws/workspaces/paragon/.secure/values.yaml`.

Copy the `aws-on-prem/terraform/workspaces/paragon/vars.auto.tfvars` to `enterprise/aws/workspaces/paragon/vars.auto.tfvars` and remove these deprecated variables:
- aws_workspace
- cluster_name
- disable_docker_verification
- helm_env
- helm_values
- logs_bucket
- supported_microservices
- tf_organization
- tf_token
- tf_workspace

### Verify Bastion Connectivity

The `enterprise/aws/workspaces/paragon/.secure/infra-output.json` file contains connection information for the updated bastion. Verify that you can connect to it.

Create an executable `migrate-pvc.sh` file on the bastion with the contents from [terraform/workspaces/paragon/migrate-pvc.sh](terraform/workspaces/paragon/migrate-pvc.sh).

```
vi migrate-pvc.sh
chmod +x migrate-pvc.sh
```

### Apply Changes

Plan and apply Terraform as normal.

```
cd aws/workspaces/paragon
terraform init
terraform plan
terraform apply
```

As soon as `kubectl get storageclass` shows a `gp3 (default)` entry then the `migrate-pvc.sh` script can be executed on the bastion to update the PVC settings that cannot be modified with Helm.

```
./migrate-pvc.sh
```
