# Budget Alert Configuration - Kitten Space Missions

## 📋 Overview

Configuración de Azure Budget Alert para monitorear costos y prevenir sorpresas en la factura.

**Budget configurado**: $100/mes  
**Notificaciones**: faduaelkourti@gmail.com  
**Subscription**: d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d

---

## 🚀 Quick Start

### Opción 1: Ejecutar Script Automatizado (Recomendado)

```bash
cd scripts
./configure-budget-alert.sh
```

El script:
- ✅ Verifica login Azure
- ✅ Configura subscription correcta
- ✅ Despliega budget con ARM template
- ✅ Configura 3 alertas (80%, 100%, forecasted)
- ✅ Muestra resumen de configuración

---

### Opción 2: Deployment Manual con Azure CLI

```bash
# Variables
SUBSCRIPTION_ID="d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"
TEMPLATE_FILE="scripts/budget-alert.json"

# Login (si no estás logueado)
az login

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Deploy ARM template
az deployment sub create \
  --name "budget-alert-$(date +%Y%m%d)" \
  --location "westeurope" \
  --template-file "$TEMPLATE_FILE" \
  --parameters \
    budgetName="kitten-missions-dev-budget" \
    amount=100 \
    contactEmails="['faduaelkourti@gmail.com']"
```

---

## 📧 Notificaciones Configuradas

### 1. Alert al 80% ($80/mes)

```
Tipo:      Actual Cost
Threshold: 80%
Acción:    Email a faduaelkourti@gmail.com
Propósito: Early warning - tiempo de optimizar
```

**Qué hacer cuando recibas este email:**
- 🔍 Revisar Azure Cost Management dashboard
- 📊 Identificar recursos con mayor costo
- ⚠️ Evaluar si hay recursos orphaned
- 📝 Documentar hallazgos en cost review

### 2. Alert al 100% ($100/mes)

```
Tipo:      Actual Cost
Threshold: 100%
Acción:    Email a faduaelkourti@gmail.com
Propósito: Budget limit reached - acción inmediata
```

**Qué hacer cuando recibas este email:**
- 🚨 URGENTE: Revisar costos inmediatamente
- 🛑 Considerar pausar recursos no-críticos
- 📊 Analizar spike de costos (¿esperado o anomalía?)
- 💬 Notificar al equipo

### 3. Alert Forecasted 100%

```
Tipo:      Forecasted Cost (ML prediction)
Threshold: 100%
Acción:    Email a faduaelkourti@gmail.com
Propósito: Predicción de exceso ANTES de que ocurra
```

**Qué hacer cuando recibas este email:**
- 📈 Azure predice que excederás budget este mes
- 🔮 Basado en patrones de uso histórico
- ✅ Tiempo de optimizar proactivamente
- 📝 Revisar tendencias de crecimiento

---

## 🎯 Thresholds y Acciones

| Threshold | Tipo | Costo | Acción Recomendada | Urgencia |
|-----------|------|-------|-------------------|----------|
| **80%** | Actual | $80 | Review & optimize | 🟡 Media |
| **100%** | Actual | $100 | Immediate action | 🔴 Alta |
| **100%** | Forecast | Predicción | Proactive optimization | 🟠 Media-Alta |

---

## 📊 Ver Budget en Azure Portal

### Portal URL
```
https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/budgets
```

### Steps:
1. Login a Azure Portal
2. Ir a **Cost Management + Billing**
3. Click en **Budgets**
4. Buscar: `kitten-missions-dev-budget`
5. Ver detalles, alertas, historial

---

## 🔍 Monitoreo de Costos

### Azure CLI - Costo Actual

```bash
# Costo mes actual
az consumption usage list \
  --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'kitten')].{Resource:instanceName, Cost:pretaxCost}" \
  -o table

# Resumen por Resource Group
az consumption usage list \
  --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  | jq '[.[] | select(.instanceName | contains("kitten"))] | group_by(.meterCategory) | map({category: .[0].meterCategory, cost: (map(.pretaxCost) | add)})'
```

### Azure CLI - Budget Status

```bash
# Ver budget actual
az consumption budget show \
  --budget-name "kitten-missions-dev-budget" \
  --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"

# Listar todos los budgets
az consumption budget list \
  --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d" \
  -o table
```

---

## 🛠️ Modificar Budget

### Cambiar Monto del Budget

```bash
# Actualizar a $150/mes
az deployment sub create \
  --name "budget-update-$(date +%Y%m%d)" \
  --location "westeurope" \
  --template-file scripts/budget-alert.json \
  --parameters \
    budgetName="kitten-missions-dev-budget" \
    amount=150 \
    contactEmails="['faduaelkourti@gmail.com']"
```

### Agregar Emails Adicionales

```bash
# Agregar múltiples destinatarios
az deployment sub create \
  --name "budget-update-$(date +%Y%m%d)" \
  --location "westeurope" \
  --template-file scripts/budget-alert.json \
  --parameters \
    budgetName="kitten-missions-dev-budget" \
    amount=100 \
    contactEmails="['faduaelkourti@gmail.com','team@company.com']"
```

### Cambiar Thresholds

Editar `budget-alert.json` y modificar sección `notifications`:

```json
"notifications": {
  "Actual_GreaterThan_50_Percent": {
    "enabled": true,
    "threshold": 50,
    // ...
  }
}
```

---

## ❌ Eliminar Budget

```bash
# Eliminar budget
az consumption budget delete \
  --budget-name "kitten-missions-dev-budget" \
  --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d"
```

---

## 📝 Troubleshooting

### Email No Llega

**Causas comunes:**
1. ⏱️ **Delay de activación**: Puede tardar 24-48 horas en activarse
2. 📧 **Verificación pendiente**: Buscar email de verificación en spam
3. 🔍 **Email incorrecto**: Verificar typo en email
4. 🚫 **Filtro spam**: Agregar `azure-noreply@microsoft.com` a contactos

**Verificar configuración:**
```bash
az consumption budget show \
  --budget-name "kitten-missions-dev-budget" \
  --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d" \
  --query "properties.notifications"
```

### Budget No Aparece en Portal

**Solución:**
1. Esperar 5-10 minutos (propagación)
2. Refresh navegador (Ctrl+F5)
3. Verificar subscription correcta seleccionada
4. Check permisos: Necesitas rol `Cost Management Contributor`

### Threshold No Funciona

**Validar:**
```bash
# Ver estado de alertas
az consumption budget show \
  --budget-name "kitten-missions-dev-budget" \
  --subscription "d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d" \
  --query "properties.notifications" \
  -o json
```

**Causas comunes:**
- `enabled: false` → Cambiar a `true`
- `thresholdType` incorrecto → Usar `Actual` o `Forecasted`
- Email no verificado → Check spam, verificar email

---

## 📚 Referencias

- [Azure Budgets Documentation](https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-acm-create-budgets)
- [Budget ARM Template Reference](https://learn.microsoft.com/azure/templates/microsoft.consumption/budgets)
- [Cost Management Best Practices](https://learn.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices)
- [Cost Optimization Guide](https://learn.microsoft.com/azure/architecture/framework/cost/)

---

## ✅ Checklist Post-Configuration

- [ ] Script ejecutado exitosamente
- [ ] Budget visible en Azure Portal
- [ ] Email de verificación recibido y confirmado
- [ ] Test alert enviado (optional: trigger manual test)
- [ ] Agregado a calendar: Review mensual costos
- [ ] Documentado en Cost Decision Record
- [ ] Equipo notificado de budget configurado

---

**Status**: ✅ Ready to deploy  
**Estimated Setup Time**: 5-10 minutos  
**Next Review**: Primer día de cada mes
