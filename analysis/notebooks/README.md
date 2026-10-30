# analysis/notebooks/
Notebooks Jupyter para exploración de datos y prototipado de análisis.

Antes de mover lógica a `scripts/`, validar aquí con datos reales.

---

## `graficas_cap6.ipynb` — gráficas del Capítulo 6

Genera las gráficas comparativas del Cap. 6 de la tesis: Caso 1 (red actual), Caso 2 (Anillo MB) y Caso 3 (Anillo Metro), con la corrida VFTModel del 2026-10-04. La tesis (`../TesisUrbanismo`) no genera gráficas: solo incluye estos PDF con `\includegraphics`.

**Entradas** (solo lectura; el notebook no modifica datos ni exports):
- `tableau/exports/data/garibelt/escenario-{base,mb,metro}/fc_distribucion_*.csv` y `garibelt_perfil_*.csv`
- `tableau/exports/data/garibelt/comparativo/{bv_comparativo,transicion_bandas,distribucion_bandas,kpi_comparativo}.csv`
- `tableau/connectors/VFTModel/exports/{,scenario_mb/,scenario_metro/}wdc_t_escalar.csv`
- Repo hermano `../VFTModel/notebooks/ASSETS/t_distribucion/`: `t_histograma_*`, `t_resumen_*`, `t_comparativo_comun` y `t_comparativo_origen` (distribución de t_ij, generada por `08_Distribucion_T.ipynb`). Si VFTModel está en otra ruta, define `VFTMODEL_ROOT`

Si cambian los datos, se regeneran antes con `make export-all` y `make export-comparativo`.

**Salida:** `analysis/notebooks/output/cap6/`, en PDF vectorial (16 cm de ancho, fuentes incrustadas) y PNG de 300 dpi de respaldo.

| Gráfica | Sección | Archivo |
|---|---|---|
| G1 | §6.3.2 FC | `Grafica_FC_Estaciones_Anillo` |
| G2 | §6.3.2 FC | `Grafica_FC_Ganancia_Sistema` |
| G3 | §6.3.3 T | `Grafica_T_Casos` |
| G4 | §6.3.3 T | `Grafica_T_Distribucion` |
| G5 | §6.3.4 B(v) | `Grafica_BV_Lorenz` |
| G6 | §6.3.4 B(v) | `Grafica_BV_Alcaldias` |
| G7 | §6.4 Espectro MJG | `Grafica_Espectro_Transicion_Banda` |
| G8 | §6.3.3 T | `Grafica_T_Demarcacion` |

### Cómo ejecutarlo

Desde la raíz del repositorio:

```bash
# 1. Dependencias (una vez)
python3 -m venv .venv
.venv/bin/pip install pandas numpy matplotlib jupyter
# o bien: .venv/bin/pip install -r requirements.txt

# 2a. Interactivo
.venv/bin/jupyter lab analysis/notebooks/graficas_cap6.ipynb

# 2b. Sin interfaz: ejecuta todo y escribe las gráficas en output/cap6/
.venv/bin/jupyter nbconvert --to notebook --execute analysis/notebooks/graficas_cap6.ipynb \
  --output /tmp/graficas_cap6_ejecutado.ipynb
```

Con la opción 2b el notebook del repo queda sin salidas y la copia ejecutada va a `/tmp`.

**Kernel de otro proyecto.** También funciona con el servidor de Jupyter de `../VFTModel` (`VFTModel/.venv`, Python 3.12, pandas 3 y matplotlib 3.11). La primera celda encuentra la raíz del repo aunque el kernel arranque en otra carpeta. Busca en este orden:
1. La variable `TRANSPORT_GIS_ROOT`.
2. El archivo del notebook, cuando se abre en VS Code.
3. Las carpetas hacia arriba del directorio actual.
4. El repo hermano `Transport-gis-zmvm-mjg`.

Si no la encuentra, define `TRANSPORT_GIS_ROOT` o ejecuta `os.chdir("<ruta>/Transport-gis-zmvm-mjg")` antes de la primera celda.

**Cifras de control.** Antes de graficar, una celda verifica las cifras esperadas de cada gráfica: FC de las estaciones del anillo, ganancias por sistema, T, Gini, Tacubaya y transiciones. Para G4 y G8 verifica además la consistencia interna: % que suma 100, pares N(N−1), media de t_ij igual a T y media de Δ igual al ΔT del conjunto común. Si alguna no coincide, la ejecución se detiene con un `AssertionError` y no se escribe ninguna gráfica. En ese caso hay que revisar los datos, no ajustar el notebook.

**Convenciones.** Están definidas una sola vez en la celda «Estilo común»:
- Paleta por caso: Caso 1 en gris, Caso 2 en ColorAcento `#F4B400` y Caso 3 en ColorPrincipal `#003893`.
- Fuente sans de 9–11 pt y sin títulos dentro de la imagen, porque el título lo pone el `\caption`.
- Intervalos 0–0.25 / 0.25–0.50 / 0.50–0.75 / 0.75–1.0 en lugar de bandas cualitativas.

Cada gráfica tiene una celda con la fuente, los filtros, las cifras verificadas, un pie sugerido y, cuando aplica, cómo armarla en Tableau.

**Tipografía.** Usa Open Sans si está instalada (`setup/install_fonts.sh`). Si no, cae a Arial o DejaVu Sans.
