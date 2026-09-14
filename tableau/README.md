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

| Archivo | Indicador | WDC fuente |
|---------|-----------|-----------|
| `col2026-2_viz01_cobertura.twb` | Cobertura por alcaldía (%) | `vftmodel_wdc.html` → `/coverage` |
| `col2026-2_viz02_factor_desviacion.twb` | Distribución del Factor de Desviación | `vftmodel_wdc.html` → `/detour` |
| `col2026-2_viz03_fuerza_capilar.twb` | Ranking de nodos por Fuerza Capilar | `vftmodel_wdc.html` → `/capillary` |
| `col2026-2_viz04_red_apimetro.twb` | Estadísticas por sistema de transporte | `apimetro_wdc.html` → `/movilidad` |

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
