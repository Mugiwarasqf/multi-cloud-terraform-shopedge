#!/bin/bash
# One command for ShopEdge: provision EKS, AKS and GKE with their registries, build
# and push the image, then deploy the Helm chart to all three clusters.
#
#   ./deploy_all.sh                  asks for confirmation before applying
#   AUTO_APPROVE=1 ./deploy_all.sh   no prompt (for CI)
#
# Needs credentials for AWS, Azure and GCP at the same time, plus a
# terraform.tfvars in shopedge/infra (copy terraform.tfvars.example).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../../infra"

tf() { (cd "$INFRA_DIR" && terraform "$@"); }
# Windows CLIs run from Git Bash can end their output with a carriage return
clean() { tr -d '\r'; }

echo "Provisioning clusters and registries..."
tf init -input=false
if [ -n "${AUTO_APPROVE:-}" ]; then
    tf apply -input=false -auto-approve
else
    tf apply
fi

# Registry names and regions come from the Terraform outputs, so they cannot drift
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text | clean)"
AZURE_REGISTRY="$(tf output -raw azure_acr_login_server | clean | cut -d. -f1)"
GCP_PROJECT="$(tf output -raw gcp_project_id | clean)"
AWS_REGION="$(tf output -raw aws_region | clean)"
GCP_REGION="$(tf output -raw gcp_region | clean)"
export AWS_ACCOUNT_ID AZURE_REGISTRY GCP_PROJECT AWS_REGION GCP_REGION

"$SCRIPT_DIR/build_push_all.sh"
"$SCRIPT_DIR/deploy_to_clouds_all.sh"

echo "ShopEdge is deployed to EKS, AKS and GKE."
