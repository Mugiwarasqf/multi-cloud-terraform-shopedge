#!/bin/bash
# Build the ShopEdge image once and push it to ECR, ACR and Artifact Registry.
# Usage: AWS_ACCOUNT_ID=... AZURE_REGISTRY=... GCP_PROJECT=... ./build_push_all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

APP_NAME="shop-edge"
VERSION="${VERSION:-1.0.0}"

# AWS ECR (registry created by shopedge/infra, module aws)
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME"

# Azure ACR (use the azure_acr_login_server output from shopedge/infra, without .azurecr.io)
: "${AZURE_REGISTRY:?Set AZURE_REGISTRY, e.g. shopedgeacrab12c}"
AZURE_REPO="$AZURE_REGISTRY.azurecr.io/$APP_NAME"

# GCP Artifact Registry (repository created by shopedge/infra, module gcp)
: "${GCP_PROJECT:?Set GCP_PROJECT}"
GCP_REGION="${GCP_REGION:-us-central1}"
GCP_REPO="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$APP_NAME/$APP_NAME"

echo "Building Docker image..."
docker build -t "$APP_NAME:$VERSION" "$APP_DIR"

echo "Pushing to AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${ECR_REPO%%/*}"
docker tag "$APP_NAME:$VERSION" "$ECR_REPO:$VERSION"
docker push "$ECR_REPO:$VERSION"

echo "Pushing to Azure ACR..."
az acr login --name "$AZURE_REGISTRY"
docker tag "$APP_NAME:$VERSION" "$AZURE_REPO:$VERSION"
docker push "$AZURE_REPO:$VERSION"

echo "Pushing to GCP Artifact Registry..."
gcloud auth configure-docker "$GCP_REGION-docker.pkg.dev" --quiet
docker tag "$APP_NAME:$VERSION" "$GCP_REPO:$VERSION"
docker push "$GCP_REPO:$VERSION"

echo "Images pushed to ECR, ACR and Artifact Registry."
