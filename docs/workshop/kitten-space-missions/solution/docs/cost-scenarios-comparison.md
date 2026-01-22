# 💰 Comparativa de Escenarios de Costos - Kitten Space Missions API

**Fecha**: 22 Enero 2026  
**Región**: West Europe  
**Budget Objetivo**: $70-80/mes

---

## 📊 Tabla Comparativa - 3 Escenarios

| **Aspecto** | **Scenario A: Ultra-Económico** | **Scenario B: Balanceado** | **Scenario C: Production-Ready** |
|-------------|--------------------------------|---------------------------|----------------------------------|
| **🎯 Objetivo** | PoC/Prototipo rápido | **Dev estable y sostenible** | Pre-producción / Producción |
| | | | |
| **INFRAESTRUCTURA** | | | |
| **App Service Plan** | F1 Free (Shared) | B1 Basic | B2 Basic |
| └─ vCPU | 1 vCPU (60 min/día) | 1 core | 2 cores |
| └─ RAM | 1 GB | 1.75 GB | 3.5 GB |
| └─ Storage | 1 GB | 10 GB | 10 GB |
| └─ Auto-scaling | ❌ No | ✅ Yes (1-3 inst) | ✅ Yes (1-10 inst) |
| └─ Always On | ❌ No | ✅ Yes | ✅ Yes |
| └─ **Costo** | **$0.00** | **$12.50** | **$25.00** |
| | | | |
| **Azure SQL Database** | Basic | Basic | Standard S0 |
| └─ Storage | 2 GB | 2 GB | 250 GB |
| └─ DTU | 5 | 5 | 10 |
| └─ Geo-replication | ❌ No | ❌ No | ✅ Available |
| └─ Point-in-time restore | 7 días | 7 días | 35 días |
| └─ **Costo** | **$4.60** | **$4.60** | **$14.70** |
| | | | |
| **Key Vault** | Standard | Standard | Standard |
| └─ Operations | 10K/mes | 50K/mes | 200K/mes |
| └─ **Costo** | **$0.03** | **$0.03** | **$0.03** |
| | | | |
| **Application Insights** | Free tier (5GB) | 50% sampling | Full telemetry |
| └─ Data ingestion | < 1 GB/mes | ~3 GB/mes | ~8 GB/mes |
| └─ Retention | 90 días | 90 días | 90 días |
| └─ **Costo** | **$0.00** | **$1.50** | **$4.50** |
| | | | |
| **Log Analytics** | Free tier (5GB) | 7 días retention | 30 días retention |
| └─ Data ingestion | < 1 GB/mes | ~1 GB/mes | ~5 GB/mes |
| └─ **Costo** | **$0.00** | **$0.50** | **$2.50** |
| | | | |
| **VNet + NSG** | Standard | Standard | Standard + Firewall |
| └─ Subnets | 2 subnets | 3 subnets | 4+ subnets |
| └─ **Costo** | **$0.00** | **$0.00** | **$15.00** (con Firewall) |
| | | | |
| **Private Endpoint** | ❌ No | ❌ No (firewall rules) | ✅ Yes (2 endpoints) |
| └─ Endpoints | 0 | 0 | 2 (SQL + KeyVault) |
| └─ **Costo** | **$0.00** | **$0.00** | **$14.60** |
| | | | |
| **Backup & DR** | ❌ No | SQL auto-backup only | Full backup strategy |
| └─ Recovery Services | No | No | Yes |
| └─ Geo-redundancy | No | No | Yes |
| └─ **Costo** | **$0.00** | **$0.00** | **$8.00** |
| | | | |
| **Monitoring Avanzado** | ❌ No | Básico | Avanzado (dashboards) |
| └─ Custom dashboards | No | 1 básico | 3 dashboards |
| └─ Alert rules | 0 | 5 alerts | 20+ alerts |
| └─ **Costo** | **$0.00** | **$0.00** | **$1.00** |
| | | | |
| **🔒 SEGURIDAD** | | | |
| Network Security | NSG básico | NSG + Firewall rules | Private Network + WAF |
| Azure AD Auth | ✅ Yes | ✅ Yes | ✅ Yes |
| TDE (Encryption) | ✅ Yes | ✅ Yes | ✅ Yes + CMK |
| Private Endpoints | ❌ No | ❌ No | ✅ Yes |
| **Security Score** | **4/10** 🔴 | **7/10** 🟡 | **10/10** 🟢 |
| | | | |
| **📈 PERFORMANCE** | | | |
| Latency p95 SLA | ❌ No SLA | ✅ < 200ms | ✅ < 100ms |
| Auto-scaling | ❌ No | ✅ 1-3 instances | ✅ 1-10 instances |
| Cold starts | 🔴 10-15 seg | 🟢 < 1 seg | 🟢 < 1 seg |
| Concurrent requests | ~10 (CPU limit) | ~100 | ~500+ |
| Database DTU | 5 (básico) | 5 (suficiente dev) | 10 (producción) |
| | | | |
| **💰 COSTOS** | | | |
| **Costo Mensual** | **$4.63** | **$19.13** | **$85.33** |
| **Costo Anual** | **$55.56** | **$229.56** | **$1,023.96** |
| **Con Reserved (1yr)** | N/A | $183.65 (20% off) | $818.37 (20% off) |
| **Con Reserved (3yr)** | N/A | $137.74 (40% off) | $614.38 (40% off) |
| | | | |
| **vs Budget $80/mes** | ✅ **94% bajo** | ✅ **76% bajo** | ⚠️ **6% sobre** |
| **% del Budget** | 6% | 24% | 106% |
| | | | |

---

## 🚦 Limitaciones por Escenario

### ❌ Scenario A: Ultra-Económico ($4.63/mes)

#### Limitaciones Críticas

1. **❌ CPU Quota de 60 minutos/día**
   - App Service F1 tiene límite de 60 min CPU por día
   - Después de consumir la cuota, la app se pausa hasta el siguiente día
   - **BLOCKER** para API que debe estar disponible 24/7

2. **❌ Sin Auto-scaling**
   - Máximo 1 instancia (no puede escalar)
   - Si hay pico de tráfico → requests fallan o timeout
   - **BLOCKER** para requisito de auto-scaling 1-3 instancias

3. **❌ Cold Starts de 10-15 segundos**
   - Sin "Always On" → app se duerme tras inactividad
   - Primera request después de inactividad tarda 10-15 seg
   - **BLOCKER** para SLA de latency p95 < 200ms

4. **❌ No Custom Domains ni SSL gratuito**
   - Solo puede usar `*.azurewebsites.net`
   - **BLOCKER** si necesitas dominio custom

5. **⚠️ Deployment Slots no disponibles**
   - No puedes hacer blue-green deployments
   - Mayor riesgo en CI/CD

6. **⚠️ Storage limitado (1 GB App + 2 GB SQL)**
   - Poco margen para logs, assets, datos
   - Requiere monitoreo constante

#### Cuándo Usar Scenario A

✅ **SOLO para**:
- Demos de 1-2 horas
- Prototipos throwaway (< 1 semana vida)
- Tutoriales educativos sin tráfico real
- Validación de concepto rápida

❌ **NO usar para**:
- Desarrollo estable (> 1 semana)
- Testing de performance/carga
- APIs con SLA de disponibilidad
- Integración con CI/CD
- Cualquier escenario productivo

---

### ✅ Scenario B: Balanceado ($19.13/mes) - **RECOMENDADO PARA DEV**

#### Limitaciones Aceptables

1. **⚠️ SQL Storage de 2 GB**
   - Suficiente para datos de prueba (miles de registros)
   - Requiere monitoreo mensual
   - **Mitigación**: Alert cuando uso > 80%

2. **⚠️ No Geo-Redundancy**
   - Single region (West Europe)
   - RPO: ~1 hora (auto-backups cada hora)
   - **Aceptable** para dev, NO para prod

3. **⚠️ Sin Private Endpoints**
   - Conectividad via firewall rules + Azure AD auth
   - Security score 7/10 (suficiente para dev sin datos reales)
   - **Mitigación**: Whitelist IPs, TLS 1.2, TDE encryption

4. **⚠️ Monitoring con sampling 50%**
   - Solo captura 50% de telemetry
   - Suficiente para detectar problemas
   - **Trade-off**: Ahorra $1.50/mes vs captura completa

5. **⚠️ Log retention 7 días**
   - Logs más antiguos se eliminan
   - **Mitigación**: Export críticos a storage si necesario

#### Ventajas vs Scenario A

- ✅ Always On → sin cold starts
- ✅ Auto-scaling 1-3 instancias
- ✅ CPU ilimitado (sin cuota 60min)
- ✅ Custom domains + SSL gratuito
- ✅ Deployment slots (staging + production)
- ✅ CI/CD compatible
- ✅ Cumple SLA latency < 200ms
- ✅ 76% bajo presupuesto → margen para crecer

#### Cuándo Usar Scenario B

✅ **IDEAL para**:
- ✅ **Desarrollo estable de larga duración**
- ✅ Entorno dev/test con CI/CD
- ✅ APIs internas sin datos sensibles
- ✅ MVP con tráfico moderado (< 10K requests/día)
- ✅ Proyectos con budget limitado ($20-30/mes)
- ✅ Learning projects serios

❌ **NO usar para**:
- Producción con datos sensibles (usar Scenario C)
- Alto tráfico (> 50K requests/día)
- Compliance estricto (GDPR, HIPAA) → requiere PE

---

### 🚀 Scenario C: Production-Ready ($85.33/mes)

#### Limitaciones

1. **💰 Costo 4.5x vs Scenario B**
   - $85/mes vs $19/mes
   - Requiere justificación ROI clara
   - **6% sobre budget** de $80/mes → requiere aprobación

2. **🔧 Complejidad operativa mayor**
   - Private Endpoints requieren DNS privado
   - Firewall rules más estrictos
   - Más componentes = más mantenimiento

3. **⚠️ Overkill para entorno dev**
   - Muchas features (geo-replication, DR) innecesarias en dev
   - Better investment: usar Scenario B dev + Scenario C prod

#### Ventajas vs Scenario B

- ✅ **Double CPU/RAM** (B2 vs B1)
- ✅ **50x más storage SQL** (250 GB vs 2 GB)
- ✅ **Private Network** (score 10/10 seguridad)
- ✅ **Full telemetry** (sin sampling)
- ✅ **Geo-redundancy** disponible
- ✅ **35 días restore** vs 7 días
- ✅ **Azure Firewall** para egress control
- ✅ **WAF** (Web Application Firewall) opcional
- ✅ **Disaster Recovery** completo

#### Cuándo Usar Scenario C

✅ **IDEAL para**:
- ✅ **Producción con tráfico real**
- ✅ Datos sensibles / compliance (GDPR, HIPAA, PCI-DSS)
- ✅ SLA 99.9%+ contractual
- ✅ Alto tráfico (> 100K requests/día)
- ✅ Enterprise customers
- ✅ Multi-tenant SaaS production
- ✅ Pre-producción que simula prod

❌ **Overkill para**:
- Desarrollo/testing
- MVPs sin tráfico
- Internal tools
- PoCs y demos

---

## 🎯 Recomendación por Fase del Proyecto

### Fase 1: Prototipo (Semana 1-2)
```
Scenario A ($4.63/mes) - SOLO si necesitas zero-cost demo
⚠️ Limitaciones severas, no recomendado

MEJOR: Scenario B por $19/mes → inversión mínima, sin blockers
```

### Fase 2: Desarrollo Activo (Mes 1-3)
```
✅ Scenario B ($19.13/mes) - RECOMENDADO
- Estable, sin surpresas
- CI/CD funcional
- Auto-scaling para testing
- 76% bajo presupuesto
```

### Fase 3: Pre-Producción (Mes 4)
```
✅ Scenario C ($85/mes) - Pre-prod environment
- Simula producción real
- Testing de seguridad
- Load testing con auto-scale
- Requiere aprobación (6% sobre budget)
```

### Fase 4: Producción
```
✅ Scenario C ($85-105/mes) - Production environment
+ Considerar Reserved Instances (20-40% ahorro)
+ Multi-region si global audience
+ Monitoring 24/7 con on-call
```

---

## 💡 Estrategia Multi-Entorno (Recomendación Final)

### Opción A: Solo Dev (Budget $80/mes)

```yaml
Environments:
  dev: Scenario B ($19.13/mes)

Total: $19.13/mes
Budget Remaining: $60.87/mes (76%)
```

**Ventajas**:
- ✅ Máximo margen de seguridad
- ✅ Budget para experimentación
- ✅ Puede agregar features/monitoreo

**Desventajas**:
- ❌ No hay staging/pre-prod
- ❌ Deploys directos a prod (riesgoso)

---

### Opción B: Dev + Staging (Budget $80/mes)

```yaml
Environments:
  dev:     Scenario B ($19.13/mes)
  staging: Scenario B ($19.13/mes)

Total: $38.26/mes
Budget Remaining: $41.74/mes (52%)
```

**Ventajas**:
- ✅ Testing en staging antes de prod
- ✅ Blue-green deployments
- ✅ Aún 52% bajo presupuesto

**Desventajas**:
- ⚠️ Staging no es idéntico a prod (si prod usa Scenario C)

---

### Opción C: Dev + Pre-Prod (REQUIERE APROBACIÓN)

```yaml
Environments:
  dev:      Scenario B ($19.13/mes)
  pre-prod: Scenario C ($85.33/mes)

Total: $104.46/mes
Budget Exceeded: +$24.46/mes (31% sobre)
```

**Requiere**:
- ⚠️ Aprobación para exceder budget
- ⚠️ Justificación ROI clara
- ⚠️ Commitment de pasar a prod en < 3 meses

---

## 📊 Calculadora de ROI - Reserved Instances

### Scenario B - Reserved 1 año

```
Precio On-Demand:  $19.13/mes × 12 = $229.56/año
Precio Reserved:   $183.65/año (20% descuento)
Ahorro anual:      $45.91

ROI: 20%
Break-even: 12 meses
```

**Recomendación**: ✅ Comprar Reserved si proyecto > 1 año

---

### Scenario C - Reserved 3 años

```
Precio On-Demand:  $85.33/mes × 36 = $3,071.88 (3 años)
Precio Reserved:   $614.38 × 3 = $1,843.14 (3 años)
Ahorro total:      $1,228.74

ROI: 40%
Break-even: 36 meses
```

**Recomendación**: ✅ Comprar Reserved 3yr si production estable

---

## 🎯 Decisión Final Recomendada

### Para Workshop Kitten Space Missions:

```yaml
✅ DECISIÓN: Scenario B - Balanceado

Justificación:
  - Costo: $19.13/mes (76% bajo presupuesto $80/mes)
  - Cumple todos los requisitos técnicos
  - Sin blockers de F1 Free
  - Margen para agregar features
  - Path claro de migración a Scenario C (prod)

Environment: dev
Budget: ✅ $19.13 de $80.00 (24% usage)
Security: 7/10 (suficiente para dev)
Performance: ✅ Cumple SLA latency
Auto-scaling: ✅ 1-3 instances
Status: ✅ APROBADO PARA DESPLIEGUE
```

---

## 📝 Action Items

- [ ] **Aprobar Scenario B** para despliegue dev
- [ ] **Configurar budget alert** $70/mes (80% de $80 + margen)
- [ ] **Implementar tags** de cost allocation
- [ ] **Review mensual** de costos reales vs estimado
- [ ] **Planear upgrade** a Scenario C cuando vaya a prod
- [ ] **Considerar Reserved Instance** si commitment > 1 año

---

**Fecha próxima revisión**: 22 Febrero 2026  
**Owner**: Engineering Team  
**Aprobadores**: FinOps Manager, Engineering Lead
