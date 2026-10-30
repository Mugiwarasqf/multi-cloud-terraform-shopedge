# Multi-Cloud Terraform + ShopEdge

[![validate](https://github.com/Mugiwarasqf/multi-cloud-terraform-shopedge/actions/workflows/validate.yml/badge.svg)](https://github.com/Mugiwarasqf/multi-cloud-terraform-shopedge/actions/workflows/validate.yml)

Modular Terraform that builds the same 3-tier architecture (network, compute, database) on AWS, Azure and GCP, plus a managed Kubernetes cluster and container registry on each. **ShopEdge**, a containerised web app, is deployed to all three clusters with one Helm chart.

> **Status:** not currently deployed; the stack was torn down to avoid running costs. CI validates the Terraform and the Helm chart. The deploy scripts have not been run end to end.

Architecture diagram: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Highlights

- One module layout (network, security, compute, database) used on all three clouds
- Public web, private app and private database subnets
- EKS, AKS and GKE, each with its own registry (ECR, ACR, Artifact Registry)
- One image and one Helm chart deployed unchanged to all three clusters
- Pod autoscaling (HPA, 2 to 10 replicas) and GKE node-pool autoscaling
- Remote state in S3 with locking, created by a bootstrap configuration
- CI runs format, validate and lint checks on every push

## Architecture

| Layer | AWS | Azure | GCP |
|---|---|---|---|
| Network | VPC, subnets, NAT gateway per AZ | VNet, subnets, NAT gateway | VPC, subnets, Cloud NAT |
| Security | Security groups | NSGs | Firewall rules |
| Compute | EC2 (Amazon Linux 2023) | Virtual machines (Ubuntu 22.04) | Compute Engine (Debian 12) |
| Database | RDS (MySQL 8.4) | Azure Database for MySQL Flexible Server | Cloud SQL (MySQL) |
| Kubernetes | EKS | AKS | GKE |
| Registry | ECR | ACR | Artifact Registry |

The 3-tier stacks and ShopEdge are independent: ShopEdge's clusters have their own networks and are not connected to the 3-tier networks or databases. Deploy either or both.

## Repository structure

```
├── bootstrap/            # Creates the S3 bucket that holds Terraform state
├── aws/ azure/ gcp/      # 3-tier infrastructure, one folder per cloud
├── shopedge/
│   ├── infra/            # EKS, AKS and GKE with registries: one root, modules per cloud, one state file
│   └── k8_deployment/
│       ├── app/          # Dockerfile, nginx config, static page
│       ├── helm-charts/  # ShopEdge Helm chart
│       └── scripts/      # deploy_all.sh, build_push_all.sh, deploy_to_clouds_all.sh
├── .github/workflows/    # CI checks
└── docs/                 # Architecture, remote state setup, module reference
```

Each cloud folder contains `main.tf`, `providers.tf`, `backend.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example` and `modules/`. Provider lock files are committed. `aws/` can also create its own ECR, ECS and EKS (`enable_containers`, off by default); ShopEdge does not use them. See [docs/MODULES.md](docs/MODULES.md).

## Prerequisites

- Terraform >= 1.11
- AWS CLI, Azure CLI and Google Cloud SDK, authenticated. State is stored in AWS, so AWS credentials are needed for every stack.
- Docker, `kubectl` and Helm 3
- GCP: enable the Service Usage and Cloud Resource Manager APIs once, so Terraform can enable the rest:
  `gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com --project <project-id>`

## Getting started

**1. Create the state bucket** (once per AWS account). See [docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md).

```bash
cd bootstrap
terraform init
terraform apply
```

**2. Deploy ShopEdge with one command.** This provisions EKS, AKS and GKE with their registries, builds and pushes the image, and deploys the Helm chart to all three clusters.

```bash
cd shopedge/infra
cp terraform.tfvars.example terraform.tfvars   # set gcp_project_id and azure_subscription_id
cd ../k8_deployment/scripts
./deploy_all.sh                                # AUTO_APPROVE=1 skips the confirmation prompt
```

The three clouds share one Terraform configuration and one state file, so credentials for all three must be available together: `aws configure`, `az login` and `gcloud auth application-default login`. To build one cloud only, run `terraform apply -target=module.aws` (or `azure`, `gcp`) in `shopedge/infra`.

| Setting | Default |
|---|---|
| `gcp_project_id` | required |
| `azure_subscription_id` | `ARM_SUBSCRIPTION_ID` if unset |
| `eks_cluster_version` | `1.36` (`aws eks describe-cluster-versions` lists supported versions) |
| `aws_region`, `azure_location`, `gcp_region` | `us-east-1`, `East US`, `us-central1` |
| `azure_node_vm_size` | `Standard_DS2_v2` (needs quota in your subscription) |

To run the stages separately, apply Terraform, then export `AWS_ACCOUNT_ID`, `AZURE_REGISTRY` (the `azure_acr_login_server` output without `.azurecr.io`) and `GCP_PROJECT`, and run `build_push_all.sh` followed by `deploy_to_clouds_all.sh`.

No ingress controller is installed, so reach the app through a port-forward on whichever cluster your `kubectl` context points to:

```bash
kubectl -n shop-edge port-forward svc/shop-edge-shopedge 8080:80
```

**3. Deploy the 3-tier infrastructure** (optional, independent of ShopEdge).

```bash
cd aws                                         # or azure / gcp
cp terraform.tfvars.example terraform.tfvars   # fill in the values below
terraform init
terraform apply
```

- AWS: `db_password`
- Azure: `admin_password`, and a subscription via `az login` plus `subscription_id`, or the `ARM_*` service principal variables. Terraform creates the resource group unless `resource_group_name` names an existing one.
- GCP: `gcp_project_id`

**4. Tear down** to avoid charges:

```bash
terraform -chdir=shopedge/infra destroy   # EKS, AKS, GKE and the registries
terraform destroy                         # in aws/, azure/ or gcp/, whichever you applied
```

The state bucket is protected with `prevent_destroy`; see [docs/BACKEND_SETUP.md](docs/BACKEND_SETUP.md) to remove it.

## Security

- Databases are private: RDS is not publicly accessible and sits in subnets with no default route, Azure MySQL uses a delegated subnet with a private DNS zone, and Cloud SQL has no public IP.
- AWS tiers are chained by security group: the internet reaches web on 80/443, web reaches app on 8080, app reaches the database on 3306. SSH is allowed only from inside the VPC.
- RDS storage is encrypted. The state bucket is versioned and encrypted, blocks public access and requires TLS.
- AKS pulls images from ACR with a managed identity (`AcrPull`); ACR admin credentials are disabled. ECR scans images on push.
- Secrets have no defaults in code. Real values go in `terraform.tfvars` (git-ignored) or environment variables; Azure also accepts `ARM_*` variables and `az login`.

## Known limitations

- Azure: the NSGs contain only allow rules, so Azure's default rule allowing traffic inside the VNet still applies and app-to-database isolation is not enforced.
- GCP: the database firewall rule targets a network tag that no resource carries, so it matches nothing. The database is protected by having no public IP.
- AWS: the app-tier `user_data` only writes log lines; nothing listens on port 8080.
- Azure MySQL (8.0.21) and Cloud SQL (`MYSQL_8_0`) still use MySQL 8.0; the AWS stack uses 8.4.
- EKS and AKS node counts are fixed; no cluster autoscaler is installed.
- The chart's ingress needs ingress-nginx and cert-manager, and the HPA needs metrics-server on EKS (AKS and GKE include it). None of these is installed by this repository.

## Roadmap

- Deploy pipeline using OIDC, with a plan on pull requests and an approval before apply
- Install ingress-nginx, cert-manager and metrics-server with Terraform or Helm
- Close the Azure and GCP isolation gaps
