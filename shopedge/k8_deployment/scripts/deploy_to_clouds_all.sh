#!/bin/bash

# Set common variables
RELEASE_NAME="shop-edge"
NAMESPACE="shop-edge"

# Function to deploy to EKS
deploy_eks() {
    echo "Deploying to EKS..."
    aws eks update-kubeconfig --region us-east-1 --name your-eks-cluster
    
    # Create namespace if not exists
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with Helm
    helm upgrade --install $RELEASE_NAME ./shopedge-chart \
        --namespace $NAMESPACE \
        --set image.repository=$ECR_REPO \
        --set image.tag=$VERSION
}

# Function to deploy to AKS
deploy_aks() {
    echo "Deploying to AKS..."
    az aks get-credentials --resource-group your-rg --name your-aks-cluster
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install $RELEASE_NAME ./shopedge-chart \
        --namespace $NAMESPACE \
        --set image.repository=$AZURE_REPO \
        --set image.tag=$VERSION
}

# Function to deploy to GKE
deploy_gke() {
    echo "Deploying to GKE..."
    gcloud container clusters get-credentials your-gke-cluster --region us-central1
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install $RELEASE_NAME ./shopedge-chart \
        --namespace $NAMESPACE \
        --set image.repository=$GCP_REPO \
        --set image.tag=$VERSION
}

# Deploy to all clouds
deploy_eks
deploy_aks
deploy_gke

echo "Deployment completed to all cloud platforms!"