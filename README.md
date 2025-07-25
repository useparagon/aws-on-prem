<p align="center">
  <a href="https://www.useparagon.com/" target="blank"><img src="./assets/paragon-logo-dark.png" width="320" alt="Paragon Logo" /></a>
</p>

<p align="center">
  <b>
    The embedded integration platform for developers.
  </b>
</p>

## ⚠️ DEPRECATION NOTICE ⚠️

**This repository has been deprecated and is no longer actively maintained.**

**For new deployments, please use the new [Paragon Enterprise repository](https://github.com/useparagon/enterprise) instead.**

The AWS-specific functionality from this repository has been moved to the `./aws` folder in the new enterprise repository. The new repository provides:

- Multi-cloud support (AWS, GCP, Azure)
- Improved infrastructure management
- Better security and monitoring
- Active maintenance and updates

**If you're starting a new Paragon deployment, please use:**
- **Repository:** https://github.com/useparagon/enterprise
- **AWS Documentation:** https://github.com/useparagon/enterprise/tree/main/aws

We will also be proactively reaching out to known users of this repository to assist with the migration process.

This repository will remain available for reference but will not receive updates or security patches.

---

## Overview

This repository is a set of tools to help you run Paragon on your own AWS infrastructure. Paragon comes bundled with a set of docker images, meaning you can run it on AWS, GCP, Azure, or any other server or cloud that supports Docker and has internet connectivity. It’s most resilient when running in Kubernetes.

This repo provides tools to deploy it to your own AWS cloud using AWS EKS (Elastic Kubernetes Service).

## Disclaimers

### Modification strongly discouraged.

We’re constantly deploying new versions of Paragon’s code and infrastructure which often include additional microservices, updates to infrastructure, improved security and more. To ensure new releases of Paragon are compatible with your infrastructure, modifying this repo is strongly discouraged to ensure compatability with future Helm charts and versions of the repo.

Instead of making changes, either:

- send a request to our engineering team to modify the repo (preferred)
- open a pull request with your changes

### ⭐️ We offer managed on premise solutions. ⭐️

If you want to deploy Paragon to your own cloud but don’t want to manage the infrastructure, we’ll do it for you. Nearly 100% of our on premise customers use this solution. Benefits include:

- additional helm charts with dozens of custom built Grafana dashboards to monitor alerts
- continuous monitoring of infrastructure
- cost optimizations on resources

We offer managed on premise solutions for AWS, Azure, and GCP. Please contact **[sales@useparagon.com](mailto:sales@useparagon.com)**, and we’ll get you started.

## Getting Started

### Access

For this repo to work, you’ll need a few additional things:

- the Paragon helm chart
- a Paragon license
- a [Docker account](https://www.docker.com/) that has been given read access to the Docker repositories

If you don't already have a license, please contact **[sales@useparagon.com](mailto:sales@useparagon.com)**, and we’ll get you connected.

### Local Machine

The machine that is being used to perform the setup will require the following software to be installed:

- [git](https://github.com/git-guides/install-git)
- [node](https://nodejs.org/en/download)
- [yarn](https://yarnpkg.com/getting-started/install)
- [docker](https://docs.docker.com/engine/install/)
- [terraform](https://developer.hashicorp.com/terraform/downloads)

### Additional Resources

To use this repository and run Paragon, you’ll additionally need:

- an [AWS account](https://aws.amazon.com/) to provision the resources and deploy the application
- a [Terraform Cloud account](https://www.terraform.io/) for managing the infrastructure state
- a [SendGrid account](https://sendgrid.com/) to send emails
- a domain name that the Paragon microservices can be reached at

**AWS Account**

From your AWS account, you’ll need:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- AWS_SESSION_TOKEN (optional)

**Terraform Account**

- organization
- API token
- two workspaces: one for the infrastructure and a second for the helm chart
  - for ease of use these should be configured to "Auto apply"

**SendGrid Account**

- API key
- email: one that has been approved from the SendGrid dashboard to send emails

**Domain Name**

A [Route53 zone](https://aws.amazon.com/route53/) will be created to manage the nameservers for this domain. Several CNAMEs will be created under this.

## Usage

If you’re bringing your own infrastructure (e.g. Kubernetes cluster, Redis, Postgres, etc), skip steps 4 and 5. Jump to the **Providing your own infrastructure** section to reference the resources you'll need.

### 1. Clone the repository and build the Docker image.

```bash
git clone https://github.com/useparagon/aws-on-prem.git paragon-on-prem
cd paragon-on-prem
make -s build
make -s tf-version
yarn install
```

Confirm that when running `make -s tf-version`, you see the following output or similar:

```bash
Terraform v1.2.4
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.3.3. You can update by downloading from https://www.terraform.io/downloads.html
```

### 2. Add the helm chart.

Copy the Helm chart provided into `terraform/workspaces/paragon/charts`. It should look like this:

```bash
...
terraform/
  workspaces/
    paragon/
      charts/
        paragon-onprem
          Chart.yaml
          values.yaml
          ...
```

### 3. Copy environment variable files.

Copy the environment variable files into the `.secure/` directory and remove `.example` from the file name.

```bash
cp .env-tf-infra.example .secure/.env-tf-infra
cp .env-tf-paragon.example .secure/.env-tf-paragon
cp values.yaml.example .secure/values.yaml
```

### 4. Configure the `.secure/.env-tf-infra` file.

**Required**

- `AWS_ACCESS_KEY_ID`: your AWS access key id
- `AWS_REGION`: the AWS region to deploy resources to
- `AWS_SECRET_ACCESS_KEY`: your AWS secret access key
- `TF_ORGANIZATION`: the name of the organization your Terraform account belongs to
- `TF_TOKEN`: your Terraform API key
- `TF_WORKSPACE`: the Terraform workspace for the infrastructure

**Optional**

- `AWS_SESSION_TOKEN`: the AWS session token for authenticating Terraform
- `DISABLE_CLOUDTRAIL`: Set to `false` to disable creation of Cloudtrail resources. (default: `false`)
- `DISABLE_DELETION_PROTECTION`: Set to `true` to disable deletion protection (ie. ephemeral installations) (default: `false`)
- `DISABLE_LOGS`: Set to `true` to disable system level logs gathering (defaults: `false`)
- `EKS_ADDON_EBS_CSI_DRIVER_ENABLED`: Whether or not to disable creating the EKS EBS CSI Driver. Required for Kubernetes versions >= `1.23`. (default: `true`)
- `EKS_ADMIN_USER_ARNS`: Comma-separated list of ARNs for IAM users that should have admin access to the cluster.
- `ELASTICACHE_NODE_TYPE`: the ElastiCache [instance type](https://aws.amazon.com/elasticache/pricing/) (default: `cache.r6g.large`)
- `K8_MAX_NODE_COUNT`: The maximum number of nodes to run in the Kubernetes cluster. (default: `20`)
- `K8_MIN_NODE_COUNT`: The minimum number of nodes to run in the Kubernetes cluster. (default: `12`)
- `K8_ONDEMAND_NODE_INSTANCE_TYPE`: The compute instance type to use for ondemand Kubernetes EC2 nodes. (default: `t3a.medium,t3.medium`)
- `K8_SPOT_INSTANCE_PERCENT`: The percentage of spot instances to use for Kubernetes EC2 nodes. (default: `75`)
- `K8_SPOT_NODE_INSTANCE_TYPE`: The compute instance type to use for spot Kubernetes EC2 nodes. (default: `t3a.medium,t3.medium`)
- `K8_VERSION`: Version of kubernetes to run. (default `1.25`)
- `MASTER_GUARDDUTY_ACCOUNT_ID`: AWS account id that Cloudtrail events will be sent to
- `MULTI_AZ_ENABLED`: Whether or not to enable multi-az for resources. (default: `true`)
- `MULTI_POSTGRES`: Whether or not to create multiple Postgres instances. Used for high volume installations. (default: `false`)
- `MULTI_REDIS`: Whether or not to create multiple Redis instances. Used for high volume installations. (default: `false`)
- `POSTGRES_VERSION`: the version of Postgres to run
- `RDS_FINAL_SNAPSHOT_ENABLED`: Specifies that RDS should take a final snapshot (default: `true`)
- `RDS_INSTANCE_CLASS`: the RDS [instance type](https://aws.amazon.com/rds/postgresql/pricing/) (default: `db.t3.small`)
- `RDS_RESTORE_FROM_SNAPSHOT`: Specifies that RDS instance(s) should be restored from snapshots (default: `false`)
- `SSH_WHITELIST`: your current IP address which will allow you SSH into the bastion to debug the Kubernetes cluster
- `VPC_CIDR_NEWBITS`: Set to a number to configure newbits used to calculate subnets used in `cidrsubnet` function. e.g. a `/16` VPC CIDR with newbits=4 will result in 4096 IPs per subnet.

### 5. Deploy the infrastructure.

Run the following command to provision the infrastructure:

```bash
make -s deploy-infra
```

You should see Terraform initialize the modules and prepare a remote plan. Type `yes` to create the infrastructure.

Note that if this is a new account or workspace that you may have to approve it in the web UI also. This can be bypassed in the future by selecting "Auto apply" under the general workspace settings.

Confirm that all the resources are created.

### 6. Configure the `.secure/.env-tf-paragon` file.

Get the state from the infra workspace by running the following command:

```bash
make -s state-infra
```

Configure the environment variables:

**Required**

- `AWS_ACCESS_KEY_ID`: your AWS access key id
- `AWS_REGION`: the AWS region to deploy resources to
- `AWS_SECRET_ACCESS_KEY`: your AWS secret access key
- `DOCKER_EMAIL`: your Docker email
- `DOCKER_PASSWORD`: your Docker password
- `DOCKER_USERNAME`: your Docker username
- `DOMAIN`: your domain name
- `ORGANIZATION`: the name of your organization (no spaces, all lowercase)
- `TF_ORGANIZATION`: the name of the organization your Terraform account belongs to
- `TF_TOKEN`: your Terraform API key
- `TF_WORKSPACE`: the Terraform workspace for the helm chart. **Make sure this is different than the infra workspace!**

**Required (from infra workspace):**

These variables should be pulled from the `infra` workspace.

- `AWS_WORKSPACE`: retrieve from `workspace` output. Used to configure [resource groups](https://docs.aws.amazon.com/ARG/latest/userguide/resource-groups.html)
- `CLUSTER_NAME`: retrieve from `cluster_name` output. Name of your EKS cluster.
- `LOGS_BUCKET`: retrieve from `logs_bucket` output. Bucket to store system logs. It can be left empty if `DISABLE_LOGS` is `true`.

**Optional**

- `ACM_CERTIFICATE_ARN`: Use to provide your own existing certificate ACM certificate ARN for use with the load balancer
- `CLOUDFLARE_DNS_API_TOKEN`: Cloudflare api token to use when updating nameservers.
- `CLOUDFLARE_ZONE_ID`: Cloudflare zone id to use when updating nameservers.
- `DISABLE_DOCKER_VERIFICATION`: Set to `false` when running the installer outside of Docker
- `DNS_PROVIDER`: specifies which DNS provider to update nameservers. Currently only supports `cloudflare`
- `ENVIRONMENT`: used when deploying multiple installations of Paragon. should be left empty or set to `enterprise`
- `K8_VERSION`: Version of kubernetes to run. Defaults to `1.25`
- `MONITORS_ENABLED`: flag to deploy monitoring resources such as Grafana and Prometheus
- `MONITOR_VERSION`: monitoring version that should typically match `VERSION` below

### 7. Configure the `.secure/values.yaml` file.

**Required**

- `LICENSE`: your Paragon license
- `SENDGRID_API_KEY`: your SendGrid API key
- `SENDGRID_FROM_ADDRESS`: the email to send SendGrid emails from
- `VERSION`: the version of Paragon you want to run

**Required (from `paragon_config` output variable in infra workspace)**

- `MINIO_MICROSERVICE_PASS`: from `minio_microservice_pass` output
- `MINIO_MICROSERVICE_USER`: from `minio_microservice_user` output
- `MINIO_PUBLIC_BUCKET`: from `minio_public_bucket` output
- `MINIO_ROOT_PASSWORD`: from `minio_root_password` output
- `MINIO_ROOT_USER`: from `minio_root_user` output
- `MINIO_SYSTEM_BUCKET`: from `minio_private_bucket` output
- `POSTGRES_DATABASE`: from `postgres` output
- `POSTGRES_HOST`: from `postgres` output
- `POSTGRES_PASSWORD`: from `postgres` output
- `POSTGRES_PORT`: from `postgres` output
- `POSTGRES_USER`: from `postgres` output
- `REDIS_HOST`: from `redis` output
- `REDIS_PORT`: from `redis` output

#### Configuring multiple Postgres instances.

If you have `MULTI_POSTGRES` enabled, instead of using `POSTGRES_*` variables, you'll configure the following variables from the `postgres` output. **NOTE**: Beethoven and Pheme should point to the same database.

```yaml
    BEETHOVEN_POSTGRES_HOST: 
    BEETHOVEN_POSTGRES_PORT: 
    BEETHOVEN_POSTGRES_USERNAME: 
    BEETHOVEN_POSTGRES_PASSWORD: 
    BEETHOVEN_POSTGRES_DATABASE: 

    CERBERUS_POSTGRES_HOST: 
    CERBERUS_POSTGRES_PORT: 
    CERBERUS_POSTGRES_USERNAME: 
    CERBERUS_POSTGRES_PASSWORD: 
    CERBERUS_POSTGRES_DATABASE: 

    HERMES_POSTGRES_HOST: 
    HERMES_POSTGRES_PORT: 
    HERMES_POSTGRES_USERNAME: 
    HERMES_POSTGRES_PASSWORD: 
    HERMES_POSTGRES_DATABASE: 

    PHEME_POSTGRES_HOST: 
    PHEME_POSTGRES_PORT: 
    PHEME_POSTGRES_USERNAME: 
    PHEME_POSTGRES_PASSWORD: 
    PHEME_POSTGRES_DATABASE: 

    ZEUS_POSTGRES_HOST: 
    ZEUS_POSTGRES_PORT: 
    ZEUS_POSTGRES_USERNAME: 
    ZEUS_POSTGRES_PASSWORD: 
    ZEUS_POSTGRES_DATABASE: 

    EVENT_LOGS_POSTGRES_HOST: 
    EVENT_LOGS_POSTGRES_PORT: 
    EVENT_LOGS_POSTGRES_USERNAME: 
    EVENT_LOGS_POSTGRES_PASSWORD: 
    EVENT_LOGS_POSTGRES_DATABASE: 

```

#### Configuring multiple Redis instances.

If you have `MULTI_REDIS` enabled, instead of using `REDIS_*` variables, you'll configure the following variables from the `redis` output. **NOTE**: Cache and Workflow should point to the same Redis.

```yaml
    CACHE_REDIS_URL: 
    WORKFLOW_REDIS_URL: 
    SYSTEM_REDIS_URL: 
    QUEUE_REDIS_URL: 

    CACHE_REDIS_CLUSTER_ENABLED: true
    SYSTEM_REDIS_CLUSTER_ENABLED: false
    QUEUE_REDIS_CLUSTER_ENABLED: false
    WORKFLOW_REDIS_CLUSTER_ENABLED: true
```

### 8. Optionally configure the `.secure/features.yml` file.

If the deployment will not have access to Paragon's `feature-flag` repository for GitOps-based flags then the flags can be configured locally. Paragon can provide an export of this file since the options change regularly. If using Git then this file should not exist. The format will look like this:

```yaml
namespace: production
flags:
  - key: MFA_RECOVERY_CODES_ENABLED
    description: Enable MFA Recovery Codes
    name: MFA_RECOVERY_CODES_ENABLED
    type: BOOLEAN_FLAG_TYPE
    rollouts:
      - description: Enabled for Organizations by ID
        segment:
          key: mfa-recovery-codes-enabled-organizations
          value: true
      - description: Disabled for all other users
        segment:
          key: all-users
          value: false
  - key: MFA_ENABLED
    description: Enable MFA
    name: MFA_ENABLED
    type: BOOLEAN_FLAG_TYPE
    rollouts:
      - description: Enabled for Organizations by ID
        segment:
          key: mfa-enabled-organizations
          value: true
      - description: Disabled for all other users
        segment:
          key: all-users
          value: false
```

### 9. Deploy the Helm chart.

Deploy the Paragon helm chart to your Kubernetes cluster. Run the following command:

```bash
make -s deploy-paragon
```

Confirm that Terraform executed successfully.

### 10. Update your nameservers.

You’ll need to update the nameservers for your domain to be able to access the services. Run the following command:

```bash
make -s state-paragon
```

Go to the website where you registered your domain (e.g. Namecheap, Cloudflare, Route53), and update the nameservers. If the domain is a subdomain, e.g. `subdomain.domain.com`, you’ll need to add `NS` entries for the subdomain. If the domain is a root domain, e.g. `domain.com`, you’ll need to update the nameservers for the domain.

### 11. Open the application.

Visit `https://dashboard.<YOUR_DOMAIN>` on your browser to view the dashboard. Register an account and get started!

## Providing your own infrastructure

This repository is split into two Terraform workspaces so you can optionally bring your own infrastructure that you can deploy the Paragon helm chart to. If so, you’ll need:

- VPC with public and private subnets ([docs](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html))
- Kubernetes cluster ([EKS](https://aws.amazon.com/eks/))
- Redis instance ([ElastiCache](https://aws.amazon.com/elasticache/))
- Postgres instance ([RDS](https://aws.amazon.com/rds/))
- two S3 buckets:
  - 1 with public access
  - 1 with private access

Configuring this is currently outside of the scope of this repository. Please consult the `terraform/workspaces/infra` directory to view the required configuration and use the outputs to configure the variables in `.secure/values.yaml`.

## Destroying the infrastructure.

To destroy the infrastructure, you’ll need to first destroy the `paragon` workspace, then the `infra` workspace.

```bash
make -s deploy-paragon initialize=false plan=false destroy=true
make -s deploy-infra initialize=false plan=false destroy=true
```

## Makefile

This repo comes with a `Makefile` and CLI to execute commands. Here are the commands and their arguments:

```bash
build                       # builds the docker image

tf-version                  # echos the terraform version

state-infra                 # gets the state of the infra workspace (comparable to terraform -chdir=terraform/workspaces/infra output -json)

state-paragon               # gets the state of the paragon workspace (comparable to terraform -chdir=terraform/workspaces/paragon output -json)

deploy-infra                # deploys the infrastructure
  debug={true,false}        # (optional) print additional debugging information
  initialize={true,false}   # (optional) used to skip the `terraform init` command
  plan={true,false}         # (optional) used to skip the `terraform plan` command
  apply={true,false}        # (optional) used to skip the `terraform apply` command
  destroy={true,false}      # (optional) used to run `terraform destroy` command
  target                    # (optional) used to specify a target for the Terraform operation
  args                      # (optional) additional arguments to pass to Terraform

deploy-paragon              # deploys the Paragon helm chart
  debug={true,false}        # (optional) print additional debugging information
  initialize={true,false}   # (optional) used to skip the `terraform init` command
  plan={true,false}         # (optional) used to skip the `terraform plan` command
  apply={true,false}        # (optional) used to skip the `terraform apply` command
  destroy={true,false}      # (optional) used to run `terraform destroy` command
  target                    # (optional) used to specify a target for the Terraform operation
  args                      # (optional) additional arguments to pass to Terraform
```

**Examples**

```bash
make -s build

make -s tf-version

make -s state-infra

make -s state-paragon

make -s deploy-infra
make -s deploy-infra initialize=false
make -s deploy-infra destroy=true target=module.cluster args=-auto-approve

make -s deploy-paragon
make -s deploy-paragon initialize=false plan=true apply=false target=module.alb
```

## Connecting to the Bastion

To debug the Kubernetes cluster, the `infra` workspace provisions a bastion that you can SSH into. After successfully provisioning the infra workspace:

1. Run `make -s state-infra`
2. Copy the value of `bastion_private_key` from the Terraform state into a new file at `.secure/id_rsa` (replacing `\n` with newlines)
3. Run `chmod 600 .secure/id_rsa`
4. Copy the bastion url from `bastion_load_balancer` from the Terraform state.
5. Run `ssh -i .secure/id_rsa ubuntu@<BASTION_LOAD_BALANCER_URL>`

Once you're in the bastion, you should be able to use `kubectl` to interact with the cluster. If it's not connecting run the following commands. Make sure to replace the placeholders.

```bash
aws eks --region <AWS_REGION> update-kubeconfig --name <CLUSTER_NAME>
kubectl config set-context --current --namespace=paragon
```
