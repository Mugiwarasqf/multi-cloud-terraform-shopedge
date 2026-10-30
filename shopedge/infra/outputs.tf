# AWS
output "aws_region" {
  description = "AWS region of the EKS cluster and ECR repository"
  value       = var.aws_region
}

output "aws_cluster_name" {
  value = module.aws.cluster_name
}

output "aws_cluster_endpoint" {
  value = module.aws.cluster_endpoint
}

output "aws_ecr_repo_url" {
  value = module.aws.ecr_repo_url
}

# Azure
output "azure_cluster_name" {
  value = module.azure.cluster_name
}

output "azure_cluster_fqdn" {
  value = module.azure.cluster_fqdn
}

output "azure_acr_login_server" {
  value = module.azure.acr_login_server
}

# GCP
output "gcp_project_id" {
  value = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP region of the GKE cluster and Artifact Registry repository"
  value       = var.gcp_region
}

output "gcp_cluster_name" {
  value = module.gcp.cluster_name
}

output "gcp_cluster_endpoint" {
  value = module.gcp.cluster_endpoint
}

output "gcp_artifact_registry_repo" {
  value = module.gcp.artifact_registry_repo
}
