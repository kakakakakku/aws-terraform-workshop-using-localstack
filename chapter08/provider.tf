terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.56.0"
    }
  }
  required_version = "~> 1.10.0"
}

provider "aws" {
  region = "us-east-1"
}
