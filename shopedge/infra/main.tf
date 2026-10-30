module "aws" {
  source = "./modules/aws"

  cluster_version = var.eks_cluster_version
}

module "azure" {
  source = "./modules/azure"

  location     = var.azure_location
  node_vm_size = var.azure_node_vm_size
}

module "gcp" {
  source = "./modules/gcp"

  region = var.gcp_region
}
