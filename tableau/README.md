# tableau/

> 📖 La documentación vigente está en la wiki: [Tableau](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Tableau) y [Reglas de rutas](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Reglas-de-rutas). Este README conserva el estado de recursos; algunas secciones de flujo son históricas.

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
  connectors/
    apimetro/apimetro_wdc.html  ← WDC de Apimetro (localhost:8080; escenarios :8083/:8084)
    VFTModel/vft_wdc.html       ← WDC de VFTModel (histórico: viz04 VFTModel lee CSV)
    VFTModel/exports/           ← wdc_*.csv y GeoJSON por escenario (fuentes Live de Tableau y QGIS)
  workbooks/          ← .twb (XML, git-tracked)
  templates/          ← plantilla .twb, paleta .tps y guías de diseño
  geo_proxy/          ← servidor del WDC de Apimetro
  exports/
    pdf/              ← PDFs exportados desde Tableau (git-tracked)
    img/              ← PNGs exportados (git-tracked)
    web/              ← URLs Tableau Public o snippets de embed (git-tracked)
  scripts/
    build_demanda_alcaldia.py  ← genera exports/data/demanda_alcaldia.csv
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
| `dashboard_viz04_red_vftmodel.twb` | Indicadores VFTModel — baseline | `connectors/VFTModel/exports/wdc_*.csv` + GeoJSON (Live, sin WDC ni extractos) |
| `dashboard_viz04_red_vftmodel_scenario_mb.twb` | VFTModel — Escenario MB | ídem `exports/scenario_mb/` (`make workbooks`) |
| `dashboard_viz04_red_vftmodel_scenario_metro.twb` | VFTModel — Escenario METRO | ídem `exports/scenario_metro/` (`make workbooks`) |
| `dashboard_viz05_garibelt_baseline.twb` | Clasificación Garibelt — Red Actual | CSVs `garibelt/escenario-base/` (Live) |
| `dashboard_viz05_garibelt_scenario_mb.twb` | Clasificación Garibelt — Anillo MB | CSVs `garibelt/escenario-mb/` (copia a mano, no `make`) |
| `dashboard_viz05_garibelt_scenario_metro.twb` | Clasificación Garibelt — Anillo Metro | CSVs `garibelt/escenario-metro/` (copia a mano, no `make`) |
| `dashboard_viz05_garibelt_comparativo.twb` | Comparativo Red Actual · MB · Metro | `garibelt/comparativo/kpi_comparativo.csv` y `bv_comparativo.csv` (Live) |

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

Destino: `exports/pdf/Clasificacion_Garibelt/{Red_Actual, MB_scenario, Metro_scenario}/`
Workbooks: `dashboard_viz05_garibelt_baseline.twb`, `_scenario_mb.twb`, `_scenario_metro.twb` (textos fijos por escenario; ver `NOTES/Transport-gis-mjg/ESTADO_RECURSOS.md`)

| Dashboard | Red Actual | Escenario MB | Escenario METRO |
|-----------|-----------|-------------|----------------|
| Dashboard KPI | ✅ | ✅ | ✅ |
| Dashboard Clasificación (bandas) | 🔁 | 🔁 | 🔁 |
| Dashboard Espectro | ✅ | ✅ | ✅ |
| Dashboard Betweenness | 🔁 | 🔁 | 🔁 |

🔁 = re-exportar tras cambiar el Top 10 de B(v) de suma por nombre a **máximo por nodo** (decisión 2026-10-16) y revisar las notas de nodo dominante y multimodales.

### D · Comparativo entre escenarios

Destino: `exports/pdf/Clasificacion_Garibelt/Comparativo_Base_MB_Metro/`
Workbook: `dashboard_viz05_garibelt_comparativo.twb` (solo estadística; sin mapas ni cobertura)

| Recurso | Hojas | Estado |
|---------|-------|--------|
| Dashboard_Comparativo_KPI.pdf | Valor normalizado por dimensión y escenario + Cambio frente a la Red Actual | ✅ |
| Unigrafica_Comparativo_Valor_Normalizado.pdf | Valor normalizado por dimensión y escenario | ✅ |
| Unigrafica_Comparativo_Extendido.pdf | Cambio frente a la Red Actual | ✅ |
| Dashboard_Comparativo_Intermediacion_Bv.pdf | Top 10 B(v) por Nodo + Anillo en el Top | ✅ |
| Unigrafica_Comparativo_Top_10_bv.pdf | Top 10 B(v) por Nodo | ✅ |
| ΔBanda Dominante / ΔCobertura | — | ➖ omitidos (poco descriptivos; cobertura fuera del comparativo) |

Colores por escenario: Red Actual `#6f2585`, Anillo MB `#c8102e`, Anillo Metro `#e5631a`. La banda va como texto, no como color.

---

## Orden de trabajo recomendado

1. **Sección C** — Top 10 por nodo (Maximum) en los tres workbooks Garibelt, revisar notas y re-exportar 6 PDF (Betweenness y Clasificación).
