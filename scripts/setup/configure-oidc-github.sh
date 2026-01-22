#!/bin/bash
# Script para configurar OIDC entre GitHub Actions y Azure
# Fecha: 2026-01-22

set -euo pipefail

# ========================================
# CONFIGURACIÓN - Edita estos valores
# ========================================
GITHUB_ORG="fadoua"  # Tu username de GitHub
GITHUB_REPO="azure-agent-pro"
APP_NAME="github-oidc-kitten-missions"
SUBSCRIPTION_ID="d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"
TENANT_ID="81612d31-5cee-4cdf-9a09-fac0be27ceef"

# ========================================
# EJECUCIÓN
# ========================================

echo "=========================================="
echo "🚀 Configuración OIDC GitHub → Azure"
echo "=========================================="
echo ""
echo "📋 Configuración:"
echo "  GitHub: $GITHUB_ORG/$GITHUB_REPO"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Tenant: $TENANT_ID"
echo ""

# 1. Crear Azure AD App Registration
echo "📝 [1/7] Creando App Registration..."
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

if [ -z "$APP_ID" ]; then
  echo "❌ Error: No se pudo crear App Registration"
  exit 1
fi

echo "✅ App creada: $APP_ID"

# 2. Crear Service Principal
echo "📝 [2/7] Creando Service Principal..."
az ad sp create --id "$APP_ID" --only-show-errors

echo "✅ Service Principal creado"

# Esperar 10 segundos para que Azure AD propague el SP
echo "⏳ Esperando propagación en Azure AD..."
sleep 10

# 3. Asignar rol Contributor a nivel subscription
echo "📝 [3/7] Asignando permisos Contributor..."
az role assignment create \
  --assignee "$APP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --only-show-errors

echo "✅ Permisos asignados"

# 4. Configurar Federated Credential para branch main
echo "📝 [4/7] Configurando OIDC para branch main..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }' \
  --only-show-errors

echo "✅ OIDC configurado para main branch"

# 5. Configurar Federated Credential para Pull Requests
echo "📝 [5/7] Configurando OIDC para Pull Requests..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':pull_request",
    "description": "GitHub Actions OIDC for PRs",
    "audiences": ["api://AzureADTokenExchange"]
  }' \
  --only-show-errors

echo "✅ OIDC configurado para Pull Requests"

# 6. Configurar Federated Credential para environment dev
echo "📝 [6/7] Configurando OIDC para environment dev..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-env-dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':environment:dev",
    "description": "GitHub Actions OIDC for dev environment",
    "audiences": ["api://AzureADTokenExchange"]
  }' \
  --only-show-errors

echo "✅ OIDC configurado para environment dev"

# 7. Verificar configuración
echo "📝 [7/7] Verificando configuración..."

echo ""
echo "Federated Credentials configuradas:"
az ad app federated-credential list \
  --id "$APP_ID" \
  --query "[].{Name:name, Subject:subject}" \
  -o table

echo ""
echo "Role Assignments:"
az role assignment list \
  --assignee "$APP_ID" \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  -o table

# 8. Mostrar resumen
echo ""
echo "=========================================="
echo "🎉 Configuración OIDC completada"
echo "=========================================="
echo ""
echo "📋 VALORES PARA GITHUB SECRETS:"
echo "=========================================="
echo ""
echo "AZURE_CLIENT_ID:       $APP_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "=========================================="
echo ""
echo "🚀 PRÓXIMOS PASOS:"
echo ""
echo "1. Ve a: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "2. Crea estos 3 secrets con los valores de arriba:"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_TENANT_ID"
echo "   - AZURE_SUBSCRIPTION_ID"
echo ""
echo "3. Crea el environment 'dev' en:"
echo "   https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/environments"
echo ""
echo "=========================================="

# Guardar valores en archivo temporal
cat > /tmp/github-secrets.txt << EOF
# GitHub Secrets para azure-agent-pro
# Generado: $(date)

AZURE_CLIENT_ID=$APP_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
EOF

echo ""
echo "💾 Valores guardados en: /tmp/github-secrets.txt"
echo ""
