# 📊 KQL Queries - Kitten Space Missions Monitoring

**Application Insights**: appi-kitten-missions-dev  
**Fecha**: 2026-01-23

---

## 1️⃣ Request Rate (Requests/min - Últimas 24h)

```kql
requests
| where timestamp > ago(24h)
| summarize RequestCount = count() by bin(timestamp, 5m)
| render timechart 
```

**Uso**: Monitorear tráfico general de la aplicación  
**Threshold**: Alertar si < 1 req/min por > 30min (posible downtime)

---

## 2️⃣ Response Time P95 por Endpoint

```kql
requests
| where timestamp > ago(1h)
| summarize 
    p50 = percentile(duration, 50),
    p95 = percentile(duration, 95),
    p99 = percentile(duration, 99),
    count = count()
by name
| order by p95 desc
| render barchart
```

**Uso**: Identificar endpoints lentos  
**Threshold**: P95 > 500ms requiere optimización  
**Threshold crítico**: P95 > 2000ms (alertar)

---

## 3️⃣ Error Rate (HTTP 5xx)

```kql
requests
| where timestamp > ago(1h)
| summarize 
    TotalRequests = count(), 
    FailedRequests = countif(success == false),
    HTTP5xx = countif(resultCode startswith "5")
| extend ErrorRate = (FailedRequests * 100.0) / TotalRequests
| project ErrorRate, TotalRequests, FailedRequests, HTTP5xx
```

**Uso**: Calcular tasa de errores  
**Threshold**: Error rate > 1% = Warning  
**Threshold crítico**: Error rate > 5% = Critical

---

## 4️⃣ Top 10 Endpoints Más Lentos

```kql
requests
| where timestamp > ago(24h)
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    MaxDuration = max(duration)
by name
| order by P95Duration desc
| take 10
| project 
    Endpoint = name,
    Requests = RequestCount,
    AvgMs = round(AvgDuration, 2),
    P95Ms = round(P95Duration, 2),
    MaxMs = round(MaxDuration, 2)
```

**Uso**: Priorizar optimizaciones de performance  
**Acción**: Investigar endpoints con P95 > 500ms

---

## 5️⃣ Failed Requests con Detalles

```kql
requests
| where timestamp > ago(1h)
| where success == false
| project 
    timestamp,
    name,
    resultCode,
    duration,
    url,
    clientIP = client_IP,
    operationId = operation_Id
| order by timestamp desc
| take 50
```

**Uso**: Debug de errores específicos  
**Columnas clave**:
- `operationId`: Para correlacionar con traces/exceptions
- `resultCode`: HTTP status (400, 401, 500, etc.)
- `url`: Full request URL con query params

---

## 6️⃣ Dependency Calls (SQL, Key Vault, HTTP)

```kql
dependencies
| where timestamp > ago(1h)
| summarize 
    CallCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    SuccessRate = (countif(success == true) * 100.0) / count()
by name, type
| order by P95Duration desc
| project 
    Dependency = name,
    Type = type,
    Calls = CallCount,
    AvgMs = round(AvgDuration, 2),
    P95Ms = round(P95Duration, 2),
    SuccessRate = round(SuccessRate, 2)
```

**Uso**: Monitorear dependencias externas (SQL, Key Vault, APIs)  
**Threshold SQL**: P95 > 100ms (revisar queries)  
**Threshold Key Vault**: P95 > 50ms (revisar caching)

---

## 7️⃣ SQL Slow Queries

```kql
dependencies
| where type == "SQL"
| where timestamp > ago(1h)
| where duration > 1000  // > 1 segundo
| project 
    timestamp,
    name,
    duration,
    data,
    success,
    resultCode
| order by duration desc
| take 20
```

**Uso**: Identificar queries SQL lentas  
**Acción**: Optimizar índices, revisar query plan

---

## 8️⃣ Exceptions y Errores

```kql
exceptions
| where timestamp > ago(24h)
| summarize 
    ExceptionCount = count(),
    UniqueUsers = dcount(user_Id)
by type, outerMessage
| order by ExceptionCount desc
| take 20
| project 
    ExceptionType = type,
    Message = outerMessage,
    Count = ExceptionCount,
    AffectedUsers = UniqueUsers
```

**Uso**: Tracking de excepciones no manejadas  
**Acción**: Priorizar por `Count` y `AffectedUsers`

---

## 9️⃣ Availability Monitoring

```kql
availabilityResults
| where timestamp > ago(7d)
| summarize 
    TotalTests = count(),
    SuccessfulTests = countif(success == true),
    AvailabilityPct = (countif(success == true) * 100.0) / count()
by bin(timestamp, 1h), location
| render timechart
```

**Uso**: Monitorear uptime desde múltiples locations  
**SLO Target**: 99.9% availability (8.76h downtime/año)

---

## 🔟 Custom Telemetry (Cuando se despliegue API)

```kql
customMetrics
| where timestamp > ago(1h)
| where name in ("mission.launch", "mission.success", "mission.failure")
| summarize count() by name, bin(timestamp, 5m)
| render timechart
```

**Uso**: Métricas de negocio específicas de Kitten Missions  
**Ejemplos**: Launches, success rate, rocket failures

---

## 📊 Dashboard Query - Overview Panel

```kql
// Multi-metric overview
let timeRange = 1h;
let requests_summary = requests
| where timestamp > ago(timeRange)
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    ErrorCount = countif(success == false);
let dependencies_summary = dependencies
| where timestamp > ago(timeRange)
| summarize DependencyCount = count();
requests_summary
| extend Dependencies = toscalar(dependencies_summary | project DependencyCount)
| project 
    Requests = RequestCount,
    AvgResponseMs = round(AvgDuration, 2),
    Errors = ErrorCount,
    Dependencies
```

**Uso**: Single-view de métricas clave para dashboard

---

## 🚨 Alert Queries

### High Error Rate Alert
```kql
requests
| where timestamp > ago(5m)
| summarize 
    Total = count(),
    Failed = countif(success == false)
| where Failed > 10  // Más de 10 errores en 5min
```

### High Response Time Alert
```kql
requests
| where timestamp > ago(10m)
| summarize P95 = percentile(duration, 95)
| where P95 > 500  // P95 > 500ms
```

### SQL High Duration Alert
```kql
dependencies
| where type == "SQL"
| where timestamp > ago(5m)
| summarize AvgDuration = avg(duration)
| where AvgDuration > 200  // Avg > 200ms
```

---

## 💡 Tips para Queries KQL

1. **Rendimiento**: Usa `| where timestamp > ago(Xh)` al inicio para filtrar temprano
2. **Aggregations**: `summarize` es tu mejor amigo para métricas
3. **Percentiles**: Usa p50, p95, p99 en vez de `avg()` para latency
4. **Visualización**: `| render timechart` / `barchart` / `piechart`
5. **Debugging**: `| take 10` para limitar resultados mientras pruebas
6. **Joins**: Usa `operation_Id` para correlacionar requests → dependencies → exceptions

---

## 🔗 Referencias

- [KQL Quick Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)
- [Application Insights Data Model](https://learn.microsoft.com/azure/azure-monitor/app/data-model)
- [SRE Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/)

