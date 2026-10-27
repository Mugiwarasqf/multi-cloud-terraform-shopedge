
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30" # Stable version for GKE
    }
  }
}

provider "google" {
  project = var.project_id    # Pass project_id from variables.tf or TF_VAR_project_id
  region  = var.region        # e.g. "us-central1"
}