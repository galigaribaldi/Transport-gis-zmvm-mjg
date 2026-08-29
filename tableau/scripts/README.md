# tableau/scripts/

Scripts Python que extraen datos de VFTModel y Apimetro y los convierten a extracts `.hyper`.

## tableau_fetcher.py

Análogo a `analysis/scripts/vft_fetcher.py` pero orientado a Tableau:
- Llama a los mismos endpoints de VFTModel y a Apimetro.
- Descarta la geometría (no es necesaria para dashboards estadísticos).
- Convierte las `properties` de cada GeoJSON feature a filas de un DataFrame.
- Escribe el resultado como extract `.hyper` usando `pantab`.

### Diferencia clave con vft_fetcher.py

| Script | Conserva geometría | Salida | Consume |
|--------|--------------------|--------|---------|
| `vft_fetcher.py` | Sí | `.gpkg` | QGIS |
| `tableau_fetcher.py` | No | `.hyper` | Tableau |

### Dependencias

```
pip install pantab requests pandas
```

### Uso

```bash
# Todos los extracts
python tableau/scripts/tableau_fetcher.py --mode live

# Un indicador específico
python tableau/scripts/tableau_fetcher.py --mode live --indicador cobertura
python tableau/scripts/tableau_fetcher.py --mode live --indicador detour
python tableau/scripts/tableau_fetcher.py --mode live --indicador capillary
python tableau/scripts/tableau_fetcher.py --mode live --indicador apimetro

# Generar también CSV de inspección
python tableau/scripts/tableau_fetcher.py --mode live --formato hyper+csv

# URLs personalizadas
python tableau/scripts/tableau_fetcher.py --mode live \
    --vftmodel-url http://localhost:8000 \
    --apimetro-url http://localhost:8080
```

### Argumentos

| Argumento | Default | Descripción |
|-----------|---------|-------------|
| `--mode` | `live` | `live` llama a las APIs; `cached` no hace llamadas HTTP |
| `--indicador` | `all` | `cobertura`, `detour`, `capillary`, `apimetro`, o `all` |
| `--formato` | `hyper` | `hyper`, `csv`, o `hyper+csv` |
| `--vftmodel-url` | `http://localhost:8000` | URL base de VFTModel |
| `--apimetro-url` | `http://localhost:8080` | URL base de Apimetro |
| `--output-dir` | `tableau/extracts/` | Directorio de salida para los extracts |
