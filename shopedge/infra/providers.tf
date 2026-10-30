terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40" # Compatible with the terraform-aws-modules EKS and VPC modules
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30" # Stable version for GKE
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# All three providers are configured on every run, so credentials for AWS, Azure
# and GCP must all be available: `aws configure`, `az login` and
# `gcloud auth application-default login` (or the matching environment variables).
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
