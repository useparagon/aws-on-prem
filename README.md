# Paragon - AWS Self-hosted Example

## Overview

This repo is used to demonstrate running Paragon on your own infrastructure. It's separated into two Terraform workspaces:

**terraform/workspaces/infra**

This workspace provisions the required infrastructure needed to run Paragon on AWS. It consists of the following modules and resources:

network

- VPC
- public and private subnets
- elastic IP addresses
- internet gateway
- nat gateway
- routing tables

redis

- ElastiCache cluster
- ElastiCache parameter group

postgres

- RDS instance
- RDS parameter group

s3

- public s3 bucket
- private s3 bucket
- IAM user
- IAM user policy

cluster

- EKS cluster
- node groups

bastion

- private key
- key pair
- EC2 autoscaling group
- load balancer

**terraform/workspaces/paragon**

This workspace deploys the Paragon helm chart to the kubernetes cluster along with an application load balancer.

helm

- kubernetes secret (docker login to pull images)
- helm release (paragon helm chart)
- helm release (alb ingress controller)

alb

- ACM certificate
- ACM certificate validation
- Route53 records

## Deploying Paragon

Using the `terraform/workspaces/infra` module is optional.

## Connecting to the Bastion

To debug the Kubernetes cluster, the `infra` workspace provisions a bastion that you can SSH into. After successfully provisioning the workspace:

1. Run `make --silent state-infra`
2. Copy the value of `bastion_private_key` from the Terraform state into a new file at `.secure/id_rsa`
3. Run `chmod 600 .secure/id_rsa`
4. Copy the bastion url from `bastion_load_balancer` from the Terraform state.
5. Run `ssh -i .secure/id_rsa ubuntu@<BASTION_LOAD_BALANCER_URL>

Once you're in the bastion, you should be able to use `kubectl` to interact with the cluster. If it's not provisioned correctly, run the following commands. Make sure to replace the placeholders.

> aws eks --region <AWS_REGION> update-kubeconfig --name <CLUSTER_NAME>
> kubectl config set-context --current --namespace=paragon
