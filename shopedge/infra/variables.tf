# AWS
variable "aws_region" {
  description = "AWS region. deploy_all.sh passes it on to the build and deploy scripts."
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster; list supported versions with: aws eks describe-cluster-versions"
  type        = string
  default     = "1.36"
}

# Azure
variable "azure_subscription_id" {
  description = "Azure subscription ID. Leave null to use ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "azure_node_vm_size" {
  description = "VM size for the AKS node pool. Pick one your subscription has quota for in the chosen region."
  type        = string
  default     = "Standard_DS2_v2"
}

# GCP
variable "gcp_project_id" {
  description = "GCP project ID (no default: set it in terraform.tfvars or TF_VAR_gcp_project_id)"
  type        = string
}

variable "gcp_region" {
  description = "GCP region. deploy_all.sh passes it on to the build and deploy scripts."
  type        = string
  default     = "us-central1"
}
