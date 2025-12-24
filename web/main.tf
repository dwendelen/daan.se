# terraform plan --var-file=secret.tfvars

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.100"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "eu-central-1"
}

provider "aws" {
  alias = "us-east-1"
  profile = "default"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "daan-se-tf-state"
    key = "web"
    region = "eu-central-1"
  }
}

locals {
  default-tags = {
    application: "daan-se"
  }
  zone-id = "Z03939243KT7G9JBEYEX5"
}
