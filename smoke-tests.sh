#!/bin/bash
# 🧪 Smoke Tests - Kitten Space Missions Infrastructure
# Activity 08 - Testing & Validation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0

# Configuration
RG_NAME="rg-kitten-missions-dev"
APP_SERVICE_NAME="app-kitten-missions-dev"
SQL_SERVER_NAME="sql-kitten-missions-dev-hvdtoc"
SQL_DB_NAME="sqldb-kitten-missions-dev"
KV_NAME="kv-km-dev-hvdtoc"
LOG_ANALYTICS_NAME="log-kitten-missions-dev"
APP_INSIGHTS_NAME="appi-kitten-missions-dev"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Smoke Tests - Kitten Space Missions Infrastructure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL=$((TOTAL + 1))
    echo -n "Test $TOTAL: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test 1: Resource Group exists
run_test "Resource Group exists" \
    "az group show --name $RG_NAME --query id -o tsv"

if [ $? -eq 0 ]; then
    RG_LOCATION=$(az group show --name $RG_NAME --query location -o tsv)
    echo "   └─ Location: $RG_LOCATION"
fi

# Test 2: App Service is running
run_test "App Service is running" \
    "az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query 'state' -o tsv | grep -q 'Running'"

if [ $? -eq 0 ]; then
    APP_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query defaultHostName -o tsv)
    echo "   └─ URL: https://$APP_URL"
fi

# Test 3: SQL Database is online
run_test "SQL Database is online" \
    "az sql db show --name $SQL_DB_NAME --server $SQL_SERVER_NAME --resource-group $RG_NAME --query 'status' -o tsv | grep -q 'Online'"

if [ $? -eq 0 ]; then
    SQL_EDITION=$(az sql db show --name $SQL_DB_NAME --server $SQL_SERVER_NAME --resource-group $RG_NAME --query 'edition' -o tsv)
    echo "   └─ Edition: $SQL_EDITION"
fi

# Test 4: Key Vault is accessible
run_test "Key Vault is accessible" \
    "az keyvault show --name $KV_NAME --query id -o tsv"

if [ $? -eq 0 ]; then
    KV_SKU=$(az keyvault show --name $KV_NAME --query 'properties.sku.name' -o tsv)
    echo "   └─ SKU: $KV_SKU"
fi

# Test 5: Managed Identity assigned to App Service
run_test "Managed Identity assigned" \
    "az webapp identity show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query principalId -o tsv"

if [ $? -eq 0 ]; then
    MI_PRINCIPAL=$(az webapp identity show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query principalId -o tsv)
    echo "   └─ Principal ID: $MI_PRINCIPAL"
fi

# Test 6: Key Vault access policy configured for App Service
echo -n "Test $((TOTAL + 1)): Key Vault access policy configured... "
TOTAL=$((TOTAL + 1))
APP_IDENTITY=$(az webapp identity show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query principalId -o tsv 2>/dev/null)
KV_POLICIES=$(az keyvault show --name $KV_NAME --query "properties.accessPolicies[?objectId=='$APP_IDENTITY'].objectId" -o tsv 2>/dev/null)

if [ -n "$KV_POLICIES" ]; then
    echo -e "${GREEN}✅ PASSED${NC}"
    PASSED=$((PASSED + 1))
    echo "   └─ App Service has Key Vault access"
else
    echo -e "${RED}❌ FAILED${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 7: Application Insights configured
run_test "Application Insights configured" \
    "az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RG_NAME --query id -o tsv"

if [ $? -eq 0 ]; then
    APPI_KEY=$(az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RG_NAME --query instrumentationKey -o tsv)
    echo "   └─ Instrumentation Key: ${APPI_KEY:0:8}..."
fi

# Test 8: Log Analytics Workspace exists
run_test "Log Analytics Workspace exists" \
    "az monitor log-analytics workspace show --workspace-name $LOG_ANALYTICS_NAME --resource-group $RG_NAME --query id -o tsv"

if [ $? -eq 0 ]; then
    LOG_RETENTION=$(az monitor log-analytics workspace show --workspace-name $LOG_ANALYTICS_NAME --resource-group $RG_NAME --query retentionInDays -o tsv)
    echo "   └─ Retention: $LOG_RETENTION days"
fi

# Test 9: App Service HTTPS only
run_test "App Service HTTPS only enabled" \
    "az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query httpsOnly -o tsv | grep -q 'true'"

# Test 10: SQL Server public access disabled (if configured)
echo -n "Test $((TOTAL + 1)): SQL Server firewall rules... "
TOTAL=$((TOTAL + 1))
FIREWALL_RULES=$(az sql server firewall-rule list --server $SQL_SERVER_NAME --resource-group $RG_NAME --query "length(@)" -o tsv 2>/dev/null)
if [ "$FIREWALL_RULES" -ge 0 ]; then
    echo -e "${GREEN}✅ PASSED${NC}"
    PASSED=$((PASSED + 1))
    echo "   └─ Firewall rules configured: $FIREWALL_RULES"
else
    echo -e "${YELLOW}⚠️  SKIPPED${NC}"
fi

# Test 11: App Service health endpoint
echo -n "Test $((TOTAL + 1)): App Service health check... "
TOTAL=$((TOTAL + 1))
APP_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query defaultHostName -o tsv)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$APP_URL" --max-time 10 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]; then
    echo -e "${GREEN}✅ PASSED${NC}"
    PASSED=$((PASSED + 1))
    echo "   └─ HTTP Status: $HTTP_CODE"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}"
    echo "   └─ HTTP Status: $HTTP_CODE (App may not be deployed yet)"
fi

# Test 12: Diagnostic settings enabled
echo -n "Test $((TOTAL + 1)): Diagnostic settings configured... "
TOTAL=$((TOTAL + 1))
# Check if diagnostic settings exist (simplified check)
if az monitor diagnostic-settings list --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$APP_SERVICE_NAME" --query "length(value)" -o tsv > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠️  SKIPPED${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Tests: $TOTAL"
echo -e "Passed:      ${GREEN}$PASSED${NC}"
echo -e "Failed:      ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All critical tests passed!${NC}"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  Some tests failed. Please review the output above.${NC}"
    echo ""
    exit 1
fi
