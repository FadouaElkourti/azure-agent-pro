#!/bin/bash
set -euo pipefail

RG="rg-kitten-missions-dev"
AG_ID="/subscriptions/D0C6D1B0-6B0A-4B6E-9EC1-85FF1AB0859D/resourceGroups/rg-kitten-missions-dev/providers/microsoft.insights/actionGroups/ag-kitten-missions-dev"

echo "🚨 Creando 4 alertas de monitoring..."
echo ""

# Alerta 1: High Response Time (App Service)
echo "1️⃣ High Response Time Alert..."
az monitor metrics alert create \
  --name "High-Response-Time" \
  --resource-group "$RG" \
  --scopes "/subscriptions/D0C6D1B0-6B0A-4B6E-9EC1-85FF1AB0859D/resourceGroups/rg-kitten-missions-dev/providers/Microsoft.Web/sites/app-kitten-missions-dev" \
  --description "Alerta cuando response time promedio > 2000ms por 10 minutos" \
  --condition "avg ResponseTime > 2000" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$AG_ID" \
  --auto-mitigate true \
  || echo "⚠️  Ya existe"

echo ""

# Alerta 2: High CPU (App Service)
echo "2️⃣ High CPU Alert..."
az monitor metrics alert create \
  --name "AppService-High-CPU" \
  --resource-group "$RG" \
  --scopes "/subscriptions/D0C6D1B0-6B0A-4B6E-9EC1-85FF1AB0859D/resourceGroups/rg-kitten-missions-dev/providers/Microsoft.Web/sites/app-kitten-missions-dev" \
  --description "Alerta cuando CPU > 80% por 10 minutos" \
  --condition "avg CpuPercentage > 80" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$AG_ID" \
  --auto-mitigate true \
  || echo "⚠️  Ya existe"

echo ""

# Alerta 3: High DTU (SQL Database)
echo "3️⃣ SQL High DTU Alert..."
az monitor metrics alert create \
  --name "SQL-High-DTU" \
  --resource-group "$RG" \
  --scopes "/subscriptions/D0C6D1B0-6B0A-4B6E-9EC1-85FF1AB0859D/resourceGroups/rg-kitten-missions-dev/providers/Microsoft.Sql/servers/sql-kitten-missions-dev-hvdtoc/databases/sqldb-kitten-missions-dev" \
  --description "Alerta cuando SQL DTU > 80% por 10 minutos" \
  --condition "avg dtu_consumption_percent > 80" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 2 \
  --action "$AG_ID" \
  --auto-mitigate true \
  || echo "⚠️  Ya existe"

echo ""

# Alerta 4: HTTP 5xx Errors (App Service)
echo "4️⃣ HTTP 5xx Errors Alert..."
az monitor metrics alert create \
  --name "HTTP-5xx-Errors" \
  --resource-group "$RG" \
  --scopes "/subscriptions/D0C6D1B0-6B0A-4B6E-9EC1-85FF1AB0859D/resourceGroups/rg-kitten-missions-dev/providers/Microsoft.Web/sites/app-kitten-missions-dev" \
  --description "Alerta cuando hay > 10 errores 5xx en 5 minutos" \
  --condition "total Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 0 \
  --action "$AG_ID" \
  --auto-mitigate true \
  || echo "⚠️  Ya existe"

echo ""
echo "✅ Alertas configuradas exitosamente!"
