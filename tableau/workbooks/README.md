# tableau/workbooks/

Archivos `.twb` (Tableau Workbook) de la tesis. Formato XML puro — tracked en git, diff-able.

## Por qué .twb y no .twbx

| Formato | Contiene datos | Trackeable en git | Diff-able |
|---------|---------------|-------------------|-----------|
| `.twb`  | No — referencia extracts externos | Sí | Sí (XML) |
| `.twbx` | Sí — empaqueta el `.hyper` dentro | No recomendado (binario grande) | No |

Los datos viven en `../extracts/*.hyper` (gitignored, regenerables con `tableau_fetcher.py`).
Los `.twb` solo guardan la definición del dashboard: hojas, cálculos, estilos y la referencia al extract.

## Convención de nombres

```
<proyecto>_viz<##>_<descripcion>.twb
```

- `<proyecto>`: `col2026-2` (Coloquio 2026-2), `tesis` (capítulos de tesis)
- `<##>`: número de dos dígitos, secuencial por proyecto
- `<descripcion>`: tema en kebab-case

## Workbooks planificados

| Archivo | Indicador |
|---------|-----------|
| `col2026-2_viz01_cobertura.twb` | Cobertura de transporte masivo por alcaldía |
| `col2026-2_viz02_factor_desviacion.twb` | Distribución del Factor de Desviación |
| `col2026-2_viz03_fuerza_capilar.twb` | Ranking nodal por Fuerza Capilar |
| `col2026-2_viz04_red_apimetro.twb` | Estadísticas de red por sistema de transporte |
