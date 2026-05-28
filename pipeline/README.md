# pipeline/
Orquestación completa del flujo de datos:

```
GTFS (CDMX)  →  apimetro_client.py  →  grafo (.json/.gpickle)
                                    ↓
                             vft_runner.py  →  indicadores (.csv)
                                    ↓
                             QGIS (maps/projects/)  →  PNG (maps/exports/)
                                    ↓
                             Tesis_Latex/Figures/
```

Punto de entrada: `run_pipeline.py`
