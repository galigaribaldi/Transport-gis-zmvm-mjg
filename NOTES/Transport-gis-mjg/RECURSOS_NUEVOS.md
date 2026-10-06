# Recursos nuevos y cambios — 2026-10-04 / 2026-10-05

## 1. Pipeline (Makefile)

| Target / opción | Qué hace |
|-----------------|----------|
| `make warmup-all` | Calienta los 3 servidores VFTModel **en paralelo** (~20 min). Log en `/tmp/vft_warmup/` |
| `_warmup-port` | 2 pasos: `build-auto` + `network-profile`, que calcula T y B(v) internamente |
| `SHOW_C=1` | Flag opcional en `warmup-baseline/-mb/-metro`: imprime C₁₄₁ y C₇₆ (`cobertura_dominios`, #26) |
| `make export-layers` | **Nuevo.** Descarga `cobertura_por_alcaldia`, `cobertura_800m`, `df_por_alcaldia` (Tableau) y `perfil_nodos` (QGIS) de los 3 escenarios, todos con CDMX + Edomex |
| `make export-garibelt-layers` | **Nuevo.** Corre `prepare_garibelt_layers.py --all` |
| `make export-all` | Ahora encadena: GeoJSONs VFTModel → líneas Apimetro → `export-layers` → `export-garibelt-layers` → CSVs Garibelt |
| `make verify` | Referencias actualizadas: líneas 678/686, T 113.91 / 108.99 / 101.92 |

## 2. Scripts corregidos

| Script | Corrección |
|--------|-----------|
| `utils/prepare_garibelt_layers.py` | Escribía MB y Metro en la raíz de `data/processed/garibelt/`. Ahora escribe en `scenario-mb/` y `scenario-metro/` |
| `utils/export_garibelt_csv.py` | Escribía en la raíz de `tableau/exports/data/garibelt/`. Ahora escribe en `escenario-base/`, `escenario-mb/` y `escenario-metro/` |

Pendiente: `export_garibelt_csv.py` todavía no exporta `cobertura_dominios`, así que la C de las 76 demarcaciones no llega a Tableau.

## 3. QGIS — `maps/projects/garibelt_comparativo.qgz`

### Grupos de capas
| Grupo | Capas | Fuente |
|-------|-------|--------|
| Propuesta-Anillar | `anillo_mb` (naranja `#F46700` 1.2 mm + halo blanco 2.2 mm), `anillo_metro` (azul `#0071C1` 2.0 mm + halo 3.5 mm) | `tableau/exports/geo/scenario_*/anillo_*.geojson` |
| Garibelt - BaseLine | Banda Dominante, Fuerza Capilar, Centralidad B(v), Nivel de Cobertura | `data/processed/garibelt/` |
| Garibelt-Scenario-MB / -Metro | Centralidad Intermedia, Fuerza Capilar, Nivel de Cobertura | `data/processed/garibelt/scenario-*/` |
| Base_Territorial | Transporte, LimitesPoliticos | `data/processed/*.gpkg` |

Regla: usar siempre las capas de `data/processed/garibelt/`, que ya traen `fc_banda`, `categoria_cobertura`, `categoria_b`, etc. Las de `tableau/exports/geo/` no tienen esos campos, y unir `poligonos` + CSV obliga a filtrar entidades y a usar el prefijo `cob_`.

Estilos copiados de BaseLine con Copy Style → Paste Style:
- Cobertura: Rule-based con `categoria_cobertura` (alta / media / baja con `cobertura_pct` > 0 / ELSE)
- FC: reglas sobre `fc_banda`
- B(v): Top 5 · Top 6–15 · Top 16–50 (`categoria_b`)

### Map Themes creados
`Comp_Bv_Base` · `Comp_Bv_MB` · `Comp_Bv_Metro` · `Comp_FC_Base` · `Comp_FC_MB` · `Comp_FC_Metro` · `Comp_Cob_Base` · `Comp_Cob_Anillo` · `Mapa Base`

### Layout comparativo acordado (A3 horizontal, 420 × 297 mm)
```
y=10  ┌──────────────────────────────────────────────────────────┐
      │ Título · subtítulo                                 20 mm │
y=35  ├──────────────────┬──────────────────┬────────────────────┤
      │ Red Actual 2026  │ Anillo MB (BRT)  │ Anillo Metro       │ 8 mm
y=43  │   MAPA 130×194   │   MAPA 130×194   │   MAPA 130×194     │
y=237 ├──────────────────┴──────────┬───────┴────────────────────┤
      │ Simbología + norte + escala │ Descripción breve + fuente │ 45 mm
y=287 └─────────────────────────────┴────────────────────────────┘
       x=10–140           x=145–275          x=280–410
```
- Escala 1:200,000 (B(v) y FC) · 1:250,000 (cobertura)
- Centro EPSG:32614: X 485884, Y 2145323 · extensión 1:200k: xmin 472884, xmax 498884, ymin 2125923, ymax 2164723
- Cada mapa: Follow map theme + Lock layers + Lock styles; mismo extent en los 3 paneles
- Sin tablas en QGIS: las cifras van en Tableau

## 4. Plan de recursos comparativos pendientes

Reparto: **QGIS muestra dónde cambia · Tableau muestra cuánto cambia**.

### QGIS → `maps/exports/pdf/Clasificacion_Garibelt/Comparativo/`
| Recurso | Descripción | Utilidad | Prioridad |
|---------|-------------|----------|-----------|
| Comparativo_Garibelt_Betweenness.pdf | 3 paneles Base · MB · Metro, Top 50 B(v) + anillo | La centralidad migra al anillo en Metro | Alta |
| Comparativo_Garibelt_Cobertura.pdf | 2 paneles Base · Anillo (MB = Metro) | Ubica las ganancias de Nezahualcóyotl y Tlalnepantla | Media |
| Comparativo_Garibelt_Cambio_Banda.pdf | 1 panel: solo nodos que cambian de Banda Dominante | Localiza los pocos nodos que mejoran o empeoran (requiere GeoJSON de diferencias por script) | Media |
| Comparativo_Garibelt_Fuerza_Capilar.pdf | 3 paneles por banda FC | Anexo: la conectividad capilar casi no cambia | Baja |

Omitido: Banda Dominante en 3 paneles (cambia < 25 de 11 k nodos; los paneles se verían iguales).

### Tableau → `dashboard_viz06_garibelt_comparativo.twb` → `tableau/exports/pdf/Clasificacion_Garibelt/Comparativo_Base_MB_Metro/`
| Recurso | Descripción | Utilidad |
|---------|-------------|----------|
| Dashboard_Comparativo_KPI.pdf | Resumen por escenario: nodos, T, C₁₄₁ / C₇₆, Gini B(v), % crítico | Lectura rápida de la mejora de cada propuesta |
| Dashboard_Comparativo_Betweenness.pdf | Top 10 B(v) × escenario y ΔB(v) por nodo | Cuantifica la redistribución (Tacubaya −30 % en Metro) |
| Dashboard_Comparativo_Cobertura.pdf | ΔCobertura por demarcación y dominio 141 vs 76 | Mide la ganancia y la limitación por falta de datos de Edomex |
| Dashboard_Comparativo_Bandas.pdf | Distribución por banda (FC y Banda Dominante) × escenario + matriz de transición | Cuántos nodos pasan de crítico a débil y viceversa |

### Tableau por escenario (sección C del README de Tableau)
- `dashboard_viz05_garibelt_mb.twb` y `dashboard_viz05_garibelt_metro.twb`: KPI, Clasificación, Espectro, Betweenness → `MB_scenario/` y `Metro_scenario/`

## 5. Orden sugerido para retomar

1. Volver a exportar los PDFs marcados 🔁 en [ESTADO_RECURSOS.md](ESTADO_RECURSOS.md), con las descripciones actualizadas
2. Armar y exportar los comparativos QGIS (empezar por B(v))
3. Tableau: refrescar extractos, re-exportar 🔁, crear viz05 MB/Metro y viz06 comparativo
