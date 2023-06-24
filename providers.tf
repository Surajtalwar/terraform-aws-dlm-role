provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source = "registry.terraform.io/hashicorp/aws"
      version = "5.3.0"
    }
  }
  required_version = "1.4.6"
}