# One state file for the whole ShopEdge platform (EKS, AKS and GKE together)
terraform {
  backend "s3" {
    bucket       = "multicloud-terraform-state-bucket"
    key          = "shopedge/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
