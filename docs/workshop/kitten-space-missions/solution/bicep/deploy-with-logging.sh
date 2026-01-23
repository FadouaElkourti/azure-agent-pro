#!/bin/bash
# Enhanced deployment script with detailed error logging
# Usage: ./deploy-with-logging.sh [resource-group-name]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="${1:-rg-kitten-missions-dev}"
DEPLOYMENT_NAME="deploy-$(date +%s)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Azure Bicep Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Resource Group: ${RESOURCE_GROUP}"
echo "Deployment Name: ${DEPLOYMENT_NAME}"
echo "Working Directory: ${SCRIPT_DIR}"
echo ""

# Step 1: Validate template
echo -e "${BLUE}📋 Step 1: Validating Bicep template...${NC}"
if az deployment group validate \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${SCRIPT_DIR}/main.bicep" \
  --parameters "${SCRIPT_DIR}/parameters/dev.parameters.json" \
  --output none 2>/dev/null; then
  echo -e "${GREEN}✅ Template validation passed${NC}"
else
  echo -e "${RED}❌ Template validation failed${NC}"
  echo ""
  echo "Run the following for details:"
  echo "  az deployment group validate \\"
  echo "    --resource-group ${RESOURCE_GROUP} \\"
  echo "    --template-file main.bicep \\"
  echo "    --parameters parameters/dev.parameters.json"
  exit 1
fi
echo ""

# Step 2: Deploy infrastructure
echo -e "${BLUE}🏗️  Step 2: Deploying infrastructure to Azure...${NC}"
echo ""

if DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${SCRIPT_DIR}/main.bicep" \
  --parameters "${SCRIPT_DIR}/parameters/dev.parameters.json" \
  --name "${DEPLOYMENT_NAME}" \
  --mode Incremental \
  --output json 2>&1); then
  
  echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
  echo ""
  
  # Extract and display outputs
  echo -e "${BLUE}📦 Deployment Outputs:${NC}"
  echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs | to_entries[] | "  \(.key): \(.value.value)"' 2>/dev/null || echo "  (outputs not available)"
  echo ""
  
else
  echo -e "${RED}❌ Deployment failed!${NC}"
  echo ""
  echo -e "${YELLOW}🔍 Fetching detailed error information...${NC}"
  echo ""
  
  # Get last deployment name
  LAST_DEPLOYMENT=$(az deployment group list \
    --resource-group "${RESOURCE_GROUP}" \
    --query "[0].name" -o tsv 2>/dev/null)
  
  if [ -n "$LAST_DEPLOYMENT" ]; then
    echo -e "${YELLOW}Failed deployment: ${LAST_DEPLOYMENT}${NC}"
    echo ""
    
    # Get failed operations
    echo -e "${RED}Failed Operations:${NC}"
    az deployment operation group list \
      --resource-group "${RESOURCE_GROUP}" \
      --name "$LAST_DEPLOYMENT" \
      --query "[?properties.provisioningState=='Failed'].{Resource:properties.targetResource.resourceType, Name:properties.targetResource.resourceName, StatusCode:properties.statusCode, Error:properties.statusMessage.error.message}" \
      --output table 2>/dev/null || echo "Could not retrieve operation details"
    echo ""
    
    # Show full deployment status
    echo -e "${YELLOW}Full Deployment Status:${NC}"
    az deployment group show \
      --resource-group "${RESOURCE_GROUP}" \
      --name "$LAST_DEPLOYMENT" \
      --query "{State:properties.provisioningState, Duration:properties.duration, Timestamp:properties.timestamp, CorrelationId:properties.correlationId}" \
      --output table 2>/dev/null || echo "Could not retrieve deployment status"
    echo ""
    
    # Provide troubleshooting commands
    echo -e "${BLUE}💡 Troubleshooting Commands:${NC}"
    echo ""
    echo "View all operations for this deployment:"
    echo "  az deployment operation group list \\"
    echo "    --resource-group ${RESOURCE_GROUP} \\"
    echo "    --name ${LAST_DEPLOYMENT}"
    echo ""
    echo "View deployment details:"
    echo "  az deployment group show \\"
    echo "    --resource-group ${RESOURCE_GROUP} \\"
    echo "    --name ${LAST_DEPLOYMENT}"
    echo ""
  fi
  
  exit 1
fi

# Step 3: Post-deployment summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "View deployment in Azure Portal:"
echo -e "  https://portal.azure.com/#blade/HubsExtension/DeploymentDetailsBlade/id/%2Fsubscriptions%2F$(az account show --query id -o tsv)%2FresourceGroups%2F${RESOURCE_GROUP}%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F${DEPLOYMENT_NAME}"
echo ""

exit 0
