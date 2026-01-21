# Enterprise Migration Instructions for `infra`

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

## Remove Incompatible Resources

Set `migration_prep = true` in [vars.auto.tfvars](./terraform/workspaces/infra/vars.auto.tfvars). This will destroy the bastion and cloudflare tunnel. These modules are incompatible with those used in the `enterprise` repo and too complex to attempt to migrate piecemeal. So they will be destroyed and recreated.

```
cd terraform/workspaces/infra
terraform init
terraform plan
terraform apply
```

*NOTE: this will result in a new bastion private key and instance so any previous connections will have to be recreated.*

The bastion log bucket may have to be manually emptied and deleted if Terraform fails to do that.

## Create Variables for `enterprise`

The tfvars file that the `enterprise` infra workspace uses should be created from this repo to ensure that all of the configurations match. This will produce a `vars.auto.tfvars-migrated` that should be moved to `enterprise/aws/workspaces/infra/vars.auto.tfvars`.

```
cd terraform/workspaces/infra
./migrate-tfvars.sh
```

## Switch to enterprise repo

The remaining steps should be executed in the `enterprise/aws/workspaces/infra` workspace.

## Fix State Conflicts

There will be several resources in AWS that the `enterprise` repo will attempt to recreate that result in conflicts. These can be addressed prior to applying the `enterprise` workspace with this script.

```
cd aws/workspaces/infra
terraform init
./migrate-state.sh
```

## Apply Changes

Plan and apply Terraform as normal.

```
cd aws/workspaces/infra
terraform plan
terraform apply
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
