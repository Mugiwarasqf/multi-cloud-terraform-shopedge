terraform {
  backend "s3" {
    bucket       = "multicloud-terraform-state-bucket"
    key          = "azure/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
