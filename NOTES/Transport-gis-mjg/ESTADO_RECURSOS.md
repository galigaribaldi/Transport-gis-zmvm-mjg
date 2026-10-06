# Estado de recursos — 2026-10-05

Las capas y CSV se regeneraron el 2026-10-05 con `make export-all`, después de las correcciones de Apimetro (ACHECK-01…04) y VFTModel (#22 DI < 1, #23 SUB aislado, #26 dominio 76).
Todo PDF exportado **antes** de esa fecha usa datos anteriores.

Leyenda: ✅ vigente · 🔁 volver a exportar (datos cambiaron) · 🔎 revisar (los datos casi no cambian; verificar texto o detalle)

---

## 1. Resumen

| Herramienta | PDFs totales | ✅ Vigentes | 🔎 Revisar | 🔁 Volver a exportar |
|-------------|-------------|-------------|------------|----------------------|
| QGIS | 23 | 4 | 7 | 12 |
| Tableau | 20 | 2 | 6 | 12 |
| **Total** | **43** | **6** | **13** | **24** |

¿Por qué la cobertura sigue vigente? Los valores de C por demarcación no cambiaron (`cobertura_alcaldias_*.csv` idénticos). Cambiaron B(v), FC, DI, T y la Banda Dominante.

---

## 2. QGIS — `maps/exports/pdf/`

### Scenarios/Red_Actual/
| PDF | Estado | Motivo |
|-----|--------|--------|
| Base_Red_Actual/Mapa_Transporte_Publico.pdf | 🔎 | SUB ahora en 12 tramos; el trazo se ve igual |
| Base_Red_Actual/Mapa_Red_Esquematica.pdf | 🔎 | Igual que el anterior |
| Indicadores_Red_Actual/Mapa_Betweenness.pdf | 🔁 | B(v) cambió (Mixcoac 0.173 → 0.192) |
| Indicadores_Red_Actual/Mapa_Cobertura_Mapa_Calor.pdf | 🔎 | `cobertura_800m` baseline ahora incluye Edomex (antes solo CDMX) |
| Indicadores_Red_Actual/Mapa_Cobertura_Red_Total.pdf | ✅ | C sin cambio |
| Indicadores_Red_Actual/Mapa_DF.pdf | 🔁 | DI cambió (#22: ya no hay DI < 1) |
| Indicadores_Red_Actual/Mapa_Fuerza_Capilar.pdf | 🔁 | FC: 10,537 → 10,543 nodos |

### Clasificacion_Garibelt/ (Red_actual · Scenario_MB · Scenario_Metro)
| Mapa | Red Actual | MB | Metro |
|------|-----------|----|-------|
| Clasificacion_Banda_Dominante | 🔁 | 🔁 | 🔁 |
| Clasificacion_Garibelt_Betweenness_Centrality | 🔁 | 🔁 | 🔁 |
| Clasificacion_Garibelt_Fuerza_Capilar | 🔁 | 🔁 | 🔁 |
| Clasificacion_Garibelt_Mapa_Cobertura | ✅ | ✅ | ✅ |

### Scenarios/Propuesta_MB · Propuesta_Metro
| PDF | Estado | Motivo |
|-----|--------|--------|
| Propuesta_Base_Anillar_MB / _Metro | 🔎 | El trazado no cambia; revisar si la descripción cita T |
| Propuesta_Anillar_Extendido_MB / _Metro | 🔎 | Igual; los ΔT cambiaron (MB −4.92, Metro −11.99 min) |

---

## 3. Tableau — `tableau/exports/pdf/`

| Carpeta | PDF | Estado | Motivo |
|---------|-----|--------|--------|
| Apimetro/ (5) + `dashboard_viz04_red_apimetro.pdf` | Dashboards y gráficas Apimetro | 🔎 | Cambió la velocidad de INTERURBANO (160 → 70) y TROLE L10 (25); revisar si aparecen |
| VFTModel/Dashboards/ | Centralidad, Factor desviación, Fuerza Capilar | 🔁 | B(v), DI y FC cambiaron |
| VFTModel/UniGrafica/ | B(v) nodos, B(v) sistema, Factor desviación, Fuerza capilar, Tiempo promedio | 🔁 | Ídem; T baseline 108.92 → 113.91 min |
| VFTModel/UniGrafica/ | Cobertura alcaldía, Cobertura sistema | ✅ | C sin cambio |
| Clasificacion_Garibelt/Red_Actual/ | KPI, Clasificación, Espectro, Betweenness | 🔁 | DI, T y Gini cambiaron |

Antes de exportar: abrir cada `.twb` y refrescar los extractos `.hyper`.

---

## 4. Valores vigentes (para descripciones)

Fuente: `RESULTADOS_RECORRIDA.md` §7/§9.2 y capas regeneradas el 2026-10-05.

### Perfil Garibelt (normalizado — banda)
| Dimensión | Baseline | MB | Metro |
|-----------|----------|----|-------|
| C (141) | 0.0552 Crítico | 0.0557 Crítico | 0.0557 Crítico |
| C (ZMVM 76) | 0.1661 Crítico | 0.1678 Crítico | 0.1678 Crítico |
| Cᵢ | 0.25 Débil | 0.25 Débil | 0.25 Débil |
| DI | 0.6533 Aceptable | 0.66 Aceptable | 0.6133 Aceptable |
| T | 0.6957 Aceptable | **0.7475 Aceptable** ⚠️ | 0.8219 Idóneo |
| B(v) (1 − Gini) | 0.1993 Crítico | 0.1988 Crítico | 0.1866 Crítico |

⚠️ T MB pasó de Idóneo a Aceptable y queda a 0.0025 del umbral (0.75).

### Valores brutos
| Métrica | Baseline | MB | Metro |
|---------|----------|----|-------|
| T (min) | 113.91 | 108.99 (−4.92) | 101.92 (−11.99) |
| DI mediana | 1.52 | 1.51 | 1.58 |
| Gini B(v) | 0.8007 | 0.8012 | 0.8134 |
| C 141 / C 76 (%) | 4.4138 / 13.287 | 4.4596 / 13.426 | 4.4596 / 13.426 |
| Nodos | 11,115 | 11,209 | 11,209 |
| SCC gigante | 10,610 (95.46 %) | 10,707 (95.52 %) | 10,707 (95.52 %) |
| Líneas Apimetro | 678 | 686 | 686 |

### Top 5 B(v)
| # | Baseline | MB | Metro |
|---|----------|----|-------|
| 1 | Tacubaya 0.223 | Tacubaya 0.216 | Tacubaya 0.157 |
| 2 | Mixcoac 0.192 | Mixcoac 0.184 | Periférico Oriente/Tláhuac 0.155 |
| 3 | Hidalgo 0.152 | Hidalgo 0.146 | Rómulo O'Farril 0.131 |
| 4 | Balderas 0.143 | Balderas 0.139 | Barranca del Muerto/Periférico 0.128 |
| 5 | Lázaro Cárdenas 0.136 | Lázaro Cárdenas 0.136 | Constitución de 1917/Periférico 0.127 |

Hallazgo: en Metro, **4 de los 5 nodos con mayor B(v) están sobre el anillo**. Tacubaya baja 30 % frente a Baseline (0.223 → 0.157). En MB la jerarquía del centro histórico se mantiene.

### Fuerza Capilar (nodos por banda)
| Banda | Baseline | MB | Metro |
|-------|----------|----|-------|
| Idóneo | 5 | 5 | 5 |
| Aceptable | 95 | 98 | 98 |
| Débil | 1,486 | 1,507 | 1,505 |
| Crítico | 8,957 (85.0 %) | 9,032 (84.9 %) | 9,034 (84.9 %) |
| Total | 10,543 | 10,642 | 10,642 |

### Banda Dominante (perfil_nodos)
| Banda | Baseline | MB | Metro |
|-------|----------|----|-------|
| Aceptable | 2 | 2 | 2 |
| Débil | 68 | 69 | 82 |
| Crítico | 11,045 | 11,138 | 11,125 |

### Cobertura por demarcación (sin cambio)
- 101 de 141 demarcaciones con 0 %; MB y Metro idénticos.
- Cambios Baseline → Anillo: Nezahualcóyotl 39.79 → 48.64 % (+8.85), Tlalnepantla 53.94 → 58.85 % (+4.91), Ecatepec +0.40, Texcoco 0 → 0.13; Iztapalapa, Xochimilco y Naucalpan +0.01 a +0.03.
