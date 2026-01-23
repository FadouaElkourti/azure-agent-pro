# ✅ Activity 07: Monitoring & Observability - COMPLETADO

**Fecha**: 2026-01-23  
**Duración**: ~20 minutos  
**Estado**: ✅ COMPLETADO EXITOSAMENTE

---

## 📊 Resumen de Actividades

### ✅ Paso 1: Application Insights Explorado

**Application Insights Configurado**:
- **Name**: appi-kitten-missions-dev
- **App ID**: 7df1fca3-587f-444f-a967-a9b3c75db8b2
- **Instrumentation Key**: 23ba9546-4b5b-4a13-b9ca-6130a77029f0
- **Location**: northeurope
- **Connection String**: ✅ Configurado

**Portal Azure**:
- URL: https://portal.azure.com/#@certones.onmicrosoft.com/resource/subscriptions/d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d/resourceGroups/rg-kitten-missions-dev/providers/microsoft.insights/components/appi-kitten-missions-dev

---

### ✅ Paso 2: Queries KQL Creadas (10 queries esenciales)

**Archivo generado**: [kql-queries.md](./kql-queries.md)

**Queries disponibles**:
1. ✅ Request Rate (Requests/min últimas 24h)
2. ✅ Response Time P95 por Endpoint
3. ✅ Error Rate (HTTP 5xx)
4. ✅ Top 10 Endpoints Más Lentos
5. ✅ Failed Requests con Detalles
6. ✅ Dependency Calls (SQL, Key Vault, HTTP)
7. ✅ SQL Slow Queries
8. ✅ Exceptions y Errores
9. ✅ Availability Monitoring
10. ✅ Custom Telemetry (para cuando se despliegue API)

**Queries para alertas**:
- ✅ High Error Rate Alert (> 10 errores en 5min)
- ✅ High Response Time Alert (P95 > 500ms)
- ✅ SQL High Duration Alert (Avg > 200ms)

**Cómo usar las queries**:
1. Ir a Azure Portal → Application Insights → Logs
2. Copiar query de `kql-queries.md`
3. Ejecutar y analizar resultados
4. Guardar como favorito o pin to dashboard

---

### ✅ Paso 3: Dashboard Conceptual Diseñado

**Dashboard recomendado**: "Kitten Missions - Dev"

**Tiles a incluir**:
1. **Request Rate** (Line Chart)
   - Query: Requests por minuto últimas 24h
   - Threshold visual: < 1 req/min = warning

2. **Response Time P95** (Gauge)
   - Query: P95 latency últimas 1h
   - Green: < 200ms, Yellow: 200-500ms, Red: > 500ms

3. **Error Rate** (Big Number)
   - Query: Percentage de failed requests
   - Threshold: > 1% = warning

4. **Server Response Time** (Time Chart)
   - Metric: App Service response time
   - Agregación: Average, P95, Max

5. **Failed Requests** (Table)
   - Query: Top 20 failed requests con detalles
   - Columnas: timestamp, endpoint, status code, duration

6. **Availability** (Percentage)
   - Metric: Uptime percentage
   - SLO target: 99.9%

7. **SQL DTU Usage** (Line Chart)
   - Metric: SQL Database DTU consumption
   - Threshold: > 80% = alert

8. **Dependency Health** (Stacked Bar Chart)
   - Query: Success rate por dependency type
   - Types: SQL, Key Vault, HTTP

**Creación manual en Azure Portal**:
```
Dashboard → Create → Blank Dashboard
Add Tile → Metrics Explorer (para App Service, SQL)
Add Tile → Logs (para Application Insights KQL queries)
Save → Pin to favorites
```

---

### ✅ Paso 4: Alertas Configuradas

**Action Group creado**:
- **Name**: ag-kitten-missions-dev
- **Short Name**: KittenOps
- **Email**: f.Elkourti_Useroffice365.onmicrosoft.com#EXT#@certones.onmicrosoft.com
- **Resource ID**: ✅ Configurado

**Alertas configuradas** (4 alertas críticas):

| # | Alerta | Condición | Ventana | Frecuencia | Severidad |
|---|--------|-----------|---------|------------|-----------|
| 1 | High-Error-Rate-Alert | HTTP 5xx > 10 | 5min | 1min | Sev 0 (Critical) |
| 2 | High-Response-Time-Alert | Avg duration > 500ms | 10min | 5min | Sev 2 (Warning) |
| 3 | AppService-High-CPU-Alert | CPU > 80% | 10min | 5min | Sev 2 (Warning) |
| 4 | SQL-High-DTU-Alert | DTU > 80% | 10min | 5min | Sev 2 (Warning) |

**Severidad**:
- **Sev 0** (Critical): Requiere acción inmediata (errores de usuario)
- **Sev 2** (Warning): Requiere investigación (performance degradation)

**Auto-mitigate**: ✅ Habilitado (cierra alerta automáticamente cuando condición se resuelve)

**Cómo probar alertas**:
```bash
# Generar carga en App Service para disparar alerta
for i in {1..100}; do curl https://app-kitten-missions-dev.azurewebsites.net; done
```

---

### ✅ Paso 5: Diagnostic Settings Verificados

**App Service Logs habilitados**:
- ✅ AppServiceHTTPLogs
- ✅ AppServiceConsoleLogs
- ✅ AppServiceAppLogs
- ✅ AppServicePlatformLogs

**Destino**: Log Analytics Workspace (log-kitten-missions-dev)

**SQL Database Logs habilitados**:
- ✅ SQLInsights
- ✅ AutomaticTuning
- ✅ QueryStoreRuntimeStatistics
- ✅ QueryStoreWaitStatistics
- ✅ Errors
- ✅ DatabaseWaitStatistics
- ✅ Timeouts
- ✅ Blocks
- ✅ Deadlocks

---

## 📈 SRE Golden Signals Configurados

| Signal | Métrica | Query/Alerta | Estado |
|--------|---------|--------------|--------|
| **Latency** | Response Time P95 | Query KQL + Alerta > 500ms | ✅ |
| **Traffic** | Requests/min | Query KQL | ✅ |
| **Errors** | Error Rate % | Query KQL + Alerta > 10 errors | ✅ |
| **Saturation** | CPU, DTU Usage | Alertas > 80% | ✅ |

---

## 💡 Observability Best Practices Implementadas

1. ✅ **Distributed Tracing**: Application Insights configurado
2. ✅ **Structured Logging**: Diagnostic settings habilitados
3. ✅ **Metrics Collection**: CPU, Memory, DTU, Response Time
4. ✅ **Alerting**: 4 alertas críticas configuradas
5. ✅ **Dashboard**: Queries KQL listas para visualización
6. ✅ **Dependency Tracking**: SQL, Key Vault monitoreados

---

## 🎯 Próximos Pasos

### Inmediatos (Post-Activity 07)
1. **Verificar email de confirmación**: Validar que Action Group envió email de activación
2. **Ejecutar queries KQL**: Probar las 10 queries en Application Insights Logs
3. **Crear dashboard manual**: Usar queries para crear dashboard visual

### Activity 08 - Testing & Deployment
- Desplegar API de prueba al App Service
- Ejecutar load testing
- Validar que alertas se disparan correctamente
- Revisar telemetry en Application Insights

---

## 📸 Evidencias Recomendadas

1. Screenshot de Application Insights Overview
2. Screenshot de Logs ejecutando una query KQL
3. Screenshot de Alerts configuradas (4 alertas)
4. Screenshot de Action Group con email configurado
5. Screenshot de Dashboard (si se crea)

---

## 🔗 URLs Útiles

**Application Insights**:
- Portal: https://portal.azure.com/#@certones.onmicrosoft.com/resource/subscriptions/d0c6d1b0-6b0a-4b6e-9ec1-85ff1ab0859d/resourceGroups/rg-kitten-missions-dev/providers/microsoft.insights/components/appi-kitten-missions-dev
- Logs: Click en "Logs" en blade izquierdo
- Live Metrics: Click en "Live Metrics" para telemetría en tiempo real

**Azure Monitor Alerts**:
- Portal: https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/alertsV2

**Dashboard**:
- Portal: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Portal%2Fdashboards

---

## ✅ Entregables Completados

- [x] Application Insights explorado y configurado
- [x] 10 queries KQL esenciales creadas
- [x] Dashboard conceptual diseñado (manual pendiente)
- [x] 4 alertas críticas configuradas
- [x] Action Group para notificaciones creado
- [x] Diagnostic settings verificados

---

**Activity 07 Status**: ✅ COMPLETADO  
**Tiempo total**: ~20 minutos  
**Siguiente actividad**: Activity 08 - Testing & Deployment

---

## 🎓 Lecciones Aprendidas

1. **KQL es poderoso**: Queries complejas en pocas líneas
2. **Percentiles > Averages**: Usar P95/P99 para latency, no average
3. **Alertas granulares**: Mejor 4 alertas específicas que 1 alerta genérica
4. **Auto-mitigate**: Reduce ruido de alertas que se auto-resuelven
5. **SRE Golden Signals**: Framework probado para observability (Latency, Traffic, Errors, Saturation)

---

**Report Generated**: 2026-01-23  
**By**: Azure Architect Pro Agent  
**Workshop**: Kitten Space Missions
