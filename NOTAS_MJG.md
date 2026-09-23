# NOTAS_MJG — Contexto de trabajo activo
# Tesis: Transportes Anillares y su importancia en la CDMX y ZMVM
# Actualizado: 2026-09-21

---

## Dos líneas de trabajo en paralelo

### Línea A — Diagnóstico de la red actual (baseline)
**Objetivo:** visualizar el estado real de la red de transporte ZMVM con la
Clasificación Garibelt (5 dimensiones) en Tableau y QGIS.

**Estado:** en progreso — GeoJSONs listos, CSVs pendientes de exportar.

**Recursos disponibles (baseline, ya generados):**
```
tableau/exports/geo/b_puntos.geojson           2,000 nodos  — betweenness B(v)
tableau/exports/geo/fc_puntos.geojson          10,537 nodos — fuerza capilar Cᵢ
tableau/exports/geo/df_puntos.geojson          200 rutas    — detour factor DI
tableau/connectors/VFTModel/exports/
  cobertura_por_alcaldia.geojson               16 alcaldías — cobertura 800m
  cobertura_800m.geojson                       cobertura espacial
  df_por_alcaldia.geojson                      DI por alcaldía
```

**Recursos pendientes (Línea A):**
```
tableau/exports/data/garibelt/
  b_ranking_baseline.csv          ← export_garibelt_csv.py  (hoy, sin servidor)
  fc_distribucion_baseline.csv    ← export_garibelt_csv.py  (hoy, sin servidor)
  df_distribucion_baseline.csv    ← export_garibelt_csv.py  (hoy, sin servidor)
  cobertura_alcaldias_baseline.csv← export_garibelt_csv.py  (hoy, sin servidor)
  garibelt_perfil_baseline.csv    ← export_garibelt_csv.py  (post-warmup, llama API)

tableau/workbooks/
  dashboard_viz05_garibelt.twb    ← crear en Tableau Desktop (6 hojas)

data/processed/scenarios/
  perfil_nodos_baseline.geojson   ← Fase B.1, post-warmup + fix VFTModel
```

**Hojas Tableau planeadas para dashboard_viz05_garibelt.twb:**
1. Espectro Garibelt — barras horizontales 5 dim, color por banda
2. Cobertura por demarcación — barras ordenadas, color por banda
3. Distribución DI — histograma con zonas de banda de fondo
4. Distribución Cᵢ — histograma/box con Q1/mediana/Q3
5. Ranking B(v) — top-20 nodos, color por sistema/alcaldía
6. T vs referencia — barra simple vs referencia CDMX 85 min
7. [PLACEHOLDER] Banda dominante por nodo — scatter 11,115 nodos (espera perfil_nodos)

---

### Línea B — Análisis comparativo 3 escenarios
**Objetivo:** comparar el impacto del Anillo Periférico (MB y METRO) vs la red
actual sobre los 5 indicadores Garibelt.

**Estado:** bloqueado — esperando que terminen los warmups (~55 min).
Los ProfileCache de los 3 escenarios deben estar activos antes de Fase B.

**Prerequisito:** `make warmup-all` corriendo. Al terminar verificar con:
```bash
make verify-step-2
```

**Recursos pendientes (Línea B), en orden de ejecución:**
```
Fase B.1 — perfil_nodos.geojson × 3 escenarios
  → añadir a generate_exports.py + make export-garibelt-all

Fase B.2 — garibelt_comparativo.csv (15 filas: 3 escenarios × 5 dimensiones)
  → utils/build_garibelt_csv.py (script nuevo)

Fase B.3 — Makefile: export-garibelt-baseline/mb/metro, export-garibelt-all
  → añadir al Makefile raíz

Fase C — dashboard_viz05_comparativo.twb
  → 3 hojas: espectro comparativo, tabla MJG × escenario, delta mejora

Fase D — QGIS mapas banda dominante × 3 escenarios
  → vft_indicadores.qgz: 3 layouts con Atlas, paleta Garibelt
```

---

## Datos de referencia fijos

| Indicador | Baseline | MB (BRT) | METRO | Δ MB | Δ METRO |
|-----------|----------|----------|-------|------|---------|
| T (min)   | 108.9169 | 104.7385 | 98.1217 | −4.18 | −10.80 |
| Nodos     | 11,115   | 11,209   | 11,209  | +94   | +94    |
| Líneas    | 668      | 676      | 676     | +8    | +8     |
| SCC giant | 10,561   | TBD      | TBD     | —     | —      |

**Scores Garibelt baseline** (del ProfileCache activo):
| Dimensión | Valor bruto | Normalizado | Banda |
|-----------|-------------|-------------|-------|
| Accesibilidad (C) | 4.41% | 0.055 | 🔴 crítico |
| Capilar (Cᵢ) | mediana=7.0 | 0.250 | 🟠 débil |
| Eficiencia (DI) | mediana=1.43 | 0.713 | 🔵 aceptable |
| Fluidez (T) | 108.9 min | 0.748 | 🔵 aceptable |
| Centralidad (B) | Gini=0.789 | 0.211 | 🔴 crítico |

---

## Comandos de referencia

```bash
# Verificar estado del pipeline completo
make verify

# Exportar CSVs Garibelt baseline (sin servidor)
python3 utils/export_garibelt_csv.py --scenario baseline

# Exportar CSVs + perfil_nodos cuando warmup esté listo
python3 utils/export_garibelt_csv.py --scenario baseline --include-api
python3 utils/export_garibelt_csv.py --scenario scenario_mb --include-api
python3 utils/export_garibelt_csv.py --scenario scenario_metro --include-api

# Verificar que ProfileCache Garibelt está activo
make verify-step-2
```

---

## Notas metodológicas a documentar en la tesis

- **554 nodos aislados (4.98%):** fuera del SCC gigante, sin B(v). Su `banda_dominante`
  se calcula solo con `fc_normalizado`. Metodológicamente correcto: son estaciones sin
  rol de intermediación en la red multimodal conectada.
- **Cobertura 4.41%:** score extremadamente bajo porque el radio peatonal 800m no cubre
  la mayor parte del territorio ZMVM (área muy extensa). Ver distribución por alcaldía.
- **B(v) Gini=0.789:** alta concentración — Tacubaya domina con B=0.2179. Top nodo
  vulnerable estructural de la red.
