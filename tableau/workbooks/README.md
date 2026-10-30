# tableau/workbooks/

Archivos `.twb` (Tableau Workbook) de la tesis. Formato XML puro — tracked en git, diff-able.

## Por qué .twb y no .twbx

| Formato | Contiene datos | Trackeable en git | Diff-able |
|---------|---------------|-------------------|-----------|
| `.twb`  | No — referencia extracts externos | Sí | Sí (XML) |
| `.twbx` | Sí — empaqueta el `.hyper` dentro | No recomendado (binario grande) | No |

Los datos viven en CSV y GeoJSON dentro de `../exports/` y `../connectors/VFTModel/exports/`, conectados en Live (se regeneran con `make export-all`).
Solo los viz04 de Apimetro usan un extracto `.hyper` del WDC, guardado en `My Tableau Repository` (fuera del repo).
Los `.twb` solo guardan la definición del dashboard: hojas, cálculos, estilos y las rutas de sus fuentes.
Antes de mover o borrar datos, ejecuta `make check-paths`.

## Convención de nombres

```
dashboard_viz<##>_<tema>[_scenario_<mb|metro>].twb
```

- `viz04_red_apimetro`, `viz04_red_vftmodel`: copias de escenario generadas con `make workbooks`.
- `viz05_garibelt_{baseline,scenario_mb,scenario_metro,comparativo}`: copias hechas a mano.
