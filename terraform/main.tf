terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.46"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "daan-se-tf-state"
    key = "default"
    region = "eu-central-1"
  }
}

locals {
  default-tags = {
    application: "daan-se"
  }
}
