# tableau/extracts/

Directorio de extracts `.hyper` — el formato nativo de Tableau para datos en caché local.

## Importante: archivos gitignored

Los `.hyper` son binarios generados automáticamente y **no se trackean en git**.
Para trabajar con los workbooks es necesario regenerarlos localmente:

```bash
source .venv/bin/activate
python tableau/scripts/tableau_fetcher.py --mode live
```

## Por qué .hyper

| Criterio | .hyper | CSV |
|----------|--------|-----|
| Velocidad de carga en Tableau | Muy rápida (columnar) | Lenta en datasets grandes |
| Tipos de datos preservados | Sí (int, float, date, string) | Todo como string, Tableau infiere |
| Legible sin Tableau | No | Sí |
| Tamaño en disco | Compacto | Mayor |

El fetcher también puede generar CSV de respaldo con `--formato csv` para inspección manual,
pero el estándar del proyecto es `.hyper`.

## Extracts esperados

| Archivo | Origen | Tablas internas |
|---------|--------|----------------|
| `cobertura.hyper` | VFTModel `/coverage` | `cobertura_por_alcaldia`, `estaciones` |
| `factor_desviacion.hyper` | VFTModel `/detour` | `df_puntos`, `df_por_alcaldia` |
| `fuerza_capilar.hyper` | VFTModel `/capillary` | `fc_puntos`, `fc_hubs` |
| `red_apimetro.hyper` | Apimetro `localhost:8080` | `lineas`, `estaciones_red` |
