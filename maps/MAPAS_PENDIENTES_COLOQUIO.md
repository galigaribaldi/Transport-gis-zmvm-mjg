# Mapas Pendientes — Coloquio 2026-2

**Presentación:** `Trabajos-Maestria-Urbanismo/TercerSemestre/Coloquio2026-2/`
**Destino de exports:** `maps/exports/` → copiar también a `Coloquio2026-2/img/`
**Plantilla base:** `maps/templates/PlantillaBase_VerdeEsmeralda_Horizontal.qpt`
**Formato de salida:** PNG, 1920×1080 px, 200 DPI, fondo blanco

---

## Estado general

| # | Archivo destino | Usado en | Estado |
|---|-----------------|----------|--------|
| 0 | `maps/exports/pdf/Mapa_Transporte_Publico.pdf` | — (no va al Coloquio) | **LISTO** |
| 1 | `mapa02_cobertura_sur.png` | s02 frame 2.2 | **PENDIENTE** |
| 2 | `mapa_red_esquematica.png` | s04 frame 4.3b | **PENDIENTE** |
| 3 | `mapa_calor_df.png` | s04 frame 4.10 | **PENDIENTE** |
| 4 | `mapa04_nodos_criticos.png` | plan original s04 | **PENDIENTE** |

> Los frames de la presentación ya tienen placeholders con TikZ en su lugar.
> Cuando el mapa esté listo, sustituir la caja TikZ por `\includegraphics{img/<archivo>}`.

---

## Mapa 1 — Cobertura de Transporte Masivo (Isócrono 800 m)

**Archivo:** `mapa02_cobertura_sur.png`
**Destino en presentación:** `s02_seccion_problema.tex`, frame 2.2 "La Paradoja del Periférico"
**Columna:** izquierda (57% del ancho del frame), alto 5.5 cm keepaspectratio

### Descripción
Mapa de isócronos de 800 m desde cada parada de transporte masivo sobre toda la ZMVM.
Las zonas cubiertas (dentro del buffer) aparecen en color verde esmeralda o azul según modo.
Las zonas sin cobertura quedan en blanco/gris claro.
El **hueco visible en el sur** (Milpa Alta, Tlalpan, Xochimilco, Tláhuac, Magdalena Contreras)
es el argumento visual central del frame.

### Capas QGIS a usar
1. `LimitesPoliticos.gpkg` — alcaldías (fondo gris muy claro, bordes en gris medio)
2. `Transporte.gpkg` — paradas de todos los sistemas masivos (Metro, Metrobús, Tren Suburbano,
   Tren Ligero, Cablebús, Mexibús, Trolebús) — NO incluir microbus ni colectivo
3. Buffer 800 m desde las paradas → rasterizar o vectorizar como isócrono de cobertura
4. Periférico (desde `InfraEstructura.gpkg`) — resaltado en color acento para que el
   comité vea que el anillo vial existe pero no tiene transporte masivo

### Elementos cartográficos
- Título: "Cobertura de Transporte Masivo — ZMVM 2024"
- Norte y escala gráfica
- Fuente: "Elaboración propia con datos GTFS · SEMOVI 2024"
- Leyenda simplificada: "Zona cubierta (≤ 800 m)" / "Zona sin cobertura"
- Resaltar con etiqueta o flecha: "Milpa Alta: 11.75% de cobertura"

### Referencia
Dato fuente del mapa ya calculado en VFTModel Fase 1 (Cobertura C).
Archivo de resultado: revisar `analysis/` o `Tesis_Latex/Figures/Cap5/Cobertura/`.

---

## Mapa 2 — Red Esquemática de Transporte (Estilo Diagrama Oficial)

**Archivo:** `mapa_red_esquematica.png`
**Destino en presentación:** `s04_seccion_resultados_preeliminares.tex`, frame 4.3b
**Layout:** frame completo sin columnas, imagen centrada ~10.5 cm de ancho

### Descripción
Mapa estilizado del sistema de transporte de la ZMVM — diferente al grafo matemático
(panel1_infraestructura.png). Aquí el objetivo es que un comité no técnico reconozca
visualmente las rutas.
NO mostrar los 11,115 nodos topológicos — mostrar las **líneas simplificadas** por modo.

### Capas QGIS a usar (en este orden de renderizado, de abajo hacia arriba)
1. `LimitesPoliticos.gpkg` — alcaldías (fondo gris muy claro `#F5F5F5`, bordes `#CCCCCC`)
2. `LimitesPoliticos.gpkg` — municipios EDOMEX (fondo más claro, borde punteado)
3. `Transporte.gpkg` — líneas por modo, colores diferenciados:
   - Metro: rojo `#E63946`, grosor 1.5 px
   - Metrobús: naranja `#F4A261`, grosor 1.2 px
   - Tren Suburbano: azul marino `#1D3557`, grosor 1.2 px
   - Tren Ligero: verde oscuro `#2D6A4F`, grosor 1.2 px
   - Cablebús: morado `#7B2D8B`, grosor 1.0 px
   - Mexibús: amarillo ocre `#E9C46A`, grosor 1.0 px
   - Trolebús: verde claro `#52B788`, grosor 0.8 px
   - RTP: gris azulado `#6B7F9E`, grosor 0.8 px
4. `InfraEstructura.gpkg` — Periférico resaltado como referencia geográfica
   (línea punteada gris oscuro, sin relleno — para que el comité vea el "anillo vacío")

### Elementos cartográficos
- Título: "Sistema de Transporte Masivo — ZMVM 2024"
- Leyenda por modo (compacta, derecha inferior)
- Norte y escala gráfica
- Fuente: "Elaboración propia con datos GTFS · SEMOVI 2024 · Apimetro"
- Sin etiquetas de estaciones (serían ilegibles a esta escala)

---

## Mapa 3 — Mapa de Calor: Factor de Desviación Espacial

**Archivo:** `mapa_calor_df.png`
**Destino en presentación:** `s04_seccion_resultados_preeliminares.tex`, frame 4.10
**Layout:** frame completo sin columnas, imagen centrada

### Descripción
Heatmap (mapa de calor o coroplético por zona) que muestra la **distribución espacial
del Factor de Desviación** ($DF = d_\text{red} / d_E$) calculado por VFTModel Fase 1.
Las zonas rojas/naranjas tienen DF alto (rodeo severo).
Las zonas verdes tienen DF bajo (trayectos relativamente directos).

El mensaje visual: el rodeo no es un caso aislado (Caso 9) sino un **patrón estructural**
concentrado en el sur y el oriente de la ZMVM — las zonas sin cobertura de transporte masivo.

### Fuente de datos
- Resultados VFTModel Fase 1 por nodo: `DF` por par O-D de la muestra de 100 rutas (abril 2026)
- Archivo de resultados: buscar en `Tesis_Latex/Figures/Cap5/FactorDesviacion/` o en
  `analysis/` — el dato por nodo o por zona debe estar en los notebooks de resultados.
- Alternativamente: usar la muestra de 100 rutas y calcular DF promedio por alcaldía de origen.

### Opciones de representación
**Opción A (preferida si hay dato por nodo):** heatmap kernel sobre los nodos de origen
de la muestra, coloreado por valor DF. Rampa de color: verde (DF ≈ 1.0) → amarillo (DF ≈ 1.5) → rojo (DF ≥ 2.0).

**Opción B (si solo hay dato agregado por zona):** coroplético por alcaldía con DF promedio.
Misma rampa de color. Alcaldías sin dato en gris claro.

### Elementos cartográficos
- Título: "Factor de Desviación — Distribución Espacial (Fase 1)"
- Leyenda de rampa de color: "DF = 1.0 (directo)" → "DF ≥ 2.0 (rodeo severo)"
- Marcar con etiqueta: "Milpa Alta → Sta. Catarina: DF = 2.52" (Caso 9)
- Norte y escala gráfica
- Fuente: "Elaboración propia · VFTModel Fase 1 · muestra 100 rutas · abril 2026"

---

## Mapa 4 — Nodos Críticos: Centralidad de Intermediación B(v)

**Archivo:** `mapa04_nodos_criticos.png`
**Destino en presentación:** mencionado en el plan original de s04; puede agregarse
como frame adicional en la sección de resultados o sustituir a otro placeholder.

### Descripción
Mapa que muestra los nodos con mayor **Centralidad de Intermediación** $B(v)$ en la red.
Los nodos más críticos aparecen con burbujas o colores más intensos.
Nodos esperados con mayor B(v): Pantitlán, Indios Verdes, Tacubaya, Barranca del Muerto.

El mensaje: si uno de estos nodos falla (cierre por accidente, mantenimiento),
una fracción muy alta de los viajes de la ZMVM se interrumpe o se alarga.

### Fuente de datos
Este indicador es de **Fase 3 — AÚN NO CALCULADO**.
Si se desea incluir en el coloquio, usar como placeholder indicando que es "resultado esperado"
basado en la literatura y en los datos de FC (Fuerza Capilar) que sí están calculados.

Alternativamente: usar el mapa de FC (Fuerza Capilar) como proxy visual —
`Tesis_Latex/Figures/Cap5/FuerzaCapilar/Mapa/NB03_mapa03_macrohubs_periferico.png`
ya está disponible y muestra la misma concentración en los nodos periféricos críticos.

### Capas QGIS (si se genera en Fase 3)
1. Fondo de alcaldías
2. Nodos del grafo con símbolo proporcional a B(v) — rampa: blanco → naranja → rojo
3. Destacar los 10 nodos con mayor B(v) con etiqueta de nombre de estación
4. Periférico como referencia

### Elementos cartográficos
- Título: "Centralidad de Intermediación B(v) — Nodos Críticos"
- Leyenda de tamaño/color
- Etiquetas: Pantitlán, Indios Verdes, Tacubaya
- Fuente y nota: "Fase 3 — Resultado preliminar / esperado"

---

## Notas para la sesión que genere estos mapas

### Sustitución en la presentación
Cuando un mapa esté listo, abrir
`Trabajos-Maestria-Urbanismo/TercerSemestre/Coloquio2026-2/secciones/`
y en el frame correspondiente reemplazar el bloque TikZ placeholder por:
```latex
\includegraphics[width=\textwidth, height=5.5cm, keepaspectratio]{img/<archivo>.png}
```

### Verificar graphicspath en main.tex
El archivo `img/` de la presentación ya está en `\graphicspath`.
Si se usan rutas desde `Tesis_Latex/Figures/`, usar la ruta relativa completa:
`../../../Tesis_Latex/Figures/Cap5/...`

### Compilación
```bash
cd Trabajos-Maestria-Urbanismo/TercerSemestre/Coloquio2026-2/
pdflatex -interaction=nonstopmode main.tex
```
La presentación compila limpio (34 páginas) al 2026-05-29.
