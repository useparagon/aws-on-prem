<p align="center">
  <a href="https://www.useparagon.com/" target="blank"><img src="./assets/paragon-logo-dark.png" width="320" alt="Paragon Logo" /></a>
</p>

<p align="center">
  <b>
    The embedded integration platform for developers.
  </b>
</p>

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

### Additional Resources

To use this repository and run Paragon, you’ll additionally need:

- an [AWS account](https://aws.amazon.com/) to provision the resources and deploy the application
- a [Terraform account](https://www.terraform.io/) for managing the infrastructure state
- a [SendGrid account](https://sendgrid.com/) to send emails
- a domain name that the Paragon microservices can be reached at

**AWS Account**

From your AWS account, you’ll need:

- access key id
- access secret key
- aws region

**Terraform Account**

- organization
- API token
- 2 workspaces: one for the infrastructure and a second for the helm chart

**SendGrid Account**

- API key
- email: one that has been approved from the SendGrid dashboard to send emails

**Domain Name**

A [Route53 zone](https://aws.amazon.com/route53/) will be created to manage the nameservers for this domain. Several CNAMEs will be created under this.

## Usage

If you’re bringing your own infrastructure (e.g. Kubernetes cluster, Redis, Postgres, etc), skip steps 4 and 5. Jump to the **Providing your own infrastructure** section to reference the resources you'll need.

### 1. Clone the repository and build the Docker image.

```tsx
> git clone git@github.com:useparagon/aws-on-prem.git paragon-on-prem
> cd paragon-on-prem
> make -s build
> make -s tf-version
```

Confirm that when running `make -s tf-version`, you see the following output or similar:

```tsx
Terraform v1.2.4
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.3.3. You can update by downloading from https://www.terraform.io/downloads.html
```

### 2. Add the helm chart.

Copy the Helm chart provided into `terraform/workspaces/paragon/charts`. It should look like this:

```tsx
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

```tsx
> cp .env-helm.example .secure/.env-helm
> cp .env-tf-infra.example .secure/.env-tf-infra
> cp .env-tf-paragon.example .secure/.env-tf-paragon
```

### 4. Configure the `.secure/.env-infra` file.

**Required**

 - `AWS_ACCESS_KEY_ID`: your AWS access key id
 - `AWS_REGION`: the AWS region to deploy resources to
 - `AWS_SECRET_ACCESS_KEY`: your AWS secret access key
 - `TF_ORGANIZATION`**:** the name of the organization your Terraform account belongs to
 - `TF_TOKEN`: your Terraform API key
 - `TF_WORKSPACE`**:** the Terraform workspace for the infrastructure

**Optional**

 - `AWS_SESSION_TOKEN`: the AWS session token for authenticating Terraform
 - `DISABLE_CLOUDTRAIL`: Set to `false` to disable creation of Cloudtrail resources
 - `DISABLE_DOCKER_VERIFICATION`: Set to `false` when running the installer outside of Docker
 - `DISABLE_DELETION_PROTECTION`: Set to `true` to disable deletion protection (ie. ephemeral installations) (default: `false`)
 - `ELASTICACHE_NODE_TYPE`: the ElastiCache [instance type](https://aws.amazon.com/elasticache/pricing/)
 - `MASTER_GUARDDUTY_ACCOUNT_ID`: AWS account id that Cloudtrail events will be sent to
 - `POSTGRES_VERSION`: the version of Postgres to run
 - `RDS_INSTANCE_CLASS`: the RDS [instance type](https://aws.amazon.com/rds/postgresql/pricing/)
 - `SSH_WHITELIST`**:** your current IP address which will allow you SSH into the bastion to debug the Kubernetes cluster
 - `VPC_CIDR_NEWBITS`: Set to a number to configure newbits used to calculate subnets used in `cidrsubnet` function

### 5. Deploy the infrastructure.

Run the following command to provision the infrastructure:

```tsx
> make -s deploy-infra
```

You should see Terraform initialize the modules and prepare a remote plan. Type `yes` to create the infrastructure.

Confirm that all the resources are created.

### 6. Configure the `.secure/.env-tf-paragon` file.

Get the state from the infra workspace by running the following command:

```tsx
> make -s state-infra
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

**Optional**

 - `ACM_CERTIFICATE_ARN`: Use to provide your own existing certificate ACM certificate ARN for use with the load balancer
 - `DISABLE_DOCKER_VERIFICATION`: Set to `false` when running the installer outside of Docker
 - `ENVIRONMENT`: used when deploying multiple installations of Paragon. should be left empty or set to `enterprise`

### 7. Configure the `.secure/.env-helm` file.

**Required**

 - `LICENSE`: your Paragon license
 - `SENDGRID_API_KEY`: your SendGrid API key
 - `SENDGRID_FROM_ADDRESS`: the email to send SendGrid emails from
 - `VERSION`: the version of Paragon you want to run

**Required (from infra workspace)**

 - `MINIO_MICROSERVICE_PASS`: from `minio_microservice_pass` output
 - `MINIO_MICROSERVICE_USER`: from `minio_microservice_user` output
 - `MINIO_PUBLIC_BUCKET`: from `minio_public_bucket` output
 - `MINIO_ROOT_PASSWORD`: from `minio_root_password` output
 - `MINIO_ROOT_USER`: from `minio_root_user` output
 - `MINIO_SYSTEM_BUCKET`: from `minio_private_bucket` output
 - `POSTGRES_DATABASE`: from `postgres_database` output
 - `POSTGRES_HOST`: from `postgres_host` output
 - `POSTGRES_PASSWORD`: from `postgres_password` output
 - `POSTGRES_PORT`: from `postgres_port` output
 - `POSTGRES_USER`: from `postgres_user` output
 - `REDIS_HOST`: from `redis_host` output
 - `REDIS_PORT`: from `redis_port` output

### 8. Deploy the Helm chart.

Deploy the Paragon helm chart to your Kubernetes cluster. Run the following command:

```tsx
> make -s deploy-paragon
```

Confirm that Terraform executed successfully.

### 9. Update your nameservers.

You’ll need to update the nameservers for your domain to be able to access the services. Run the following command:

```tsx
> make -s state-paragon
```

Go to the website where you registered your domain (e.g. Namecheap, Cloudflare), and update the nameservers. If the domain is a subdomain, e.g. `subdomain.domain.com`, you’ll need to add `NS` entries for the subdomain. If the domain is a root domain, e.g. `domain.com`, you’ll need to update the nameservers for the domain.

### 10. Open the application.

Visit `https://dashboard.<YOUR_DOMAIN>` on your browser to view the dashboard. Register an account and get started!

## Providing your own infrastructure

This repository is split into two Terraform workspaces so you can optionally bring your own infrastructure that you can deploy the Paragon helm chart to. If so, you’ll need:

- VPC with public and private subnets ([docs](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html))
- Kubernetes cluster ([EKS](https://aws.amazon.com/eks/))
- Redis instance ([ElastiCache](https://aws.amazon.com/elasticache/))
- Postgres instance ([RDS](https://aws.amazon.com/rds/))
- 2 S3 buckets:
  - 1 with public access
  - 1 with private access

Configuring this is currently outside of the scope of this repository. Please consult the `terraform/workspaces/infra` directory to view the required configuration and use the outputs to configure the variables in `.secure/.env-helm`.

## Destroying the infrastructure.

To destroy the infrastructure, you’ll need to first destroy the `paragon` workspace, then the `infra` workspace.

```tsx
> make -s deploy-paragon initialize=false plan=false destroy=true
> make -s deploy-infra initialize=false plan=false destroy=true
```

## Makefile

This repo comes with a `Makefile` and CLI to execute commands. Here are the commands and their arguments:

```tsx
build                       # builds the docker image

tf-version                  # echos the terraform version

state-infra                 # gets the state of the infra workspace

state-paragon               # gets the state of the helm workspace

deploy-infra                # deploys the infrastructure
  debug={true,false}        # (optional) print additional debugging information
  initialize={true,false}   # (optional) used to skip the `terraform init` command
  plan={true,false}         # (optional) used to skip the `terraform plan` command
  apply={true,false}        # (optional) used to skip the `terraform apply` command
  destroy={true,false}      # (optional) used to run `terraform destroy` command
  target                    # (optional) used to specify a target for the Terraform operation
  args                      # (optional) additional arguments to pass to Terraform

deploy-paragon # deploys the Paragon helm chart
  debug={true,false}        # (optional) print additional debugging information
  initialize={true,false}   # (optional) used to skip the `terraform init` command
  plan={true,false}         # (optional) used to skip the `terraform plan` command
  apply={true,false}        # (optional) used to skip the `terraform apply` command
  destroy={true,false}      # (optional) used to run `terraform destroy` command
  target                    # (optional) used to specify a target for the Terraform operation
  args                      # (optional) additional arguments to pass to Terraform
```

**Examples**

```tsx
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
2. Copy the value of `bastion_private_key` from the Terraform state into a new file at `.secure/id_rsa`
3. Run `chmod 600 .secure/id_rsa`
4. Copy the bastion url from `bastion_load_balancer` from the Terraform state.
5. Run `ssh -i .secure/id_rsa ubuntu@<BASTION_LOAD_BALANCER_URL>`

Once you're in the bastion, you should be able to use `kubectl` to interact with the cluster. If it's not configured correctly, run the following commands. Make sure to replace the placeholders.

```tsx
> aws eks --region <AWS_REGION> update-kubeconfig --name <CLUSTER_NAME>
> kubectl config set-context --current --namespace=paragon
```
