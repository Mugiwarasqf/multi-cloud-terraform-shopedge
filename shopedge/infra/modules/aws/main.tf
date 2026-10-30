

# EKS Cluster + Managed Node Group

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa                    = true
  cluster_endpoint_public_access = true

  # Without this the identity running Terraform gets no Kubernetes permissions,
  # and kubectl and helm are refused after the cluster is created.
  enable_cluster_creator_admin_permissions = true

  #  Managed Node Group
  eks_managed_node_groups = {
    default = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      # Amazon Linux 2 images are not published for Kubernetes 1.33 and later
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "worker"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# ECR Repository

resource "aws_ecr_repository" "app_repo" {
  name                 = "shop-edge"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


# . Outputs

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

