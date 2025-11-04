#!/bin/bash

# Azure Deployment Script for Jenkins
# Deploys Jenkins with Python 3.11 and Azure CLI for Research Report Generation CI/CD

set -e

# Configuration
RESOURCE_GROUP="research-report-jenkins-rg"
LOCATION="eastasia"   # Use eastasia only for Azure for Students
STORAGE_ACCOUNT="reportjenkinsstore$(openssl rand -hex 3)"   # unique name
FILE_SHARE="jenkins-data"
ACR_NAME="reportjenkinsacr$(openssl rand -hex 2)"   # unique name
CONTAINER_NAME="jenkins-research-report"
DNS_NAME_LABEL="jenkins-research-$(date +%s | tail -c 6)"
JENKINS_IMAGE_NAME="custom-jenkins"
JENKINS_IMAGE_TAG="lts-git-configured"

# Subscription ID (pass as 1st argument or set AZURE_SUBSCRIPTION_ID env)
SUBSCRIPTION_ID="${1:-${AZURE_SUBSCRIPTION_ID}}"

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deploying Jenkins for Research Report Generation     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Verify Azure login
echo "🔐 Verifying Azure login..."
if ! az account show &>/dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo "📋 Setting Azure subscription to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
else
    echo "ℹ️  No subscription ID provided. Using current default subscription."
    CURRENT_SUB=$(az account show --query id -o tsv)
    echo "   Current subscription: $CURRENT_SUB"
    SUBSCRIPTION_ID="$CURRENT_SUB"
fi

echo "✅ Using subscription: $SUBSCRIPTION_ID"
echo ""

# Check if resource group exists and skip recreation if it does
if az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "📦 Resource Group '$RESOURCE_GROUP' already exists. Skipping creation."
else
    echo "📦 Creating Resource Group: $RESOURCE_GROUP in $LOCATION..."
    az group create --name $RESOURCE_GROUP --location $LOCATION --subscription "$SUBSCRIPTION_ID"
fi

# Create Storage Account (unique name each run)
echo "💾 Creating Storage Account: $STORAGE_ACCOUNT..."
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --subscription "$SUBSCRIPTION_ID"

# Get Storage Account Key
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --subscription "$SUBSCRIPTION_ID" \
  --query '[0].value' -o tsv)

# Create File Share
echo "📁 Creating File Share: $FILE_SHARE..."
az storage share create \
  --name $FILE_SHARE \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --subscription "$SUBSCRIPTION_ID"

# Create ACR (unique name)
echo "🐳 Creating Container Registry: $ACR_NAME..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true \
  --subscription "$SUBSCRIPTION_ID"

# Login to ACR
echo "🔐 Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

# Build custom Jenkins image
echo "🔨 Building custom Jenkins Docker image for Linux AMD64..."
docker build --platform linux/amd64 -f Dockerfile.jenkins -t ${ACR_NAME}.azurecr.io/${JENKINS_IMAGE_NAME}:${JENKINS_IMAGE_TAG} .

# Push Jenkins image to ACR
echo "📤 Pushing Jenkins image to ACR..."
docker push ${ACR_NAME}.azurecr.io/${JENKINS_IMAGE_NAME}:${JENKINS_IMAGE_TAG}

# Get ACR credentials
echo "🔑 Retrieving ACR credentials..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --subscription "$SUBSCRIPTION_ID" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --subscription "$SUBSCRIPTION_ID" --query passwords[0].value -o tsv)

# Deploy Jenkins Container using custom image
echo "🚀 Deploying Jenkins Container..."
az container create \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_NAME \
  --image ${ACR_NAME}.azurecr.io/${JENKINS_IMAGE_NAME}:${JENKINS_IMAGE_TAG} \
  --registry-login-server ${ACR_NAME}.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --os-type Linux \
  --dns-name-label $DNS_NAME_LABEL \
  --ports 8080 \
  --cpu 2 \
  --memory 4 \
  --azure-file-volume-account-name $STORAGE_ACCOUNT \
  --azure-file-volume-account-key $STORAGE_KEY \
  --azure-file-volume-share-name $FILE_SHARE \
  --azure-file-volume-mount-path /var/jenkins_home \
  --environment-variables JAVA_OPTS="-Djenkins.install.runSetupWizard=true" \
  --subscription "$SUBSCRIPTION_ID"

# Wait for deployment
echo "⏳ Waiting for Jenkins to deploy..."
sleep 10

# Get Jenkins URL
JENKINS_URL=$(az container show \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_NAME \
  --subscription "$SUBSCRIPTION_ID" \
  --query ipAddress.fqdn -o tsv)

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║           Deployment Complete!                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Jenkins URL: http://$JENKINS_URL:8080"
echo ""
echo "⏳ Wait 2–3 minutes for Jenkins to fully start, then run:"
echo ""
echo "az container exec \\"
echo "  --resource-group $RESOURCE_GROUP \\"
echo "  --name $CONTAINER_NAME \\"
echo "  --exec-command 'cat /var/jenkins_home/secrets/initialAdminPassword'"
echo ""
