# tableau/datasources/

Archivos `.tds` (Tableau Data Source) — definiciones de conexión reutilizables entre workbooks.
Formato XML, tracked en git. No contienen datos, solo la referencia al extract y metadatos de campos.

## Cuándo usar un .tds

Un `.tds` centraliza la definición de una fuente de datos (nombres de campo, tipos, cálculos
auxiliares, agrupaciones) para que múltiples workbooks la compartan sin duplicar configuración.
Si solo un workbook usa una fuente, la conexión puede vivir dentro del `.twb` directamente.

## Fuentes de datos planificadas

| Archivo | Extract que referencia | Workbooks que la usan |
|---------|----------------------|----------------------|
| `vftmodel_cobertura.tds` | `../extracts/cobertura.hyper` | `viz01_cobertura.twb` |
| `vftmodel_detour.tds` | `../extracts/factor_desviacion.hyper` | `viz02_factor_desviacion.twb` |
| `vftmodel_capillary.tds` | `../extracts/fuerza_capilar.hyper` | `viz03_fuerza_capilar.twb` |
| `apimetro_red.tds` | `../extracts/red_apimetro.hyper` | `viz04_red_apimetro.twb` |
