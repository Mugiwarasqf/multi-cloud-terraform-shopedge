terraform {
  backend "s3" {
    bucket       = "multicloud-terraform-state-bucket"
    key          = "gcp/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
