# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repo

Capa computacional y cartográfica de la tesis de maestría **"Transportes Anillares y su importancia en la CDMX y ZMVM"** (Urbanismo UNAM FES Acatlán, semestre 2026-2).

Conecta cuatro herramientas:
- **Apimetro** — backend Go que consume feeds GTFS de la CDMX y genera grafos de la red de transporte (repo hermano)
- **VFTModel** — modelo propio que calcula indicadores de eficiencia de red (DI, B(v), FC, T) (repo hermano)
- **QGIS** — mapas cartográficos (`maps/projects/*.qgz`)
- **Tableau** — dashboards estadísticos (`tableau/workbooks/*.twb`)

## Repos relacionados (no modificar sin confirmar)

| Repo | Ruta | Relación |
|------|------|----------|
| TesisUrbanismo | `../TesisUrbanismo/` | Consume los PDF/PNG de `maps/exports/`, `tableau/exports/pdf/` y `analysis/notebooks/output/` |
| VFTModel | `../VFTModel/` | API de indicadores (:8000–8002) y `notebooks/ASSETS/t_distribucion/` |
| Apimetro | `../Apimetro/` | API GTFS (:8080, :8083, :8084) |
| Trabajos-Maestria-Urbanismo | `.../Trabajos-Maestria-Urbanismo/` | Fuente de capas `.gpkg` y plantillas `.qpt` |

## Arquitectura y flujo de datos

```
Apimetro (:8080/:8083/:8084) + VFTModel (:8000/:8001/:8002)
    → make export-all  (utils/*.py)        →  GeoJSON/CSV en tableau/exports/, tableau/connectors/VFTModel/exports/
                                              y capas QGIS en data/processed/garibelt/
    → Tableau (tableau/workbooks/*.twb)    →  tableau/exports/pdf/
    → QGIS (maps/projects/*.qgz)           →  maps/exports/pdf/
    → analysis/notebooks/graficas_cap6.ipynb → analysis/notebooks/output/cap6/
    → ../TesisUrbanismo                    →  figuras del documento LaTeX
```

Orquestador: `Makefile` (`make help`, `make guide`).

## Reglas de rutas (no romper los proyectos)

- Antes y después de mover, renombrar o borrar archivos: `make check-paths` (lee todos los `.twb` y `.qgz`).
- Tableau guarda rutas **absolutas**; QGIS, **relativas** a `maps/projects/`.
- `tableau/exports/geo/`, `tableau/connectors/VFTModel/exports/` y `tableau/exports/data/garibelt/` también son fuentes de QGIS.
- No unificar los nombres de escenario: `scenario_mb` (tableau/geo y connectors), `scenario-mb` (data/processed/garibelt), `escenario-mb` (tableau/exports/data/garibelt).
- Detalle completo en la página «Reglas de rutas» de la wiki del repo.

## Estructura del repo

```
data/
  processed/  ← capas .gpkg (Git LFS) y capas Garibelt en garibelt/{,scenario-mb,scenario-metro,comparativo}/

maps/
  projects/   ← proyectos .qgz; capas con rutas relativas a ../../data/processed/ y ../../tableau/
  templates/  ← plantillas .qpt con paletas UNAM (VerdeEsmeralda, Teal, Institucional…)
  exports/    ← pdf/ por escenario y Clasificación Garibelt

tableau/
  workbooks/  ← .twb (XML); connectors/ (WDC y exports VFTModel); exports/ (geo, data, pdf); templates/; geo_proxy/

analysis/
  notebooks/  ← graficas_cap6.ipynb y su salida en output/cap6/

utils/        ← scripts de exportación, copy_workbook_scenario.py y check_paths.py
NOTES/        ← notas de trabajo (se migran a la wiki de GitHub)
```

## Git LFS

Los archivos `.gpkg` están trackeados con Git LFS (`.gitattributes`). `data/raw/` está en `.gitignore`.

Capas procesadas esperadas en `data/processed/`:
- `LimitesPoliticos.gpkg` — alcaldías, manzanas
- `Transporte.gpkg` — Metro, Metrobús, RTP, tren ligero ← la más importante para mapas de metro
- `InfraEstructura.gpkg` — vialidades, periférico
- `MedioFisicoNatural.gpkg` — usos de suelo, curvas de nivel
- `PoligonoEstudio1.gpkg` — polígono de la región de estudio (ningún proyecto lo carga hoy)

## Convención de exports

Nombre: `<proyecto>_mapa<##>_<descripcion>.png`

Los PNGs exportados desde QGIS van a dos destinos:
1. `maps/exports/`
2. El directorio `img/` de la presentación correspondiente en `Trabajos-Maestria-Urbanismo/`

## Git

- No agregar líneas `Co-Authored-By` ni ninguna atribución de Claude en los mensajes de commit.
- Los comandos git se proporcionan como texto para que el usuario los ejecute — Claude no los corre directamente.
