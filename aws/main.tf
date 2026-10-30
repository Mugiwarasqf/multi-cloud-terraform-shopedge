locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  # Amazon Linux 2023 (Amazon Linux 2 is past end of life)
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Network Module
module "network" {
  source = "./modules/network"

  project_name          = var.project_name
  common_tags           = local.common_tags
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = data.aws_availability_zones.available.names
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  common_tags  = local.common_tags
  vpc_id       = module.network.vpc_id
  vpc_cidr     = module.network.vpc_cidr_block
}

# Database Module
module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  common_tags                = local.common_tags
  database_subnet_ids        = module.network.database_subnet_ids
  database_security_group_id = module.security.database_security_group_id
  db_engine                  = var.db_engine
  db_engine_version          = var.db_engine_version
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  db_backup_retention_period = var.db_backup_retention_period
  db_backup_window           = var.db_backup_window
  db_maintenance_window      = var.db_maintenance_window
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  common_tags           = local.common_tags
  ami_id                = data.aws_ami.amazon_linux.id
  web_instance_type     = var.web_instance_type
  app_instance_type     = var.app_instance_type
  web_instance_count    = var.web_instance_count
  app_instance_count    = var.app_instance_count
  key_pair_name         = var.key_pair_name
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  web_security_group_id = module.security.web_security_group_id
  app_security_group_id = module.security.app_security_group_id
  database_endpoint     = module.database.database_endpoint
}

# Container layer: off by default so a plain apply builds only the 3-tier stack.
# Set enable_containers = true to also provision ECR, ECS and EKS.
module "ecr" {
  count  = var.enable_containers ? 1 : 0
  source = "./modules/ecr"
}

# ECS Module
module "ecs" {
  count           = var.enable_containers ? 1 : 0
  source          = "./modules/ecs"
  app_image       = var.app_image
  app_port        = var.app_port
  vpc_id          = module.network.vpc_id
  subnets         = module.network.public_subnet_ids
  security_groups = [module.security.web_security_group_id]
}

module "eks" {
  count  = var.enable_containers ? 1 : 0
  source = "./modules/eks"

  cluster_name = "${var.project_name}-eks"
  vpc_id       = module.network.vpc_id
  subnets      = module.network.private_subnet_ids

  # control plane and node subnets (private recommended)
  subnet_ids      = module.network.private_subnet_ids
  node_subnet_ids = module.network.private_subnet_ids

  # node sizing
  instance_types        = ["t3.medium"]
  node_desired_capacity = 2
  node_min_size         = 1
  node_max_size         = 3

  ssh_key_name       = var.key_pair_name
  kubernetes_version = var.eks_kubernetes_version
  common_tags        = local.common_tags

  # pass security group ids from the security module using the names you already used
  web_security_group_id      = module.security.web_security_group_id
  app_security_group_id      = module.security.app_security_group_id
  database_security_group_id = module.security.database_security_group_id

  # optionally tune the port used for app->node comms
  app_to_node_port = 8080

  # Required attributes
  node_group_name_suffix  = "workers"
  endpoint_public_access  = false
  endpoint_private_access = true
  remote_access_sg_ids    = [module.security.app_security_group_id]
  ami_type                = "AL2023_x86_64_STANDARD"
  capacity_type           = "ON_DEMAND"
}
