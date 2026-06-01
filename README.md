# Transport-gis-zmvm-mjg

**Hernán Galileo Cabrera Garibaldi**
Programa de Maestría y Doctorado en Urbanismo — FES Acatlán, UNAM
Semestre 2026-2

---

## Descripción

Capa computacional y cartográfica de la tesis de maestría **"Transportes Anillares y su importancia en la CDMX y ZMVM"**. Conecta tres herramientas:

- **Apimetro** — backend Go que consume feeds GTFS de la CDMX y genera grafos de la red de transporte
- **VFTModel** — modelo propio que calcula indicadores de eficiencia de red: Cobertura (C), Factor de Desviación (DF) y Centralidad B(v)
- **QGIS** — mapas cartográficos que visualizan los resultados del modelo con plantillas institucionales UNAM

---

## Requisitos

- **QGIS 3.x** con acceso a las capas en `data/processed/`
- **Python 3.12+** con entorno virtual en `VFTModel/venv/`
- **Go 1.21+** para compilar y ejecutar Apimetro (`localhost:8080`)
- **Git LFS** — los archivos `.gpkg` están trackeados con LFS (`git lfs pull`)
- **gh CLI** — para publicar releases (`gh auth login` antes del primer uso)

---

## Arquitectura del pipeline

```
GTFS (datos CDMX · SEMOVI 2024)
    │
    └─► Apimetro (Go · localhost:8080)
            │  geojsonEstacion / geojsonLinea
            └─► VFTModel (Python · notebooks/)
                    │
                    ├─► 02_Nivel_Cobertura.ipynb     → Cobertura800m.gpkg
                    ├─► 04_Detaur_factor.ipynb        → FactorDesviacion.gpkg
                    └─► 03_Fuerza_capilar.ipynb       → FuerzaCapilar.gpkg
                                │
                                └─► QGIS (maps/projects/coloquio-2026-2.qgz)
                                        │
                                        ├─► maps/exports/pdf/   ← PDFs del layout
                                        └─► Tesis_Latex/Figures/Cap5/
```

Orquestador completo: `pipeline/run_pipeline.py`

---

## Estructura del repositorio

```
Transport-gis-zmvm-mjg/
│
├── CLAUDE.md                        ← Guía para Claude Code
├── pipeline/
│   └── run_pipeline.py              ← Orquestador GTFS → VFT → QGIS
│
├── data/
│   ├── raw/                         ← en .gitignore (GTFS, INEGI sin procesar)
│   └── processed/                   ← capas .gpkg en Git LFS
│
├── analysis/
│   ├── notebooks/                   ← exploración Jupyter
│   └── scripts/                     ← apimetro_client.py, vft_runner.py
│
└── maps/
    ├── projects/                    ← archivos .qgz por entregable
    ├── templates/                   ← plantillas .qpt con paletas UNAM
    └── exports/
        └── pdf/                     ← PDFs de los layouts exportados
```

---

## Capas GIS — `data/processed/`

Todas las capas están en **EPSG:32614** (WGS 84 / UTM zona 14N). Trackeadas con Git LFS.

| Archivo | Layers principales | Fuente | Descripción |
|---------|-------------------|--------|-------------|
| `LimitesPoliticos.gpkg` | `alcaldias`, `municipios_edomex` | INEGI 2023 | Límites político-administrativos CDMX y EDOMEX |
| `Transporte.gpkg` | líneas y estaciones por sistema | GTFS SEMOVI 2024 | Metro, Metrobús, RTP, Tren Ligero, Cablebús, Mexibús, Trolebús |
| `InfraEstructura.gpkg` | vialidades, puentes | INEGI 2023 | Red vial principal |
| `Vialidades.gpkg` | `periferico` | INEGI 2023 (TIPOVIAL='Periférico') | Anillo del Periférico como capa aislada |
| `MedioFisicoNatural.gpkg` | usos de suelo, curvas de nivel | INEGI 2023 | Contexto físico-natural |
| `PoligonoEstudio1.gpkg` | `poligono_estudio` | Elaboración propia | Polígono de la región de análisis |
| `PoligonosEdoMex.gpkg` | `municipios` | INEGI 2023 | Municipios EDOMEX del área metropolitana |
| `Cobertura800m.gpkg` | `cobertura_800m`, `sin_cobertura`, `estaciones`, `cobertura_por_alcaldia` | VFTModel Fase 1 | Isócronos de cobertura caminable 800 m por estación |
| `FactorDesviacion.gpkg` | `df_puntos`, `df_por_alcaldia` | VFTModel Fase 1 · muestra 100 rutas | Factor de Desviación por punto de origen y promedio por alcaldía |
| `FuerzaCapilar.gpkg` | `fc_puntos`, `fc_top20_hubs` | VFTModel Fase 2 | Fuerza Capilar (grado nodal) de los 11,115 nodos del grafo |

---

## GitHub Releases

Los mapas exportados se distribuyen como **GitHub Releases**. Cada release lleva un tag que identifica el semestre, el entregable y el mapa.

### Estructura del tag

```
v{AÑO}-{S}-{ENTREGABLE}-{TIPO}-{TEMA}[-r{N}]
```

| Segmento | Descripción | Ejemplos |
|----------|-------------|---------|
| `{AÑO}` | Año del semestre | `2026` |
| `{S}` | Semestre dentro del año | `1`, `2` |
| `{ENTREGABLE}` | Contexto del entregable | `col` (coloquio), `tesis` |
| `{TIPO}` | Tipo de salida | `mapas`, `analisis`, `datos` |
| `{TEMA}` | Tema en kebab-case | `transporte`, `cobertura`, `df`, `fc`, `red` |
| `[-r{N}]` | Revisión post-entrega (opcional) | `-r2`, `-r3` |

> **Regla:** el tag sin sufijo es la entrega original. Correcciones posteriores usan `-r2`, `-r3`. Nunca se reutiliza ni sobreescribe un tag existente.

---

### Releases — Coloquio 2026-2

| Tag | PDF | Mapa | Estado |
|-----|-----|------|--------|
| `v2026-2-col-mapas-transporte` | `Mapa_Transporte_Publico.pdf` | Red de Transporte Público — ZMVM 2024 | ✓ Listo |
| `v2026-2-col-mapas-cobertura` | `Mapa_Cobertura_Red_Total.pdf` | Cobertura de Transporte Masivo 800 m | ✓ Listo |
| `v2026-2-col-mapas-cobertura-calor` | `Mapa_Cobertura_Mapa_Calor.pdf` | Cobertura por Alcaldía — Mapa de Calor | ✓ Listo |
| `v2026-2-col-mapas-red` | `Mapa_Red_Esquematica.pdf` | Red Esquemática de Transporte | ✓ Listo |
| `v2026-2-col-mapas-df` | `Mapa_DF.pdf` | Factor de Desviación — Distribución Espacial | ✓ Listo |
| `v2026-2-col-mapas-fc` | `Mapa_Fuerza_Capilar.pdf` | Centralidad Nodal — Fuerza Capilar | ✓ Listo |

### Releases — Tesis (planeados)

| Tag | Contenido | Fase VFTModel | Estado |
|-----|-----------|---------------|--------|
| `v2026-2-tesis-cap5-cobertura` | Figuras Cap. 5 — Cobertura (C) | Fase 1 | Pendiente export final |
| `v2026-2-tesis-cap5-df` | Figuras Cap. 5 — Factor de Desviación (DF) | Fase 1 | Pendiente export final |
| `v2026-2-tesis-cap5-fc` | Figuras Cap. 5 — Fuerza Capilar (FC) | Fase 2 | Pendiente export final |
| `v2026-2-tesis-cap5-bv` | Figuras Cap. 5 — Centralidad B(v) | Fase 3 | No calculado |

---

### Publicar un release

```bash
# Crear tag y subir el PDF correspondiente
gh release create v2026-2-col-mapas-df \
    maps/exports/pdf/Mapa_DF.pdf \
    --title "Mapa: Factor de Desviación — Coloquio 2026-2" \
    --notes "Factor de Desviación espacial por alcaldía. Muestra 100 rutas de la ZMVM, graduado verde→rojo. Fuente: VFTModel Fase 1 · abril 2026."
```

---

## Reproducir el análisis

### 1. Clonar el repo con LFS

```bash
git clone <url>
cd Transport-gis-zmvm-mjg
git lfs pull          # descarga los .gpkg
```

### 2. Levantar Apimetro

```bash
cd ../apimetro        # repo hermano
go run main.go        # escucha en localhost:8080
```

### 3. Ejecutar los notebooks VFTModel

```bash
cd ../VFTModel
source venv/bin/activate
jupyter lab notebooks/
```

Orden de ejecución:
1. `00_Construccion_grafo.ipynb` — construye el grafo NetworkX
2. `02_Nivel_Cobertura.ipynb` — calcula C, exporta `Cobertura800m.gpkg`
3. `04_Detaur_factor.ipynb` — calcula DF, exporta `FactorDesviacion.gpkg`
4. `03_Fuerza_capilar.ipynb` — calcula FC, exporta `FuerzaCapilar.gpkg`

### 4. Abrir QGIS

```
maps/projects/coloquio-2026-2.qgz
```

Las capas usan rutas relativas a `../../data/processed/` — no requieren reconfiguración.

---

## Repos relacionados

| Repo | Ruta local | Relación |
|------|-----------|----------|
| `Tesis_Latex` | `../Tesis_Latex/` | Consume PNGs de `maps/exports/` en `Figures/Cap5/` |
| `Trabajos-Maestria-Urbanismo` | `../Trabajos-Maestria-Urbanismo/` | Fuente de plantillas `.qpt` y presentaciones del coloquio |
| `apimetro` | `../apimetro/` | Backend Go, debe estar corriendo en `localhost:8080` |
| `VFTModel` | `../VFTModel/` | Motor analítico Python, genera los `.gpkg` |
