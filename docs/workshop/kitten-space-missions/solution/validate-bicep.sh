#!/bin/bash
# Validation script for Kitten Space Missions Bicep modules
# Verifies syntax, best practices, and dependencies

set -e

echo "🐱 Kitten Space Missions - Bicep Validation"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Azure CLI
echo "📋 Checking prerequisites..."
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Install: https://aka.ms/install-azure-cli${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI installed${NC}"

# Check Bicep
if ! command -v bicep &> /dev/null; then
    echo -e "${YELLOW}⚠️  Bicep CLI not found. Installing...${NC}"
    az bicep install
fi
BICEP_VERSION=$(az bicep version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
echo -e "${GREEN}✅ Bicep CLI installed (version: $BICEP_VERSION)${NC}"
echo ""

# Navigate to solution directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📁 Validating Bicep modules..."
echo ""

# Validate main.bicep
echo "1️⃣  Validating main.bicep..."
if az bicep build --file bicep/main.bicep --outdir /tmp > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ main.bicep - Syntax OK${NC}"
else
    echo -e "${RED}   ❌ main.bicep - Syntax errors${NC}"
    az bicep build --file bicep/main.bicep 2>&1 | tail -20
    exit 1
fi

# Validate app-service.bicep
echo "2️⃣  Validating modules/app-service.bicep..."
if az bicep build --file bicep/modules/app-service.bicep --outdir /tmp > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ app-service.bicep - Syntax OK${NC}"
else
    echo -e "${RED}   ❌ app-service.bicep - Syntax errors${NC}"
    az bicep build --file bicep/modules/app-service.bicep 2>&1 | tail -20
    exit 1
fi

# Validate monitoring.bicep
echo "3️⃣  Validating modules/monitoring.bicep..."
if az bicep build --file bicep/modules/monitoring.bicep --outdir /tmp > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ monitoring.bicep - Syntax OK${NC}"
else
    echo -e "${RED}   ❌ monitoring.bicep - Syntax errors${NC}"
    az bicep build --file bicep/modules/monitoring.bicep 2>&1 | tail -20
    exit 1
fi

# Check parameters file
echo "4️⃣  Validating parameters/dev.parameters.json..."
if jq empty bicep/parameters/dev.parameters.json 2>/dev/null; then
    echo -e "${GREEN}   ✅ dev.parameters.json - Valid JSON${NC}"
    
    # Check for placeholder values
    if grep -q "<YOUR_AZURE_AD_OBJECT_ID>" bicep/parameters/dev.parameters.json; then
        echo -e "${YELLOW}   ⚠️  Warning: Placeholder values detected in parameters file${NC}"
        echo -e "${YELLOW}      Update sqlAzureAdAdminObjectId before deployment${NC}"
    fi
else
    echo -e "${RED}   ❌ dev.parameters.json - Invalid JSON${NC}"
    exit 1
fi

echo ""
echo "🔍 Checking module dependencies..."

# Check if referenced modules exist
MISSING_MODULES=()

if [ ! -f "../../../../bicep/modules/key-vault.bicep" ]; then
    MISSING_MODULES+=("key-vault.bicep")
fi

if [ ! -f "../../../../bicep/modules/sql-database.bicep" ]; then
    MISSING_MODULES+=("sql-database.bicep")
fi

if [ ${#MISSING_MODULES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All module dependencies found${NC}"
else
    echo -e "${RED}❌ Missing module dependencies:${NC}"
    for module in "${MISSING_MODULES[@]}"; do
        echo -e "${RED}   - $module${NC}"
    done
    exit 1
fi

echo ""
echo "📊 Module Statistics:"
echo ""

# Count lines in modules
MAIN_LINES=$(wc -l < bicep/main.bicep)
APP_SERVICE_LINES=$(wc -l < bicep/modules/app-service.bicep)
MONITORING_LINES=$(wc -l < bicep/modules/monitoring.bicep)
TOTAL_LINES=$((MAIN_LINES + APP_SERVICE_LINES + MONITORING_LINES))

echo "   main.bicep:         $MAIN_LINES lines"
echo "   app-service.bicep:  $APP_SERVICE_LINES lines"
echo "   monitoring.bicep:   $MONITORING_LINES lines"
echo "   ─────────────────────────────"
echo "   Total:              $TOTAL_LINES lines"

echo ""
echo "📚 Documentation:"
echo "   - Architecture Design Document:  docs/architecture/ADD-kitten-space-missions.md"
echo "   - Architecture Decision Record:  docs/adr/001-architecture.md"
echo "   - Deployment README:             bicep/README.md"

echo ""
echo -e "${GREEN}✅ All validations passed!${NC}"
echo ""
echo "🚀 Next steps:"
echo "   1. Update bicep/parameters/dev.parameters.json with your Azure AD details"
echo "   2. Create resource group: az group create --name rg-kitten-missions-dev --location westeurope"
echo "   3. Deploy: az deployment group create --resource-group rg-kitten-missions-dev --template-file bicep/main.bicep --parameters bicep/parameters/dev.parameters.json"
echo ""
echo "📖 For detailed deployment instructions, see: bicep/README.md"
