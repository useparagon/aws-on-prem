# Paragon - AWS Self-hosted Example

### Overview

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
