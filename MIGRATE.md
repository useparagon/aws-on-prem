# Enterprise Migration Instructions

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

Run `terraform apply`.

## Fix State Conflicts

There will be several resources in AWS that the `enterprise` repo will attempt to recreate that result in conflicts. These can be addressed prior to applying the `enterprise` workspace with this script.

```
cd terraform/workspaces/infra
./migration-prep.sh
```
