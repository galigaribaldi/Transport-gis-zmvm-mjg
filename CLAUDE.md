# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repo

Capa computacional y cartográfica de la tesis de maestría **"Transportes Anillares y su importancia en la CDMX y ZMVM"** (Urbanismo UNAM FES Acatlán, semestre 2026-2).

Conecta tres herramientas:
- **Apimetro** — backend Go que consume feeds GTFS de la CDMX y genera grafos de la red de transporte
- **VFTModel** — modelo propio que calcula indicadores de eficiencia de red (DI, B(v), ΔE)
- **QGIS** — mapas cartográficos que visualizan los resultados del modelo

## Repos relacionados (no modificar sin confirmar)

| Repo | Ruta | Relación |
|------|------|----------|
| Tesis_Latex | `/home/galigaribaldi/Documentos/Maestria/Tesis_Latex/` | Consume PNGs de `maps/exports/` |
| Trabajos-Maestria-Urbanismo | `.../Trabajos-Maestria-Urbanismo/` | Fuente de capas `.gpkg` y plantillas `.qpt` |

## Arquitectura y flujo de datos

```
GTFS (datos CDMX)
    → analysis/scripts/apimetro_client.py  →  grafo NetworkX (.json / .gpickle)
    → analysis/scripts/vft_runner.py       →  indicadores por nodo (.csv)
    → QGIS (maps/projects/*.qgz)           →  mapas temáticos
    → maps/exports/*.png
    → Tesis_Latex/Figures/                 →  figuras en el documento LaTeX
```

Orquestador: `pipeline/run_pipeline.py`

## Estructura del repo

```
data/
  raw/        ← en .gitignore; fuentes INEGI/GTFS sin procesar
  processed/  ← capas .gpkg recortadas a región de estudio, trackeadas en Git LFS

maps/
  projects/   ← proyectos .qgz por tema/capítulo; capas con rutas relativas a ../../data/processed/
  templates/  ← plantillas .qpt con paletas UNAM (VerdeEsmeralda, Teal, Institucional…)
  exports/    ← PNGs finales → copiados a Tesis_Latex/Figures/ y a Coloquio2026-2/img/

analysis/
  notebooks/  ← exploración y prototipado Jupyter
  scripts/    ← scripts Python de producción (apimetro_client.py, vft_runner.py)

pipeline/     ← run_pipeline.py orquesta todo
```

## Git LFS

Los archivos `.gpkg` están trackeados con Git LFS (`.gitattributes`). `data/raw/` está en `.gitignore`.

Capas procesadas esperadas en `data/processed/`:
- `LimitesPoliticos.gpkg` — alcaldías, manzanas
- `Transporte.gpkg` — Metro, Metrobús, RTP, tren ligero ← la más importante para mapas de metro
- `InfraEstructura.gpkg` — vialidades, periférico
- `MedioFisicoNatural.gpkg` — usos de suelo, curvas de nivel
- `PoligonoEstudio1.gpkg` — polígono de la región de estudio

## Convención de exports

Nombre: `<proyecto>_mapa<##>_<descripcion>.png`

Los PNGs exportados desde QGIS van a dos destinos:
1. `maps/exports/`
2. El directorio `img/` de la presentación correspondiente en `Trabajos-Maestria-Urbanismo/`
