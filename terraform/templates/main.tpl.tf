terraform {
  required_version = "= 1.2.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "__TF_ORGANIZATION__"

    workspaces {
      name = "__TF_WORKSPACE__"
    }
  }
}
