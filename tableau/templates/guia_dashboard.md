# Plantilla Verde Esmeralda — Dashboard Multi-Gráfico

Para dashboards de resumen con 2–4 gráficos (vistas de anexo o presentación).
Más limpio que el SingleChart: sin panel de metadatos lateral, enfocado en los datos.

---

## Anatomía objetivo

```
┌──────────────────────────────────────────────────────────────┐
│  TÍTULO DEL DASHBOARD                                        │  ← Header #008250
│  UNAM · FES Acatlán · Maestría en Urbanismo · Sem. 2026-2   │
├──────────────────────────────────────────────────────────────┤  ← Franja #FFBA08 8px
│                          │                                   │
│   GRÁFICO 1              │   GRÁFICO 2                       │
│   (ej. Mapa de red)      │   (ej. Serie de tiempo)           │
│                          │                                   │
│                          ├───────────────────────────────────┤
│                          │   GRÁFICO 3                       │
│                          │   (ej. Bar chart top 10)          │
├──────────────────────────┴───────────────────────────────────┤
│  Leyenda Línea / Jerarquía Transporte                        │
├──────────────────────────────────────────────────────────────┤
│ Fuente: INEGI - APIMETRO / Elaboración propia · Sem. 2026-2  │  ← Footer #F5F6F8
└──────────────────────────────────────────────────────────────┘
```

---

## Dimensiones

| Configuración | Tamaño canvas | Cuándo usar |
|--------------|--------------|-------------|
| Dashboard estándar | 1122 × 794 px | A4 landscape — anexos tesis |
| Dashboard presentación | 1280 × 720 px | Proyector / Coloquio |
| Dashboard cuadrado | 900 × 900 px | Tableau Public embed |

---

## Tokens de diseño

Idénticos al SingleChart — ver [guia_single_chart.md](guia_single_chart.md) sección "Tokens de diseño".

Diferencia clave: **no hay panel derecho** ni "Datos del Plano".

---

## Paso a paso en Tableau Desktop

### 1. Preparar las hojas

Antes de construir el dashboard, todas las sheets que entrarán deben estar listas:
- Títulos descriptivos (ej. `Afluencia por Línea METRO (2010-2025)`)
- Paleta "Verde Esmeralda UNAM" activa
- Filtros configurados

### 2. Crear el dashboard

1. File → New Dashboard (ícono `+` en barra inferior)
2. **Size → Fixed → 1122 × 794** (A4 landscape)
3. Desmarca "Show dashboard title" (el título irá como Text container)

### 3. Header Verde Esmeralda

1. Objects → arrastra **Horizontal Container** al tope
2. Layout → **Fixed Height: `52`**
3. Dentro, arrastra **Text**
4. Text tile → Layout → **Background: `#008250`**
5. Doble clic en el texto:
   ```
   TÍTULO DEL DASHBOARD
   UNAM · FES Acatlán · Maestría en Urbanismo · Sem. 2026-2
   ```
6. Fuente: Arial 13pt Bold `#FFFFFF` (primera línea) / 7pt Regular `#FFFFFF` (segunda)
7. Alineación: centrado

### 4. Franja dorada

1. Objects → arrastra **Blank** debajo del Header
2. Layout → **Fixed Height: `8`**
3. Layout → **Background: `#FFBA08`**

### 5. Área de contenido

Construye el layout con Horizontal/Vertical Containers:

**Layout de 2 columnas (gráfico mapa + 2 gráficos derecha):**
```
Horizontal Container
├── Vertical Container izquierdo (~40% ancho)
│   └── Sheet: mapa/red
└── Vertical Container derecho (~60% ancho)
    ├── Sheet: serie de tiempo (Fixed Height ~381px)
    └── Horizontal Container
        └── Sheet: bar chart
```

**Layout de 2×2 (cuatro gráficos iguales):**
```
Vertical Container
├── Horizontal Container superior
│   ├── Sheet: gráfico 1
│   └── Sheet: gráfico 2
└── Horizontal Container inferior
    ├── Sheet: gráfico 3
    └── Sheet: gráfico 4
```

**Reglas de padding:**
- Outer Padding de todos los containers: `0`
- Inner Padding: `0`
- Margin individual de sheets: `4` (para respiración mínima)

### 6. Área de leyendas (opcional)

Si el dashboard incluye leyendas de color:
1. Clic en una sheet → flecha ▼ → Legends → Color Legend
2. Arrastrar las leyendas a un Horizontal Container debajo del contenido
3. Container → Layout → **Background: `#F0F2F5`** (gris claro, igual que paneles QGIS)
4. Fixed Height: `40–60px` dependiendo del número de ítems

### 7. Footer

1. Objects → arrastra **Text** debajo de las leyendas
2. Layout → **Fixed Height: `20`**
3. Layout → **Background: `#F5F6F8`**
4. Texto:
   ```
   Fuente: INEGI - APIMETRO / Elaboración propia  |  Sem. 2026-2
   ```
5. Fuente: Arial 6pt, color `#191919`, alineación centrada

### 8. Filtros y controles interactivos

Si el dashboard tiene filtros (sliders de año, checkboxes):
- Colocarlos **dentro del área de contenido**, no como tiles sueltos
- Eliminar los filter tiles que Tableau agrega automáticamente: clic en X de cada tile
- Usar filtros integrados dentro de cada sheet cuando sea posible

### 9. Guardar como plantilla

1. File → Save As → `tableau/templates/PlantillaBase_Dashboard_VerdeEsmeralda.twb`
2. Elimina las sheets del área de contenido (deja solo header, stripe, containers vacíos, footer)
3. Los containers vacíos son el punto de partida para arrastrar nuevas sheets

---

## Variante: Dashboard de 1 sheet

Para un gráfico solo que necesita el tratamiento completo de dashboard
(sin panel de metadatos del SingleChart, cuando la figura es más informal):

```
Header #008250 (52px)
Franja #FFBA08 (8px)
Sheet única (ocupa todo el espacio restante)
Footer #F5F6F8 (20px)
```

Usar cuando el gráfico se incluye en el cuerpo del texto de la tesis,
no en la sección de figuras formales. Si va en figuras formales → usar SingleChart.

---

## Checklist de validación antes de exportar

- [ ] Header fondo `#008250`, texto blanco, Arial
- [ ] Franja `#FFBA08`, 8px alto
- [ ] Contenido sin padding exterior (Outer Padding = 0 en todos los containers)
- [ ] Leyendas sobre fondo `#F0F2F5`
- [ ] Footer fondo `#F5F6F8`, 20px alto
- [ ] Sin filter tiles sueltos (X en tiles de filtros automáticos)
- [ ] Size fijo 1122×794 (no Automatic)
- [ ] Export → pdfcrop aplicado

---

## Diferencias respecto al SingleChart

| Elemento | SingleChart | Dashboard |
|----------|-------------|-----------|
| Panel derecho (metadatos) | Sí | No |
| Logos UNAM/FES | Sí | No |
| "Datos del Plano" | Sí | No |
| Área de leyendas | Con el gráfico | Container separado |
| Footer detalle | EPSG, proyección | Solo fuente y semestre |
| Ideal para | Figura de tesis | Anexo / presentación |

---

## Referencia de colores rápida

```
Header bg:     #008250
Stripe:        #FFBA08
Panel/legend:  #F0F2F5
Footer bg:     #F5F6F8
Separator:     #B4B9C3
Text dark:     #191919
Text on green: #FFFFFF
```
