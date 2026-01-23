#!/bin/bash
# Azure Monitoring Setup - Activity 07
# Configura Action Groups y Alertas para Kitten Space Missions

set -euo pipefail

# Variables
RG_NAME="rg-kitten-missions-dev"
APP_INSIGHTS_NAME="appi-kitten-missions-dev"
APP_SERVICE_NAME="app-kitten-missions-dev"
SQL_SERVER_NAME="sql-kitten-missions-dev-hvdtoc"
SQL_DB_NAME="sqldb-kitten-missions-dev"
ACTION_GROUP_NAME="ag-kitten-missions-dev"
EMAIL="${1:-f.Elkourti_Useroffice365.onmicrosoft.com#EXT#@certones.onmicrosoft.com}"

echo "🚨 Configurando Monitoring & Alerts para Kitten Space Missions"
echo "=============================================================="
echo ""

# Obtener Resource IDs
echo "📋 Obteniendo Resource IDs..."
APP_INSIGHTS_ID=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS_NAME" \
  --resource-group "$RG_NAME" \
  --query id -o tsv)

APP_SERVICE_ID=$(az webapp show \
  --name "$APP_SERVICE_NAME" \
  --resource-group "$RG_NAME" \
  --query id -o tsv)

SQL_DB_ID=$(az sql db show \
  --name "$SQL_DB_NAME" \
  --server "$SQL_SERVER_NAME" \
  --resource-group "$RG_NAME" \
  --query id -o tsv)

echo "✅ App Insights ID: $APP_INSIGHTS_ID"
echo "✅ App Service ID: $APP_SERVICE_ID"
echo "✅ SQL Database ID: $SQL_DB_ID"
echo ""

# Crear Action Group
echo "1️⃣ Creando Action Group para notificaciones..."
ACTION_GROUP_ID=$(az monitor action-group create \
  --name "$ACTION_GROUP_NAME" \
  --resource-group "$RG_NAME" \
  --short-name "KittenOps" \
  --email-receiver name="Admin" email-address="$EMAIL" \
  --query id -o tsv 2>/dev/null || \
  az monitor action-group show \
    --name "$ACTION_GROUP_NAME" \
    --resource-group "$RG_NAME" \
    --query id -o tsv)

echo "✅ Action Group creado: $ACTION_GROUP_ID"
echo ""

# Alerta 1: High Error Rate
echo "2️⃣ Creando alerta: High Error Rate..."
az monitor metrics alert create \
  --name "High-Error-Rate-Alert" \
  --resource-group "$RG_NAME" \
  --scopes "$APP_INSIGHTS_ID" \
  --description "Alert when HTTP 5xx errors > 10 in 5 minutes" \
  --condition "count requests/failed > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 0 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  || echo "⚠️  Alerta ya existe o error en creación"

echo "✅ Alerta High Error Rate configurada"
echo ""

# Alerta 2: High Response Time
echo "3️⃣ Creando alerta: High Response Time..."
az monitor metrics alert create \
  --name "High-Response-Time-Alert" \
  --resource-group "$RG_NAME" \
  --scopes "$APP_INSIGHTS_ID" \
  --description "Alert when P95 response time > 500ms for 10 minutes" \
  --condition "avg requests/duration > 500" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  || echo "⚠️  Alerta ya existe o error en creación"

echo "✅ Alerta High Response Time configurada"
echo ""

# Alerta 3: App Service CPU High
echo "4️⃣ Creando alerta: App Service High CPU..."
az monitor metrics alert create \
  --name "AppService-High-CPU-Alert" \
  --resource-group "$RG_NAME" \
  --scopes "$APP_SERVICE_ID" \
  --description "Alert when App Service CPU > 80% for 10 minutes" \
  --condition "avg CpuPercentage > 80" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  || echo "⚠️  Alerta ya existe o error en creación"

echo "✅ Alerta App Service CPU configurada"
echo ""

# Alerta 4: SQL Database DTU High
echo "5️⃣ Creando alerta: SQL Database High DTU..."
az monitor metrics alert create \
  --name "SQL-High-DTU-Alert" \
  --resource-group "$RG_NAME" \
  --scopes "$SQL_DB_ID" \
  --description "Alert when SQL DTU > 80% for 10 minutes" \
  --condition "avg dtu_consumption_percent > 80" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  || echo "⚠️  Alerta ya existe o error en creación"

echo "✅ Alerta SQL DTU configurada"
echo ""

# Listar alertas configuradas
echo "📊 Resumen de alertas configuradas:"
az monitor metrics alert list \
  --resource-group "$RG_NAME" \
  --query "[].{Name:name, Enabled:enabled, Severity:severity, Target:scopes[0]}" \
  -o table

echo ""
echo "✅ ¡Monitoring configurado exitosamente!"
echo ""
echo "📧 Notificaciones se enviarán a: $EMAIL"
echo "🔗 Ver alertas en Azure Portal:"
echo "   https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/alertsV2"
