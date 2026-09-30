# tableau/

Módulo de dashboards estadísticos interactivos para la tesis **"Transportes Anillares y su importancia en la CDMX y ZMVM"**.

---

## División de responsabilidades

| Herramienta | Fuente de datos | Qué produce |
|-------------|----------------|-------------|
| **QGIS** | `.gpkg` en `data/processed/` | Mapas cartográficos (PDF/PNG para tesis y coloquio) |
| **Tableau** | API VFTModel + Apimetro directamente vía WDC | Dashboards estadísticos interactivos |

Tableau **no consume `.gpkg`** ni requiere scripts Python intermedios.
La conexión es nativa a través de **Web Data Connectors (WDC)** que llaman directamente a las APIs.

---

## Estructura

```
tableau/
  connectors/         ← WDC: archivos HTML+JS (git-tracked)
    vftmodel_wdc.html   ← conecta a VFTModel (localhost:8000)
    apimetro_wdc.html   ← conecta a Apimetro (localhost:8080)
  workbooks/          ← .twb (XML, git-tracked)
  datasources/        ← .tds definiciones de conexión (XML, git-tracked)
  extracts/           ← .hyper (gitignored, opcionales para performance)
  exports/
    pdf/              ← PDFs exportados desde Tableau (git-tracked)
    img/              ← PNGs exportados (git-tracked)
    web/              ← URLs Tableau Public o snippets de embed (git-tracked)
  scripts/
    export_tabcmd.sh  ← automatización de exports con tabcmd
  README.md
```

---

## Flujo de datos

```
VFTModel (FastAPI · localhost:8000)
    │
    └─► vftmodel_wdc.html  ──┐
                              ├─►  Tableau Desktop  ──►  .twb workbooks
Apimetro (Gin · localhost:8080) │                         │
    │                          │                          ▼
    └─► apimetro_wdc.html  ──┘                      exports/
                                                     pdf/ · img/ · web/
```

El WDC corre en el browser embebido de Tableau Desktop (Chromium).
Llama a las APIs, descarta la geometría de los GeoJSON, y entrega las `properties`
como filas de tablas planas directamente a Tableau.

---

## Cómo conectar Tableau a las APIs

### Prerrequisitos

1. **Apimetro corriendo**: `cd ../apimetro && go run cmd/main.go`
   — ya tiene CORS habilitado (`AllowOrigins: ["*"]`).

2. **VFTModel corriendo**: `cd ../VFTModel && uvicorn src.api.main:app --reload`
   — **requiere CORS habilitado** (ver nota abajo).

3. **Tableau Desktop** instalado (versión 2020.4+ para soporte de WDC 2.0).

> **Nota VFTModel CORS**: el `main.py` de VFTModel no incluye `CORSMiddleware`.
> El browser embebido de Tableau bloqueará las llamadas si no está habilitado.
> Antes de conectar, agregar en `VFTModel/src/api/main.py`:
> ```python
> from fastapi.middleware.cors import CORSMiddleware
> app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET"])
> ```

### Pasos en Tableau Desktop

1. Abrir Tableau Desktop → **Conectar** → **Más...** → **Conector de datos web**
2. Ingresar la ruta al archivo WDC:
   - VFTModel: `file:///ruta/al/repo/tableau/connectors/vftmodel_wdc.html`
   - Apimetro: `file:///ruta/al/repo/tableau/connectors/apimetro_wdc.html`
3. En el formulario del WDC, ingresar la URL base y seleccionar las tablas a cargar.
4. Hacer clic en **Obtener datos** — Tableau descarga y tabulariza la respuesta.
5. Opcionalmente extraer a `.hyper` para trabajo sin conexión.

---

## Workbooks disponibles

Convención de nombre: `<proyecto>_viz<##>_<descripcion>.twb`

| Archivo | Contenido | Fuente de datos |
|---------|-----------|----------------|
| `dashboard_viz04_red_apimetro.twb` | Estadísticas red Apimetro — baseline | `apimetro_wdc.html` / hyper |
| `dashboard_viz04_red_apimetro_scenario_mb.twb` | Red Apimetro — Escenario MB | hyper MB |
| `dashboard_viz04_red_apimetro_scenario_metro.twb` | Red Apimetro — Escenario METRO | hyper METRO |
| `dashboard_viz04_red_vftmodel.twb` | Indicadores VFTModel — baseline | `vftmodel_wdc.html` / hyper |
| `dashboard_viz04_red_vftmodel_scenario_mb.twb` | VFTModel — Escenario MB | hyper MB |
| `dashboard_viz04_red_vftmodel_scenario_metro.twb` | VFTModel — Escenario METRO | hyper METRO |
| `dashboard_viz05_garibelt_baseline.twb` | Clasificación Garibelt — baseline | CSVs `escenario-base/` |

---

## Exports

Los dashboards se exportan en tres formatos para publicación en el repositorio:

| Formato | Directorio | Método |
|---------|------------|--------|
| PDF | `exports/pdf/` | Tableau Desktop: Archivo → Exportar como PDF |
| Imagen (PNG) | `exports/img/` | Tableau Desktop: Archivo → Exportar como imagen |
| Web | `exports/web/` | Tableau Public (URL) o snippet de embed HTML |

Convención de nombre de exports: `<proyecto>_viz<##>_<descripcion>.<ext>`

Para automatizar con `tabcmd`:
```bash
bash tableau/scripts/export_tabcmd.sh
```

---

## Estado de recursos — PDFs exportados

Leyenda: ✅ generado · ⬜ pendiente · ➖ omitir

### A · Apimetro — estadísticas de red

Destino: `exports/pdf/Apimetro/`

| Recurso | Estado |
|---------|--------|
| Dashboard_Apimetro_2026.pdf | ✅ |
| Dashboard_Apimetro_2026_Red_ZMVM.pdf | ✅ |
| Grafica_Apimetro_2026_Afluencia_Metro_Anual.pdf | ✅ |
| Grafica_Apimetro_2026_Top_10_estaciones.pdf | ✅ |
| Grafica_Dashboard_Apimetro_2026_Calidad_Servicio.pdf | ✅ |

### B · VFTModel — indicadores baseline

Destino: `exports/pdf/VFTModel/`

| Recurso | Estado | Nota |
|---------|--------|------|
| Dashboard Centralidad Intermediación | ✅ | solo baseline |
| Dashboard Factor Desviación | ✅ | solo baseline |
| Dashboard Fuerza Capilar | ✅ | solo baseline |
| Gráfica B(v) Nodos | ✅ | solo baseline |
| Gráfica B(v) por sistema | ✅ | solo baseline |
| Gráfica Cobertura alcaldía | ✅ | solo baseline |
| Gráfica Cobertura sistema | ✅ | solo baseline |
| Gráfica Factor Desviación | ✅ | solo baseline |
| Gráfica Fuerza Capilar | ✅ | solo baseline |
| Gráfica Tiempo Promedio | ✅ | solo baseline |
| PDFs escenario MB | ➖ | cubierto por Garibelt (sección D) |
| PDFs escenario METRO | ➖ | cubierto por Garibelt (sección D) |

### C · Clasificación Garibelt — dashboards por escenario

Destino: `exports/pdf/Clasificacion_Garibelt/{Red_Actual, MB_scenario, Metro_scenario, Comparativo_Base_MB_Metro}/`
Workbook base: `dashboard_viz05_garibelt_baseline.twb`

| Dashboard | Red Actual | Escenario MB | Escenario METRO |
|-----------|-----------|-------------|----------------|
| Dashboard KPI | ✅ | ⬜ | ⬜ |
| Dashboard Clasificación (bandas) | ✅ | ⬜ | ⬜ |
| Dashboard Espectro | ✅ | ⬜ | ⬜ |
| Dashboard Betweenness | ✅ | ⬜ | ⬜ |

Workbooks pendientes de crear: `dashboard_viz05_garibelt_mb.twb` · `dashboard_viz05_garibelt_metro.twb`

### D · Comparativo entre escenarios (pendiente)

Destino: `exports/pdf/Clasificacion_Garibelt/Comparativo_Base_MB_Metro/`
Workbook pendiente: `dashboard_viz06_garibelt_comparativo.twb`

| Dashboard comparativo | Estado | Prioridad |
|-----------------------|--------|-----------|
| ΔBanda Dominante (3 escenarios) | ⬜ | Alta |
| ΔB(v) Baseline → MB → METRO | ⬜ | Alta |
| ΔCobertura por alcaldía | ⬜ | Media |
| KPI comparativo (tabla resumen) | ⬜ | Alta |

---

## Orden de trabajo recomendado

1. **Sección C** — crear `dashboard_viz05_garibelt_mb.twb` y `_metro.twb`, exportar 8 dashboards
2. **Sección D** — crear `dashboard_viz06_garibelt_comparativo.twb`, exportar comparativos
