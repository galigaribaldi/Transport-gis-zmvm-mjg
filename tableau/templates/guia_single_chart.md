# Plantilla Verde Esmeralda — Figura Individual (SingleChart)

Replica la anatomía del template QGIS `PlantillaBase_VerdeEsmeralda_Vertical.qpt`
para gráficos Tableau que aparecen como figuras de tesis junto a los mapas QGIS.

---

## Anatomía objetivo

```
┌──────────────────────────────────────────────────────────────┐
│ [Logo UNAM 22×22]  TÍTULO DEL GRÁFICO          [Logo FES]   │  ← Header #008250
│                    UNAM · FES Acatlán · Maestría Urbanismo   │
├──────────────────────────────────────────────────────────────┤  ← Franja #FFBA08 8px
│                                    │ DESCRIPCIÓN             │
│                                    │─────────────────────────│
│   ÁREA DE CONTENIDO                │ Qué mide este gráfico   │
│   (sheet de Tableau)               │ y qué argumento apoya.  │
│                                    │─────────────────────────│
│                                    │ DATOS DEL PLANO         │
│                                    │ Alumno: H. G. Cabrera   │
│                                    │ Tutor: Dr. D. López     │
│                                    │ Semestre: 2026-2        │
│                                    │ Fecha: [Fecha]          │
├──────────────────────────────────────────────────────────────┤
│ Fuente: INEGI - APIMETRO / Elaboración propia                │  ← Footer #F5F6F8
└──────────────────────────────────────────────────────────────┘
```

---

## Dimensiones recomendadas

| Uso | Tamaño canvas | Equivale a |
|-----|--------------|------------|
| Figura de tesis (portrait) | 794 × 1122 px | A4 portrait a 96dpi |
| Figura de tesis (landscape) | 1122 × 794 px | A4 landscape a 96dpi |
| Presentación (landscape) | 1280 × 720 px | 720p / proyector |

---

## Tokens de diseño

| Elemento | Color | Hex | Fuente |
|----------|-------|-----|--------|
| Header background | Verde Esmeralda | `#008250` | `.qpt` línea 6 |
| Header text | Blanco | `#FFFFFF` | `.qpt` línea 13 |
| Accent stripe | Dorado UNAM | `#FFBA08` | `.qpt` línea 7 |
| Panel backgrounds | Gris claro | `#F0F2F5` | `.qpt` líneas 8-11 |
| Footer background | Gris muy claro | `#F5F6F8` | `.qpt` línea 12 |
| Separator line | Gris medio | `#B4B9C3` | `.qpt` línea 26 |
| Text body | Casi negro | `#191919` | `.qpt` general |
| Tipografía | Arial | — | `.qpt` todos los items |

---

## Paso a paso en Tableau Desktop

### 1. Crear el workbook base

1. File → New
2. Conecta tu fuente de datos
3. Construye la hoja (`Sheet 1`) con el gráfico
4. **Renombra la hoja** con el título del gráfico (ej. `Afluencia por Línea METRO`)

### 2. Crear el dashboard

1. Clic en el ícono `+` (New Dashboard) en la barra inferior
2. **Size → Fixed → 1122 × 794** (landscape) o 794 × 1122 (portrait)
3. Activa **"Show dashboard title"** → desmárcalo después (el título irá como Text container)

### 3. Construir el Header (Verde Esmeralda)

1. Desde Objects → arrastra **Horizontal Container** al tope del dashboard
2. Dentro del container, arrastra **Text**
3. Clic derecho en el container → **Edit Layout** → Fixed Height: `52`
4. Clic en el tile Text → Layout → **Background: `#008250`**
5. Doble clic en el texto → escribe:
   ```
   TÍTULO DEL GRÁFICO
   UNAM · FES Acatlán · Maestría en Urbanismo · Sem. 2026-2
   ```
6. Fuente: Arial, 13pt Bold, color `#FFFFFF` (primera línea) / 7pt Regular (segunda línea)
7. *Nota: los logos UNAM/FES se agregan como objetos Image dentro del mismo container*

### 4. Construir la franja dorada

1. Desde Objects → arrastra **Blank** debajo del Header container
2. Layout → Fixed Height: `8`
3. Layout → Background: `#FFBA08`

### 5. Construir el área de contenido

1. Desde Objects → arrastra **Horizontal Container** debajo de la franja
2. Dentro, arrastra tu sheet (`Sheet 1`) a la izquierda (~70% del ancho)
3. Arrastra **Vertical Container** a la derecha (~30% del ancho)

### 6. Construir el panel derecho (Descripción + Datos del Plano)

Dentro del Vertical Container derecho:

**Sección Descripción:**
1. Arrastra **Text** → Background: `#F0F2F5`
2. Escribe la descripción del gráfico (qué mide, qué argumento apoya)
3. Fuente: Arial 8pt, color `#191919`

**Separador:**
1. Arrastra **Blank** → Fixed Height: `2` → Background: `#B4B9C3`

**Sección Datos del Plano:**
1. Arrastra **Text** → Background: `#F0F2F5`
2. Escribe:
   ```
   DATOS DEL PLANO
   Alumno: Hernán Galileo Cabrera Garibaldi
   Tutor: Dr. David López Flores
   Semestre: 2026-2
   Fecha: [Fecha]
   ```
3. Fuente: Arial 7pt, color `#191919`; "DATOS DEL PLANO" en Bold

### 7. Construir el Footer

1. Desde Objects → arrastra **Text** debajo del área de contenido
2. Layout → Fixed Height: `24`
3. Layout → Background: `#F5F6F8`
4. Texto:
   ```
   Fuente: INEGI - APIMETRO / Elaboración propia  |  Sistema: WGS 84 UTM Zona 14N (EPSG:32614)  |  Sem. 2026-2
   ```
5. Fuente: Arial 6pt, color `#191919`

### 8. Aplicar la paleta de colores

Antes de formatear colores del gráfico:
1. Copia `tableau/templates/VerdeEsmeralda.tps` a `~/Documents/My Tableau Repository/Preferences.tps`
   (si ya existe un Preferences.tps, fusiona el bloque `<color-palette>`)
2. Reinicia Tableau Desktop
3. En cualquier color picker → paleta desplegable → busca **"Verde Esmeralda UNAM"**

### 9. Guardar como plantilla

Una vez construido el primer dashboard individual:

1. File → Save As → `tableau/templates/PlantillaBase_SingleChart_VerdeEsmeralda.twb`
2. Borra el contenido de la sheet (los datos) pero deja la estructura de containers
3. Este `.twb` será tu punto de partida para futuros gráficos individuales

---

## Checklist de validación antes de exportar

- [ ] Header fondo `#008250`, texto blanco, Arial 13pt Bold / 7pt Regular
- [ ] Franja dorada `#FFBA08`, 8px alto
- [ ] Panel derecho fondo `#F0F2F5`, texto `#191919`
- [ ] Separador `#B4B9C3`
- [ ] Footer fondo `#F5F6F8`, texto 6pt
- [ ] Paleta "Verde Esmeralda UNAM" activa en el gráfico
- [ ] Título del dashboard vacío (el texto va en el Text container, no en el título nativo)
- [ ] Export: pdfcrop aplicado (`pdfcrop --margins 10 input.pdf output.pdf`)

---

## Referencia de colores rápida (copia-pega en Tableau)

```
Header bg:     #008250
Stripe:        #FFBA08
Panel bg:      #F0F2F5
Footer bg:     #F5F6F8
Separator:     #B4B9C3
Text dark:     #191919
Text on green: #FFFFFF
```
