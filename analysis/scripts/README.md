# analysis/scripts/
Scripts Python de producción. Orquestados por `pipeline/run_pipeline.py`.

Scripts esperados:
- `apimetro_client.py` — consume feeds GTFS vía Apimetro y genera grafos NetworkX (.json / .gpickle)
- `vft_runner.py` — aplica VFTModel y exporta indicadores por nodo (.csv)
