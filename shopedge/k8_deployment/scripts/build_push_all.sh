#!/bin/bash

# Set variables
APP_NAME="shop-edge"
VERSION="1.0.0"
REGISTRIES=("aws" "azure" "gcp")

# AWS ECR Configuration
AWS_ACCOUNT_ID="565393029077"
AWS_REGION="us-east-1"
ECR_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME"

Azure ACR Configuration
AZURE_REGISTRY="shopedge"
AZURE_REPO="$AZURE_REGISTRY.azurecr.io/$APP_NAME"

GCP Artifact Registry Configuration
GCP_PROJECT="striking-water-472711-g2"
GCP_REGION="us-central1"
GCP_REPO="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$APP_NAME/$APP_NAME"

# Build the image
echo "Building Docker image..."
docker build -t $APP_NAME:$VERSION .

# Tag and push to AWS ECR
echo "Pushing to AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
docker tag $APP_NAME:$VERSION $ECR_REPO:$VERSION
docker push $ECR_REPO:$VERSION

# Tag and push to Azure ACR
echo "Pushing to Azure ACR..."
az acr login --name $AZURE_REGISTRY
docker tag $APP_NAME:$VERSION $AZURE_REPO:$VERSION
docker push $AZURE_REPO:$VERSION

# # Tag and push to GCP Artifact Registry
echo "Pushing to GCP Artifact Registry..."
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev
docker tag $APP_NAME:$VERSION $GCP_REPO:$VERSION
docker push $GCP_REPO:$VERSION

echo "Images pushed to all aws registries!"