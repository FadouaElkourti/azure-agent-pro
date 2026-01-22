#!/bin/bash
#
# Script: configure-budget-alert.sh
# Purpose: Configure Azure Budget Alert with email notifications
# Author: Azure Architect Pro
# Date: 2026-01-22
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUBSCRIPTION_ID="d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"
BUDGET_NAME="kitten-missions-dev-budget"
AMOUNT=100
EMAIL="faduaelkourti@gmail.com"
RESOURCE_GROUP="rg-kitten-missions-dev"
TEMPLATE_FILE="$(dirname "$0")/budget-alert.json"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Azure Budget Alert Configuration${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if logged in
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo -e "${YELLOW}Please run: az login${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Azure login verified${NC}"
echo ""

# Set correct subscription
echo -e "${YELLOW}Setting subscription...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"
CURRENT_SUB=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Using subscription: $CURRENT_SUB${NC}"
echo ""

# Check if budget already exists
echo -e "${YELLOW}Checking for existing budget...${NC}"
EXISTING_BUDGET=$(az consumption budget list \
    --subscription "$SUBSCRIPTION_ID" \
    --query "[?name=='$BUDGET_NAME'].name" -o tsv 2>/dev/null || echo "")

if [ -n "$EXISTING_BUDGET" ]; then
    echo -e "${YELLOW}⚠️  Budget '$BUDGET_NAME' already exists${NC}"
    read -p "Do you want to update it? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${RED}❌ Operation cancelled${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Will update existing budget...${NC}"
fi
echo ""

# Deploy budget using ARM template
echo -e "${YELLOW}Deploying budget configuration...${NC}"
echo ""
echo -e "Configuration:"
echo -e "  Budget Name:    $BUDGET_NAME"
echo -e "  Amount:         \$$AMOUNT/month"
echo -e "  Email:          $EMAIL"
echo -e "  Resource Group: $RESOURCE_GROUP"
echo -e "  Thresholds:     80% (Actual), 100% (Actual), 100% (Forecasted)"
echo ""

DEPLOYMENT_NAME="budget-alert-$(date +%Y%m%d-%H%M%S)"

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "westeurope" \
    --template-file "$TEMPLATE_FILE" \
    --parameters \
        budgetName="$BUDGET_NAME" \
        amount=$AMOUNT \
        contactEmails="['$EMAIL']" \
    --only-show-errors

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Budget alert configured successfully!${NC}"
    echo ""
    echo -e "${BLUE}📧 Email Notifications Configured:${NC}"
    echo -e "   • At 80% of budget (\$80):  $EMAIL"
    echo -e "   • At 100% of budget (\$100): $EMAIL"
    echo -e "   • Forecasted to exceed \$100: $EMAIL"
    echo ""
    echo -e "${BLUE}📊 View Budget in Azure Portal:${NC}"
    echo -e "   https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/budgets"
    echo ""
    echo -e "${YELLOW}⚠️  Important Notes:${NC}"
    echo -e "   • Email notifications may take 24-48 hours to activate"
    echo -e "   • Check spam folder for verification email from Azure"
    echo -e "   • Costs are calculated daily (not real-time)"
    echo -e "   • Forecasted alerts use ML predictions based on historical data"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Failed to configure budget alert${NC}"
    echo -e "${YELLOW}Please check the error messages above${NC}"
    exit 1
fi

# Display current budget details
echo -e "${YELLOW}Fetching budget details...${NC}"
az consumption budget show \
    --budget-name "$BUDGET_NAME" \
    --subscription "$SUBSCRIPTION_ID" \
    --query "{Name:name, Amount:amount, TimeGrain:timeGrain, Category:category}" \
    -o table

echo ""
echo -e "${GREEN}✅ Budget alert configuration completed!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Check your email ($EMAIL) for Azure notifications"
echo -e "2. Verify budget in Azure Portal"
echo -e "3. Monitor costs in Azure Cost Management"
echo -e "4. Review monthly: Cost vs Estimate"
echo ""
echo -e "${BLUE}================================================${NC}"
