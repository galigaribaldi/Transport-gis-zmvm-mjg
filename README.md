# Transport-gis-zmvm-mjg

**Hernán Galileo Cabrera Garibaldi**
Programa de Maestría y Doctorado en Urbanismo — FES Acatlán, UNAM · Semestre 2026-2

Cartografía (**QGIS**) y visualización estadística (**Tableau**) de la tesis **"Transportes Anillares y su importancia en la CDMX y ZMVM"**. El repo también sirve de referencia para futuros proyectos de QGIS y Tableau.

📖 **Documentación: [wiki del repositorio](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki)**

| Página | Contenido |
|---|---|
| [Estructura del repositorio](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Estructura-del-repositorio) | Qué hay en cada carpeta |
| [Reglas de rutas](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Reglas-de-rutas) | Qué no mover para no romper los proyectos |
| [Convenciones de nombres](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Convenciones-de-nombres) | Escenarios, proyectos, workbooks y exports |
| [Flujo de datos](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Flujo-de-datos) | Regenerar los datos con el Makefile |
| [Tableau](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Tableau) · [QGIS](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/QGIS) | Abrir, editar y exportar |
| [Descargables](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Descargables) | Mapas, dashboards y gráficas para ver o descargar |

---

## Inicio rápido

```bash
git lfs install
git clone https://github.com/galigaribaldi/Transport-gis-zmvm-mjg.git
cd Transport-gis-zmvm-mjg
bash setup/install_fonts.sh                      # fuentes de los layouts QGIS (Windows: setup\install_fonts.bat)
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
make check-paths                                 # todas las fuentes de los .twb y .qgz deben existir
```

Después abre un proyecto de `maps/projects/` en QGIS 4.x o un workbook de `tableau/workbooks/` en Tableau Desktop.

Para **regenerar los datos** hacen falta los repos hermanos `../Apimetro` y `../VFTModel` corriendo; ver `make help` y la página [Flujo de datos](https://github.com/galigaribaldi/Transport-gis-zmvm-mjg/wiki/Flujo-de-datos).

```
Apimetro + VFTModel ─► make export-all ─► GeoJSON / CSV / GPKG ─┬─► Tableau ─► tableau/exports/pdf/
                                                                 ├─► QGIS    ─► maps/exports/pdf/
                                                                 └─► notebooks ─► analysis/notebooks/output/
```

> Antes y después de mover, renombrar o borrar archivos: **`make check-paths`**.

---

## GitHub Releases

Los mapas y dashboards entregados se publican como **GitHub Releases**, con un tag que identifica semestre, entregable y tema:

```
v{AÑO}-{S}-{ENTREGABLE}-{TIPO}-{TEMA}[-r{N}]
```

| Segmento | Descripción | Ejemplos |
|----------|-------------|---------|
| `{AÑO}` | Año del semestre | `2026` |
| `{S}` | Semestre dentro del año | `1`, `2` |
| `{ENTREGABLE}` | Contexto | `col` (coloquio), `tesis` |
| `{TIPO}` | Tipo de salida | `mapas`, `analisis`, `datos` |
| `{TEMA}` | Tema en kebab-case | `transporte`, `cobertura`, `df`, `fc`, `red` |
| `[-r{N}]` | Revisión posterior a la entrega (opcional) | `-r2`, `-r3` |

El tag sin sufijo es la entrega original. Las correcciones usan `-r2`, `-r3`, y un tag existente nunca se reutiliza.

```bash
gh release create v2026-2-col-mapas-df \
    maps/exports/pdf/Scenarios/Red_Actual/Indicadores_Red_Actual/Mapa_DF.pdf \
    --title "Mapa: Factor de Desviación — Coloquio 2026-2" \
    --notes "Factor de Desviación por alcaldía. Fuente: VFTModel."
```

---

## Repos relacionados

| Repo | Ruta local | Relación |
|------|-----------|----------|
| `TesisUrbanismo` | `../TesisUrbanismo/` | Documento LaTeX; incluye los PDF/PNG exportados |
| `VFTModel` | `../VFTModel/` | API de indicadores (:8000, :8001, :8002) |
| `Apimetro` | `../Apimetro/` | API de la red GTFS (:8080, :8083, :8084) |
| `Trabajos-Maestria-Urbanismo` | `../Trabajos-Maestria-Urbanismo/` | Plantillas `.qpt` y presentaciones del coloquio |
