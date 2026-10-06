# Estructura de carpetas — 2026-10-05

Dónde vive cada recurso y quién lo genera. Las rutas son relativas a la raíz del repo.

## Flujo general

```
Apimetro (:8080 base · :8083 MB · :8084 Metro)      VFTModel (:8000 base · :8001 MB · :8002 Metro)
        │                                                    │
        │ make export-lineas                                 │ make export-baseline/-mb/-metro   (generate_exports.py)
        │                                                    │ make export-layers                (curl a /geolayers)
        ▼                                                    ▼
  tableau/exports/geo/ ◄─────────────────────────────────────┘
  tableau/connectors/VFTModel/exports/
        │
        ├── make export-garibelt-layers  (prepare_garibelt_layers.py)  ──►  data/processed/garibelt/   ──►  QGIS
        └── make export-garibelt-csv-all (export_garibelt_csv.py)      ──►  tableau/exports/data/garibelt/ ──►  Tableau
```

`make export-all` corre todo en ese orden. Requiere los 6 servidores activos y la caché caliente (`make warmup-all`).

## Árbol

```
Transport-gis-zmvm-mjg/
├── Makefile                          ← pipeline: check · warmup · export · workbooks · verify
├── NOTES/
│   ├── Apimetro/                     ← correcciones ACHECK
│   ├── VFTModel/                     ← re-corrida y verificaciones del revisor
│   ├── Tesis/                        ← notas de capítulos y diagnóstico de datos
│   └── Transport-gis-mjg/            ← estas notas
│
├── utils/
│   ├── generate_exports.py           ← GeoJSONs VFTModel (b/fc/df_puntos, cobertura_estaciones)
│   ├── prepare_garibelt_layers.py    ← capas Garibelt para QGIS
│   ├── export_garibelt_csv.py        ← CSVs Garibelt para Tableau
│   └── copy_workbook_scenario.py     ← clona .twb baseline → escenarios
│
├── data/processed/
│   ├── *.gpkg                        ← LimitesPoliticos, Transporte, InfraEstructura… (Git LFS)
│   ├── scenarios/VFTOutput_scenario_{mb,metro}.gpkg
│   └── garibelt/                     ← CAPAS QGIS GARIBELT
│       ├── perfil_nodos_baseline.geojson       (11,115)  Banda Dominante
│       ├── fc_puntos_garibelt.geojson          (10,543)  Fuerza Capilar
│       ├── b_puntos_top.geojson                (50)      Top B(v)
│       ├── cobertura_garibelt.geojson          (141)     Cobertura por demarcación
│       ├── scenario-mb/      → perfil_nodos_mb · fc_puntos_garibelt_mb · b_puntos_top_mb · cobertura_garibelt_mb
│       └── scenario-metro/   → perfil_nodos_metro · fc_puntos_garibelt_metro · b_puntos_top_metro · cobertura_garibelt_metro
│
├── maps/
│   ├── projects/
│   │   ├── garibelt_red_actual.qgz
│   │   ├── garibelt_escenario_mb.qgz
│   │   ├── garibelt_escenario_metro.qgz
│   │   ├── garibelt_comparativo.qgz  ← NUEVO: análisis comparativo Base/MB/Metro
│   │   ├── vft_indicadores.qgz
│   │   ├── tesis-2026-2.qgz
│   │   └── coloquio-2026-2.qgz
│   ├── templates/                    ← .qpt paletas UNAM (VerdeEsmeralda principal)
│   ├── fonts/                        ← TTF Open Sans
│   └── exports/pdf/
│       ├── Scenarios/
│       │   ├── Red_Actual/{Base_Red_Actual, Indicadores_Red_Actual}/
│       │   ├── Propuesta_MB/Base_MB/
│       │   └── Propuesta_Metro/Base_Metro/
│       └── Clasificacion_Garibelt/
│           ├── Red_actual/
│           ├── Scenario_MB/
│           ├── Scenario_Metro/
│           └── Comparativo/          ← PENDIENTE
│
└── tableau/
    ├── connectors/
    │   ├── apimetro/apimetro_wdc.html
    │   └── VFTModel/
    │       ├── vft_wdc.html          ← tablas: fc_puntos, fc_hubs, df_puntos, b_puntos, t_escalar
    │       └── exports/              ← Spatial Files: cobertura_por_alcaldia (141), cobertura_800m, df_por_alcaldia
    │           ├── scenario_mb/
    │           └── scenario_metro/
    ├── workbooks/                    ← viz04 (Apimetro y VFTModel × 3), viz05_garibelt_baseline
    ├── exports/
    │   ├── geo/                      ← GeoJSONs baseline
    │   │   ├── b_puntos (2000) · fc_puntos (10,543) · df_puntos (200) · lineas (678) · poligonos · cobertura_estaciones
    │   │   ├── scenario_mb/          ← ídem (fc 10,642 · lineas 686) + anillo_mb.geojson
    │   │   └── scenario_metro/       ← ídem (fc 10,642 · lineas 686) + anillo_metro.geojson
    │   ├── data/garibelt/
    │   │   ├── escenario-base/       ← b_ranking · fc_distribucion · df_distribucion · cobertura_alcaldias · garibelt_perfil  (_baseline)
    │   │   ├── escenario-mb/         ← ídem (_scenario_mb)
    │   │   └── escenario-metro/      ← ídem (_scenario_metro)
    │   └── pdf/
    │       ├── Apimetro/{Dashboards, UniGrafica}/
    │       ├── VFTModel/{Dashboards, UniGrafica}/
    │       └── Clasificacion_Garibelt/
    │           ├── Red_Actual/
    │           ├── MB_scenario/                  ← PENDIENTE
    │           ├── Metro_scenario/               ← PENDIENTE
    │           └── Comparativo_Base_MB_Metro/    ← PENDIENTE
    └── extracts/                     ← .hyper (gitignored)
```

## Convenciones de nombre de carpeta por escenario

Cada carpeta usa un nombre distinto para el mismo escenario. Al crear archivos nuevos, respetar la convención de la carpeta:

| Ubicación | Baseline | MB | Metro |
|-----------|----------|----|-------|
| `tableau/exports/geo/` | (raíz) | `scenario_mb/` | `scenario_metro/` |
| `tableau/connectors/VFTModel/exports/` | (raíz) | `scenario_mb/` | `scenario_metro/` |
| `tableau/exports/data/garibelt/` | `escenario-base/` | `escenario-mb/` | `escenario-metro/` |
| `data/processed/garibelt/` | (raíz) | `scenario-mb/` | `scenario-metro/` |
| `maps/exports/pdf/Clasificacion_Garibelt/` | `Red_actual/` | `Scenario_MB/` | `Scenario_Metro/` |
| `tableau/exports/pdf/Clasificacion_Garibelt/` | `Red_Actual/` | `MB_scenario/` | `Metro_scenario/` |
