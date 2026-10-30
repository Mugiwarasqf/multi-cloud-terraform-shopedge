variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "multi-cloud-terraform"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}


# Compute Variables
variable "web_instance_type" {
  description = "Instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for app tier"
  type        = string
  default     = "t3.small"
}

variable "web_instance_count" {
  description = "Number of web tier instances"
  type        = number
  default     = 2
}

variable "app_instance_count" {
  description = "Number of app tier instances"
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "app_image" {
  description = "The Docker image for the application."
  type        = string
  default     = "nginx:latest"
}

variable "app_port" {
  description = "The port the application listens on."
  type        = number
  default     = 80
}

# Database Variables
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version (MySQL 8.0 left RDS standard support on 2026-07-31)"
  type        = string
  default     = "8.4"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password (no default: set it in terraform.tfvars or TF_VAR_db_password)"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "Database backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Database backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Database maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enable_containers" {
  description = "Also provision ECR, ECS and EKS in the AWS root (ShopEdge has its own EKS in shopedge/infra/modules/aws)"
  type        = bool
  default     = false
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the optional EKS cluster; list supported versions with: aws eks describe-cluster-versions"
  type        = string
  default     = "1.36"
}
