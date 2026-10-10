# maps/

Cartografía QGIS de la tesis **"Transportes Anillares y su importancia en la CDMX y ZMVM"**.
UNAM · FES Acatlán · Maestría en Urbanismo · Semestre 2026-2.

---

## Estructura

```
maps/
  projects/     ← Proyectos QGIS (.qgz), uno por tema/escenario
  templates/    ← Plantillas de layout (.qpt) con paletas UNAM
  exports/pdf/  ← PDFs finales organizados por categoría y escenario
  fonts/        ← TTFs estáticos (Open Sans) para compatibilidad multiplataforma
```

---

## Proyectos QGIS

| Proyecto | Qué contiene | Capas clave |
|----------|-------------|-------------|
| `garibelt_red_actual.qgz` | Clasificación Garibelt — red base 2025 | VFT indicadores (baseline GeoJSONs), Transporte, LimitesPoliticos |
| `garibelt_escenario_mb.qgz` | Propuesta Anillar MB + Garibelt MB | `anillo_mb.geojson`, escenario-mb CSVs, Named Styles + Map Themes |
| `garibelt_escenario_metro.qgz` | Propuesta Anillar METRO + Garibelt METRO | `anillo_metro.geojson`, escenario-metro CSVs, Named Styles + Map Themes |
| `vft_indicadores.qgz` | Indicadores VFTModel — red base | `b_puntos.geojson`, `fc_puntos.geojson`, `df_puntos.geojson` |
| `tesis-2026-2.qgz` | Mapas generales para el documento de tesis | Varios |
| `coloquio-2026-2.qgz` | Mapas para presentación Coloquio 2026-2 | Varios |

Fuente de datos: `data/processed/*.gpkg` + `tableau/exports/geo/` (GeoJSONs por escenario).

---

## Plantillas de layout (.qpt)

Todas con variantes Horizontal / Vertical. La paleta principal de la tesis es **VerdeEsmeralda**.

| Plantilla | Uso |
|-----------|-----|
| `PlantillaBase_VerdeEsmeralda_Horizontal.qpt` | Tesis — mapas horizontales (principal) |
| `PlantillaBase_Institucional_Horizontal.qpt` | Presentaciones formales UNAM |
| `Modificados/PlantillaBase_Verde_horizontal_Coloquio.qpt` | Coloquio 2026-2 (franjas verdes) |

---

## Estado de recursos — PDFs exportados

Leyenda: ✅ generado · ⬜ pendiente · ➖ omitir (cubierto por otro recurso)

### A · Red Actual — mapas base e indicadores

Proyecto: `garibelt_red_actual.qgz` y `vft_indicadores.qgz`
Destino: `exports/pdf/Scenarios/Red_Actual/`

| Recurso | Archivo | Estado |
|---------|---------|--------|
| Transporte público ZMVM | `Base_Red_Actual/Mapa_Transporte_Publico.pdf` | ✅ |
| Red esquemática | `Base_Red_Actual/Mapa_Red_Esquematica.pdf` | ✅ |
| Betweenness centrality | `Indicadores_Red_Actual/Mapa_Betweenness.pdf` | ✅ |
| Cobertura mapa de calor | `Indicadores_Red_Actual/Mapa_Cobertura_Mapa_Calor.pdf` | ✅ |
| Cobertura red total | `Indicadores_Red_Actual/Mapa_Cobertura_Red_Total.pdf` | ✅ |
| Factor Desviación | `Indicadores_Red_Actual/Mapa_DF.pdf` | ✅ |
| Fuerza Capilar | `Indicadores_Red_Actual/Mapa_Fuerza_Capilar.pdf` | ✅ |

### B · Clasificación Garibelt — mapas QGIS por escenario

Proyectos: `garibelt_red_actual.qgz` / `garibelt_escenario_mb.qgz` / `garibelt_escenario_metro.qgz`
Destino: `exports/pdf/Clasificacion_Garibelt/{Red_actual, Scenario_MB, Scenario_Metro}/`

| Mapa | Red Actual | Escenario MB | Escenario METRO |
|------|-----------|-------------|----------------|
| Banda Dominante | ✅ | ⬜ | ⬜ |
| Betweenness Centrality B(v) | ✅ | ⬜ | ⬜ |
| Fuerza Capilar FC | ✅ | ⬜ | ⬜ |
| Cobertura por alcaldía | ✅ | ⬜ | ⬜ |

### C · Propuesta Anillar — trazado y cuadrantes

Proyectos: `garibelt_escenario_mb.qgz` · `garibelt_escenario_metro.qgz`
Destino: `exports/pdf/Propuestas_Base_Scenarios/{Propuesta_MB, Propuesta_Metro}/`

| Mapa | Escenario MB | Escenario METRO |
|------|-------------|----------------|
| Base (anillo + red sin etiquetas) | ✅ | ✅ |
| Extendido A3 (dashboard 4 cuadrantes) | ✅ | ✅ |

### D · Indicadores por escenario — QGIS (Anexos)

Destino: `exports/pdf/Scenarios/{Propuesta_MB, Propuesta_Metro}/Indicadores_*/`

| Mapa | MB | METRO | Nota |
|------|----|-------|------|
| Betweenness por escenario | ➖ | ➖ | cubierto por sección B |
| Cobertura calor por escenario | ➖ | ➖ | cubierto por sección B |
| Fuerza Capilar por escenario | ➖ | ➖ | cubierto por sección B |
| Factor Desviación por escenario | ⬜ | ⬜ | único no cubierto — opcional/anexo |

### E · Comparativo entre escenarios — QGIS

Proyecto: `garibelt_comparativo.qgz` · Destino: `exports/pdf/Clasificacion_Garibelt/Comparativo/`
Capas comparativas: `data/processed/garibelt/comparativo/` (`make export-comparativo`)

| Layout | PDF | Contenido | Estado |
|--------|-----|-----------|--------|
| Comparativo_Bv | `Comparativo_Garibelt_Betweenness.pdf` | 2×2: Red Actual · MB · Metro · ΔB(v) Metro − Base (1:270,000) | ✅ |
| Comparativo_Cobertura | `Comparativo_Garibelt_Cobertura.pdf` | 2 paneles: Red Actual · Anillo + demarcaciones con aumento (1:400,000) | ✅ |
| Comparativo_Cambio_Banda | `Comparativo_Garibelt_Cambio_Banda.pdf` | 2 paneles MB · Metro: nodos que cambian de Banda Dominante (1:180,000) | ✅ |
| Comparativo_FC | — | FC casi no cambia entre escenarios; se omite | ➖ |

---

## Orden de trabajo recomendado

1. **Sección B** — 4 mapas Garibelt × MB + METRO = 8 PDFs (próximo paso)
2. **Sección E** — comparativos (después de tener B completa)
3. **Sección D** — solo Mapa_DF si se requiere en tesis (opcional)
