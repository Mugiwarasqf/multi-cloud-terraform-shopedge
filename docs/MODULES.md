# Terraform Modules

This document lists what each module in the `aws/`, `azure/` and `gcp/` folders creates. Inputs and outputs are defined in each module's `variables.tf` and `outputs.tf`.

## Module structure

Each provider folder follows the same layout:

```
<provider>/
├── modules/
│   ├── network/     # Networks, subnets, routing, NAT
│   ├── security/    # Security groups, NSGs, firewall rules
│   ├── compute/     # Web and app tier instances
│   └── database/    # Managed MySQL
├── main.tf          # Root module: wires the modules together
├── providers.tf
├── backend.tf       # Remote state (S3, lockfile locking)
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

`aws/modules/` also has `ecr`, `ecs` and `eks`; see [AWS container modules](#aws-container-modules-optional).

## Network

| | Resources |
|---|---|
| AWS | VPC, internet gateway, public / private / database subnets (one per CIDR given), one Elastic IP and NAT gateway per public subnet, route tables and associations |
| Azure | Virtual network, public / private / database subnets, NAT gateway with a public IP, private route table |
| GCP | VPC network, public / private / database subnets, Cloud Router and Cloud NAT, private services access (global address and service networking connection) for Cloud SQL |

## Security

| | Resources |
|---|---|
| AWS | Three security groups: web, app, database |
| Azure | Three network security groups (web, app, database), associated with their subnets |
| GCP | Firewall rules: HTTP/HTTPS to web, SSH from the VPC, web to app on 8080, app to database on 3306, health checks, and a low-priority deny-all |

## Compute

| | Resources |
|---|---|
| AWS | EC2 instances (Amazon Linux 2023) for the web and app tiers (`aws_instance`, counts set by variables) |
| Azure | Linux virtual machines (Ubuntu 22.04) for the web and app tiers, with network interfaces; web VMs get public IPs |
| GCP | Instance templates for the web and app tiers, and instances created from them |

## Database

| | Resources |
|---|---|
| AWS | RDS instance (MySQL by default), DB subnet group, parameter group, enhanced-monitoring IAM role |
| Azure | MySQL Flexible Server in a delegated subnet, database, server configuration, private DNS zone and VNet link |
| GCP | Cloud SQL (MySQL) instance with private IP only, database and user |

The Azure and GCP database passwords are generated with `random_password` in the root module. The AWS password comes from `db_password`.

## AWS container modules (optional)

Switched on with `enable_containers = true` (default `false`):

| Module | Resources |
|---|---|
| `ecr` | ECR repository `shopedge` with scan on push, and a lifecycle policy for untagged images |
| `ecs` | ECS cluster, Fargate task definition and service (runs `app_image`, default `nginx:latest`), task execution role |
| `eks` | EKS cluster and managed node group, IAM roles, security groups and rules, OIDC provider |

ShopEdge does not use these. It has its own ECR repository and EKS cluster in `shopedge/infra/modules/aws`.

## Module usage

Each root module calls its modules with explicit inputs. For example, from `aws/main.tf`:

```hcl
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
```
