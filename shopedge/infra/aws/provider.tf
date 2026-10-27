
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40" # Compatible with latest EKS module
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change to your preferred AWS region
}