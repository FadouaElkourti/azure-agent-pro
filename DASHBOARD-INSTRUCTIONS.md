# 🎨 Instrucciones: Importar Dashboard de Azure

## 📋 Archivo Dashboard

**Archivo**: `dashboard-kitten-missions.json`  
**Dashboard Name**: "Kitten Missions - Dev Dashboard"  
**Tiles**: 9 tiles configurados

---

## 🚀 Método 1: Importar en Azure Portal (Recomendado)

### Paso 1: Ir a Dashboards

1. Abre [Azure Portal](https://portal.azure.com)
2. En el menú lateral, click **"Dashboard"** (o busca "Dashboard" en el search bar)
3. Click **"+ Upload"** (o "+ Create" → "Upload a dashboard")

### Paso 2: Seleccionar archivo JSON

1. Click **"Browse"**
2. Navega a: `/home/fadoua/repos/github/workshop/azure-agent-pro/`
3. Selecciona: **`dashboard-kitten-missions.json`**
4. Click **"Open"**

### Paso 3: Guardar Dashboard

1. Azure Portal cargará el JSON
2. Verás el dashboard con 9 tiles configurados
3. Click **"Save"** (icono de disquete arriba)
4. Confirma el nombre: "Kitten Missions - Dev Dashboard"

**✅ ¡Listo!** Ya puedes ver el dashboard.

---

## 🖱️ Método 2: Crear Manualmente (Alternativo)

Si prefieres crear el dashboard manualmente tile por tile:

### 1. Crear Dashboard Blank

```
Azure Portal → Dashboard → + Create → Blank dashboard
Nombre: "Kitten Missions - Dev"
```

### 2. Añadir Tiles

Click **"Edit"** → **"+ Add tile"**

#### Tile 1: Request Rate
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**: (copia de kql-queries.md - Request Rate)
- **Time Range**: Last 24 hours
- **Visualization**: Line chart

#### Tile 2: Response Time P95
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**: (copia de kql-queries.md - P95 Latency)
- **Time Range**: Last 1 hour
- **Visualization**: Bar chart

#### Tile 3: Error Rate
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**: (copia de kql-queries.md - Error Rate)
- **Time Range**: Last 1 hour
- **Visualization**: Big number

#### Tile 4: Availability
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**:
  ```kql
  availabilityResults
  | where timestamp > ago(1h)
  | summarize AvailabilityRate = avg(todouble(success)) * 100
  | project AvailabilityRate = round(AvailabilityRate, 2)
  ```
- **Visualization**: Big number

#### Tile 5: SQL DTU Usage
- **Type**: Metrics Chart
- **Resource**: `sqldb-kitten-missions-dev`
- **Metric**: DTU percentage
- **Aggregation**: Average
- **Time Range**: Last 1 hour
- **Chart Type**: Line chart

#### Tile 6: Failed Requests
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**: (copia de kql-queries.md - Failed Requests)
- **Time Range**: Last 1 hour
- **Visualization**: Table

#### Tile 7: Dependency Calls
- **Type**: Logs (Application Insights)
- **Resource**: `appi-kitten-missions-dev`
- **Query**: (copia de kql-queries.md - Dependency Calls)
- **Time Range**: Last 1 hour
- **Visualization**: Table

#### Tile 8: App Service CPU
- **Type**: Metrics Chart
- **Resource**: `app-kitten-missions-dev`
- **Metric**: CPU Time
- **Aggregation**: Total
- **Time Range**: Last 1 hour
- **Chart Type**: Line chart

#### Tile 9: App Service Memory
- **Type**: Metrics Chart
- **Resource**: `app-kitten-missions-dev`
- **Metric**: Memory Working Set
- **Aggregation**: Average
- **Time Range**: Last 1 hour
- **Chart Type**: Line chart

### 3. Layout Optimization

Arrastra y redimensiona los tiles para un layout óptimo:

```
┌─────────────────────────┬─────────────────────────┐
│  Request Rate (6x4)     │  Response Time P95 (6x4)│
├──────────┬──────────┬───┴──────────┬──────────────┤
│ Error    │ Avail.   │  SQL DTU     │              │
│ Rate     │          │  Usage       │              │
│ (3x3)    │ (3x3)    │  (6x3)       │              │
├──────────┴──────────┼──────────────┴──────────────┤
│  Failed Requests     │  Dependency Calls          │
│  (6x4)               │  (6x4)                     │
├──────────────────────┼────────────────────────────┤
│  App Service CPU     │  App Service Memory        │
│  (6x4)               │  (6x4)                     │
└──────────────────────┴────────────────────────────┘
```

---

## 📊 Tiles del Dashboard

| # | Tile | Tipo | Query/Metric | Time Range |
|---|------|------|--------------|------------|
| 1 | 📊 Request Rate | KQL | `requests | summarize count() by bin(timestamp, 5m)` | 24h |
| 2 | ⏱️ Response Time P95 | KQL | `percentile(duration, 95) by name` | 1h |
| 3 | 🚨 Error Rate | KQL | `(FailedRequests * 100.0) / TotalRequests` | 1h |
| 4 | ✅ Availability | KQL | `avg(success) * 100` from availabilityResults | 1h |
| 5 | 💾 SQL DTU Usage | Metric | dtu_consumption_percent | 1h |
| 6 | ❌ Failed Requests | KQL | `requests | where success == false | take 20` | 1h |
| 7 | 🔗 Dependency Calls | KQL | `dependencies | summarize by name, type` | 1h |
| 8 | 🖥️ App Service CPU | Metric | CpuTime | 1h |
| 9 | 💾 App Service Memory | Metric | MemoryWorkingSet | 1h |

---

## 🔍 Verificar Dashboard

Una vez importado, verifica:

✅ **Todos los tiles cargan datos** (no "No data")  
✅ **Request Rate** muestra línea temporal  
✅ **Error Rate** muestra porcentaje (puede ser 0% si no hay errores)  
✅ **SQL DTU** muestra uso de database  
✅ **Dependency Calls** muestra llamadas a SQL/Key Vault  

⚠️ **Nota**: Algunos tiles pueden estar vacíos si la aplicación aún no está desplegada o no hay tráfico.

---

## 🎯 Próximos Pasos

1. **Pin a Home**: Click ⭐ "Pin to dashboard" para acceso rápido
2. **Share Dashboard**: Settings → Share (si trabajas en equipo)
3. **Auto-refresh**: Configure auto-refresh (5 min, 15 min, 1h)
4. **Exportar**: Settings → Download para backup

---

## 📚 Recursos Adicionales

- **Queries KQL**: [kql-queries.md](kql-queries.md)
- **Activity 07 Summary**: [activity-07-summary.md](activity-07-summary.md)
- **Azure Dashboards Docs**: [Create and share dashboards](https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards)

---

## 🐛 Troubleshooting

### Problema: "No data available"

**Causa**: Aplicación no está generando telemetría  
**Solución**: 
1. Verifica que Application Insights está configurado
2. Despliega la aplicación (Activity 08)
3. Genera tráfico HTTP al App Service
4. Espera 2-5 minutos para que aparezcan datos

### Problema: "Query failed"

**Causa**: Query KQL con sintaxis incorrecta  
**Solución**:
1. Abre Application Insights → Logs
2. Ejecuta la query manualmente
3. Corrige errores
4. Actualiza el tile del dashboard

### Problema: JSON import falla

**Causa**: Resource IDs incorrectos en JSON  
**Solución**:
1. Edita `dashboard-kitten-missions.json`
2. Reemplaza todos los `d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d` con tu Subscription ID
3. Guarda y vuelve a importar

---

**✅ Dashboard listo para monitoreo 24/7!** 🎉
