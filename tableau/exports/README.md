# tableau/exports/

Artefactos finales exportados desde Tableau Desktop para publicación en el repositorio.
Mismo rol que `maps/exports/` para QGIS — la diferencia es que aquí son dashboards estadísticos.

---

## Subdirectorios

```
exports/
  pdf/    ← PDFs de cada dashboard completo
  img/    ← PNGs de vistas individuales (para embeber en tesis o presentación)
  web/    ← Referencias a publicaciones en Tableau Public
```

---

## Convención de nombres

Misma convención que mapas: `<proyecto>_viz<##>_<descripcion>.<ext>`

| Ejemplo | Qué contiene |
|---------|-------------|
| `col2026-2_viz01_cobertura.pdf` | Dashboard completo de cobertura |
| `col2026-2_viz02_factor_desviacion.png` | Vista de distribución del DF |
| `col2026-2_viz04_red_apimetro.pdf` | Dashboard de estadísticas de red |

---

## Cómo exportar desde Tableau Desktop

### PDF
```
Archivo → Exportar como PDF
  → Rango: Toda la historia / Hoja actual
  → Papel: A4 o Carta, apaisado
  → Guardar en: tableau/exports/pdf/<nombre>.pdf
```

### Imagen (PNG)
```
Archivo → Exportar como imagen
  → Resolución: 200 DPI
  → Guardar en: tableau/exports/img/<nombre>.png
```

### Web (Tableau Public)
Publicar en Tableau Public y guardar la URL en `exports/web/<nombre>.url.txt`.
El archivo `.url.txt` es un texto de una línea con la URL pública del dashboard.

---

## Automatización con tabcmd

Para exportar en lote sin abrir Tableau Desktop, usar el script:
```bash
bash tableau/scripts/export_tabcmd.sh
```

Ver `tableau/scripts/README.md` para configuración de `tabcmd`.
