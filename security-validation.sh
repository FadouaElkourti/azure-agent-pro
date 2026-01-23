#!/bin/bash
# 🔐 Security Validation - Kitten Space Missions
# Activity 08 - Security Best Practices Check

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
RG_NAME="rg-kitten-missions-dev"
APP_SERVICE_NAME="app-kitten-missions-dev"
SQL_SERVER_NAME="sql-kitten-missions-dev-hvdtoc"
SQL_DB_NAME="sqldb-kitten-missions-dev"
KV_NAME="kv-km-dev-hvdtoc"

# Security Score
SCORE=0
MAX_SCORE=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Security Validation - Azure Well-Architected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_security() {
    local check_name="$1"
    local command="$2"
    local expected="$3"
    local points="${4:-10}"
    
    MAX_SCORE=$((MAX_SCORE + points))
    echo -n "🔍 $check_name... "
    
    result=$(eval "$command" 2>/dev/null || echo "")
    
    if [ "$result" = "$expected" ]; then
        echo -e "${GREEN}✅ PASSED${NC} (+$points points)"
        SCORE=$((SCORE + points))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC} (Found: $result, Expected: $expected)"
        return 1
    fi
}

# 1. App Service HTTPS Only
check_security \
    "App Service HTTPS Only" \
    "az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query httpsOnly -o tsv" \
    "true" \
    15

# 2. App Service TLS 1.2 Minimum
check_security \
    "App Service TLS 1.2+ minimum" \
    "az webapp config show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query minTlsVersion -o tsv" \
    "1.2" \
    15

# 3. Managed Identity Configured
echo -n "🔍 Managed Identity configured... "
MAX_SCORE=$((MAX_SCORE + 15))
MI_TYPE=$(az webapp identity show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query type -o tsv 2>/dev/null)
if [ "$MI_TYPE" = "SystemAssigned" ]; then
    echo -e "${GREEN}✅ PASSED${NC} (+15 points)"
    SCORE=$((SCORE + 15))
else
    echo -e "${RED}❌ FAILED${NC} (Type: $MI_TYPE)"
fi

# 4. Key Vault Soft Delete Enabled
check_security \
    "Key Vault Soft Delete enabled" \
    "az keyvault show --name $KV_NAME --query 'properties.enableSoftDelete' -o tsv" \
    "true" \
    10

# 5. Key Vault Purge Protection
check_security \
    "Key Vault Purge Protection enabled" \
    "az keyvault show --name $KV_NAME --query 'properties.enablePurgeProtection' -o tsv" \
    "true" \
    10

# 6. SQL Server Azure AD Auth
echo -n "🔍 SQL Server Azure AD authentication... "
MAX_SCORE=$((MAX_SCORE + 15))
SQL_AD_ADMIN=$(az sql server ad-admin list --server $SQL_SERVER_NAME --resource-group $RG_NAME --query "[0].login" -o tsv 2>/dev/null)
if [ -n "$SQL_AD_ADMIN" ]; then
    echo -e "${GREEN}✅ PASSED${NC} (+15 points)"
    SCORE=$((SCORE + 15))
    echo "   └─ Admin: $SQL_AD_ADMIN"
else
    echo -e "${YELLOW}⚠️  WARNING${NC} (No Azure AD admin configured)"
fi

# 7. SQL Database TDE (Transparent Data Encryption)
echo -n "🔍 SQL Database Transparent Data Encryption... "
MAX_SCORE=$((MAX_SCORE + 10))
SQL_TDE=$(az sql db tde show --database $SQL_DB_NAME --server $SQL_SERVER_NAME --resource-group $RG_NAME --query status -o tsv 2>/dev/null)
if [ "$SQL_TDE" = "Enabled" ]; then
    echo -e "${GREEN}✅ PASSED${NC} (+10 points)"
    SCORE=$((SCORE + 10))
else
    echo -e "${YELLOW}⚠️  WARNING${NC} (TDE: $SQL_TDE)"
fi

# 8. App Service FTP disabled
echo -n "🔍 App Service FTP state... "
MAX_SCORE=$((MAX_SCORE + 10))
FTP_STATE=$(az webapp config show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query ftpsState -o tsv 2>/dev/null)
if [ "$FTP_STATE" = "Disabled" ] || [ "$FTP_STATE" = "FtpsOnly" ]; then
    echo -e "${GREEN}✅ PASSED${NC} (+10 points)"
    SCORE=$((SCORE + 10))
    echo "   └─ FTP State: $FTP_STATE"
else
    echo -e "${RED}❌ FAILED${NC} (FTP State: $FTP_STATE)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛡️  Security Score Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PERCENTAGE=$((SCORE * 100 / MAX_SCORE))
echo "Score: $SCORE / $MAX_SCORE points ($PERCENTAGE%)"
echo ""

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🏆 Excellent! Security posture is strong.${NC}"
    EXIT_CODE=0
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  Good, but some improvements needed.${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}❌ Critical security issues found. Please remediate.${NC}"
    EXIT_CODE=1
fi

echo ""
echo "📚 Recommendations:"
echo "  - Enable all security features for production environments"
echo "  - Review Azure Security Center recommendations"
echo "  - Implement Private Endpoints for PaaS services"
echo "  - Enable Advanced Threat Protection"
echo ""

exit $EXIT_CODE
