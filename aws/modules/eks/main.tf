terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.13.0"
    }
  }
}

# -- IAM roles (unchanged) --
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# -- Security groups for cluster and nodes created by this module --
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster control-plane SG"
  vpc_id      = var.vpc_id
  tags        = var.common_tags

  # Allow EKS-managed node SG (if created) to talk to control plane (we also create a node SG below for in-module rules)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_node_sg" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group used as reference for worker nodes (module-managed)"
  vpc_id      = var.vpc_id
  tags        = var.common_tags

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "node to node communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -- Add rules that allow your web/app/db security groups to communicate to cluster/node SGs --
# Web -> Node: allow HTTP/HTTPS + NodePort range (30000-32767)
resource "aws_security_group_rule" "web_to_node_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = var.web_security_group_id
  description              = "Allow HTTP from web SG to nodes"
}

resource "aws_security_group_rule" "web_to_node_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = var.web_security_group_id
  description              = "Allow HTTPS from web SG to nodes"
}

resource "aws_security_group_rule" "web_to_node_nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = var.web_security_group_id
  description              = "Allow NodePort range from web SG to nodes"
}

# App -> Node: allow app port(s) (default 8080)
resource "aws_security_group_rule" "app_to_node_appport" {
  type                     = "ingress"
  from_port                = var.app_to_node_port
  to_port                  = var.app_to_node_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node_sg.id
  source_security_group_id = var.app_security_group_id
  description              = "Allow app SG to nodes on app port"
}

# If you want the cluster control plane to allow traffic from your web/app SGs (e.g., if you use control-plane proxying)
resource "aws_security_group_rule" "web_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = var.web_security_group_id
  description              = "Allow HTTPS from web SG to cluster control plane"
}

resource "aws_security_group_rule" "app_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = var.app_security_group_id
  description              = "Allow HTTPS from app SG to cluster control plane"
}

# -- EKS Cluster --
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  tags = var.common_tags

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# -- Managed node group --
resource "aws_eks_node_group" "managed_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-managed-${var.node_group_name_suffix}"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.node_subnet_ids

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  ami_type       = var.ami_type

  # SSH access is only configured when a key pair is given
  dynamic "remote_access" {
    for_each = var.ssh_key_name != "" ? [1] : []

    content {
      ec2_ssh_key               = var.ssh_key_name
      source_security_group_ids = var.remote_access_sg_ids
    }
  }

  tags = merge(var.common_tags, {
    "Name" = "${var.cluster_name}-node"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}

# Create OIDC provider for IRSA
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_iam_openid_connect_provider" "maybe" {
  count = 0
  # This data is for conditional checks, keep for reference
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url            = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    # AWS uses the common thumbprint; you can fetch this programmatically in pipelines.
    "9e99a48a9960b14926bb7f3b02e22da0afd1f9d6"
  ]
}