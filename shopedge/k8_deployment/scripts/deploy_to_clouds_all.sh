#!/bin/bash
# Deploy the ShopEdge Helm chart to EKS, AKS and GKE.
# Run build_push_all.sh first, with the same environment variables set.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$SCRIPT_DIR/../helm-charts/shopedge"

RELEASE_NAME="shop-edge"
NAMESPACE="shop-edge"
APP_NAME="shop-edge"
VERSION="${VERSION:-1.0.0}"

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
: "${AZURE_REGISTRY:?Set AZURE_REGISTRY}"
: "${GCP_PROJECT:?Set GCP_PROJECT}"
AWS_REGION="${AWS_REGION:-us-east-1}"
GCP_REGION="${GCP_REGION:-us-central1}"

ECR_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME"
AZURE_REPO="$AZURE_REGISTRY.azurecr.io/$APP_NAME"
GCP_REPO="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$APP_NAME/$APP_NAME"

# Cluster names match shopedge/infra
EKS_CLUSTER="shopedge-cluster"
AKS_CLUSTER="shopedge-aks"
AKS_RESOURCE_GROUP="shopedge-rg"
GKE_CLUSTER="shopedge-cluster"

helm_deploy() {
    local repo="$1"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
        --namespace "$NAMESPACE" \
        --set image.repository="$repo" \
        --set image.tag="$VERSION"
}

deploy_eks() {
    echo "Deploying to EKS..."
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER"
    helm_deploy "$ECR_REPO"
}

deploy_aks() {
    echo "Deploying to AKS..."
    az aks get-credentials --resource-group "$AKS_RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing
    helm_deploy "$AZURE_REPO"
}

deploy_gke() {
    echo "Deploying to GKE..."
    gcloud container clusters get-credentials "$GKE_CLUSTER" --region "$GCP_REGION" --project "$GCP_PROJECT"
    helm_deploy "$GCP_REPO"
}

deploy_eks
deploy_aks
deploy_gke

echo "Deployment completed to all cloud platforms!"
