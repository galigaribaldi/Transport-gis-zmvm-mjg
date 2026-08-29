# tableau/

Módulo de dashboards estadísticos interactivos para la tesis **"Transportes Anillares y su importancia en la CDMX y ZMVM"**.

---

## División de responsabilidades

| Herramienta | Fuente de datos | Produce |
|-------------|----------------|---------|
| **QGIS** | `.gpkg` en `data/processed/` | Mapas cartográficos (PDF/PNG para tesis y coloquio) |
| **Tableau** | API VFTModel + Apimetro (HTTP directo) | Dashboards estadísticos interactivos |

Tableau **no consume `.gpkg`**. El script `scripts/tableau_fetcher.py` llama directamente a los mismos endpoints que `vft_fetcher.py`, pero descarta la geometría y escribe extracts `.hyper` con solo los atributos tabulares.

---

## Estructura

```
tableau/
  workbooks/        ← .twb (XML, git-tracked) — un archivo por tema/indicador
  datasources/      ← .tds definiciones de conexión (XML, git-tracked)
  extracts/         ← .hyper (binario, gitignored) — generados por scripts/tableau_fetcher.py
  scripts/
    tableau_fetcher.py  ← extrae datos de VFTModel y Apimetro → .hyper
  README.md
```

---

## Flujo de datos

```
VFTModel API (localhost:8000)
    │
    ├─► vft_fetcher.py          →  .gpkg  →  QGIS  →  mapas
    │   (geometry + attributes)
    │
    └─► tableau_fetcher.py      →  .hyper  →  Tableau  →  dashboards
        (properties only, sin geometría)

Apimetro (localhost:8080)
    │
    └─► tableau_fetcher.py      →  .hyper  →  Tableau
        (estadísticas de red por línea / estación)
```

---

## Workbooks disponibles

Convención de nombre: `<proyecto>_viz<##>_<descripcion>.twb`

| Archivo | Indicador | Endpoints fuente |
|---------|-----------|-----------------|
| `col2026-2_viz01_cobertura.twb` | Cobertura por alcaldía (%) | VFTModel `/coverage` |
| `col2026-2_viz02_factor_desviacion.twb` | Factor de Desviación por alcaldía y distribución | VFTModel `/detour` |
| `col2026-2_viz03_fuerza_capilar.twb` | Ranking de nodos por Fuerza Capilar | VFTModel `/capillary` |
| `col2026-2_viz04_red_apimetro.twb` | Estadísticas por sistema (líneas, estaciones, cobertura) | Apimetro `localhost:8080` |

---

## Requisitos

```
pip install pantab requests pandas
```

| Paquete | Uso |
|---------|-----|
| `pantab` | Escribe/lee archivos `.hyper` desde pandas DataFrames |
| `requests` | Llamadas HTTP a VFTModel y Apimetro |
| `pandas` | Transforma la respuesta GeoJSON a DataFrame tabular |

---

## Generar los extracts

```bash
# Activar el mismo entorno virtual del repo
source .venv/bin/activate

# Regenerar todos los extracts
python tableau/scripts/tableau_fetcher.py --mode live

# Regenerar solo un indicador
python tableau/scripts/tableau_fetcher.py --mode live --indicador cobertura

# Usar caché existente (no llama a las APIs)
python tableau/scripts/tableau_fetcher.py --mode cached
```

Los archivos `.hyper` se escriben en `tableau/extracts/`. Son gitignored — cada analista los regenera localmente con el comando anterior.

---

## Abrir un workbook

1. Generar los extracts con el comando de arriba.
2. Abrir Tableau Desktop.
3. Abrir `tableau/workbooks/<archivo>.twb`.
4. Si Tableau pide reubicar el extract, apuntarlo a `tableau/extracts/<nombre>.hyper`.

Los `.twb` usan rutas relativas a `../extracts/` — si abres Tableau desde la raíz del repo no debería pedir reubicación.
