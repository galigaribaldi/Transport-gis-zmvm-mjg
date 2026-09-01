# tableau/scripts/

Scripts de automatización de exports. No contienen lógica de conexión a APIs
(eso lo hacen los WDC en `../connectors/`).

---

## export_tabcmd.sh

Exporta en lote los workbooks publicados en Tableau Server o Tableau Public
usando la herramienta de línea de comandos `tabcmd`.

`tabcmd` es la CLI oficial de Tableau para automatizar exports sin abrir Tableau Desktop.
Disponible como parte de Tableau Server o como descarga separada.

### Instalación de tabcmd

```bash
# macOS con Homebrew
brew install tabcmd   # si está disponible
# o descargar el instalador desde:
# https://www.tableau.com/support/releases/tabcmd
```

### Uso

```bash
# Exportar todos los dashboards definidos en el script
bash tableau/scripts/export_tabcmd.sh

# El script hace login, exporta cada workbook y desconecta
# Requiere variables de entorno configuradas en .env.local:
#   TABLEAU_SERVER=https://public.tableau.com
#   TABLEAU_USER=tu_usuario
#   TABLEAU_PASSWORD=tu_password (o usar token)
```

### Qué exporta el script

| Workbook | PDF destino | PNG destino |
|----------|-------------|-------------|
| `col2026-2_viz01_cobertura` | `exports/pdf/col2026-2_viz01_cobertura.pdf` | `exports/img/col2026-2_viz01_cobertura.png` |
| `col2026-2_viz02_factor_desviacion` | `exports/pdf/col2026-2_viz02_factor_desviacion.pdf` | `exports/img/col2026-2_viz02_factor_desviacion.png` |
| `col2026-2_viz03_fuerza_capilar` | `exports/pdf/col2026-2_viz03_fuerza_capilar.pdf` | `exports/img/col2026-2_viz03_fuerza_capilar.png` |
| `col2026-2_viz04_red_apimetro` | `exports/pdf/col2026-2_viz04_red_apimetro.pdf` | `exports/img/col2026-2_viz04_red_apimetro.png` |

---

> Para exports manuales desde Tableau Desktop, ver `../exports/README.md`.
