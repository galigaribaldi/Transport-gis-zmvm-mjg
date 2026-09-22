# Makefile — raíz del repositorio
# Transportes Anillares y su importancia en la CDMX y ZMVM
#
# Flujo de 5 pasos:
#   1. check       → verificar conexiones y servidores activos
#   2. warmup      → calentar los grafos en caché (VFTModel)
#   3. export-all  → generar fuentes de datos (GeoJSON, GPKG, conectores)
#   4. workbooks   → generar/actualizar archivos Tableau; QGIS es manual
#   5. verify      → revisar integridad de todo el pipeline
#
# Atajos:
#   make help      → lista de todos los targets
#   make guide     → guía descriptiva del flujo completo
#   make verify    → verificación integral (todos los pasos)

PYTHON   ?= .venv/bin/python
EXPORTS   = utils/generate_exports.py
COPY_WB   = utils/copy_workbook_scenario.py
GEO_DIR   = tableau/exports/geo
WB_DIR    = tableau/workbooks

.PHONY: all help guide \
        check \
        warmup warmup-all warmup-scenarios \
        warmup-baseline warmup-mb warmup-metro \
        _warmup-port \
        export-all export-baseline export-mb export-metro \
        export-lineas export-lineas-baseline export-lineas-mb export-lineas-metro \
        workbooks serve \
        verify verify-step-1 verify-step-2 verify-step-3 verify-step-4 verify-step-5

# ══════════════════════════════════════════════════════════════════════════════
#  FLUJO COMPLETO
# ══════════════════════════════════════════════════════════════════════════════

all: check warmup-all export-all export-lineas workbooks verify

# ══════════════════════════════════════════════════════════════════════════════
#  PASO 1 — Verificar conexiones y servidores
# ══════════════════════════════════════════════════════════════════════════════

check:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 1 — Verificando servicios activos"
	@echo "══════════════════════════════════════════════════════════"
	@echo "  Apimetro:"
	@curl -s --max-time 5 http://localhost:8080/health > /dev/null 2>&1 \
		&& echo "    :8080  baseline  ✓ activo" \
		|| echo "    :8080  baseline  ✗ inactivo  →  make dev  (repo Apimetro)"
	@curl -s --max-time 5 http://localhost:8083/health > /dev/null 2>&1 \
		&& echo "    :8083  MB        ✓ activo" \
		|| echo "    :8083  MB        ✗ inactivo  →  make docker-dev-scenario-mb  (repo Apimetro)"
	@curl -s --max-time 5 http://localhost:8084/health > /dev/null 2>&1 \
		&& echo "    :8084  METRO     ✓ activo" \
		|| echo "    :8084  METRO     ✗ inactivo  →  make docker-dev-scenario-metro  (repo Apimetro)"
	@echo "  VFTModel:"
	@curl -sf --max-time 8 \
		"http://localhost:8000/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		> /dev/null 2>&1 \
		&& echo "    :8000  baseline  ✓ activo" \
		|| echo "    :8000  baseline  ✗ inactivo  →  make run  (repo VFTModel, instancia baseline)"
	@curl -sf --max-time 8 \
		"http://localhost:8001/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		> /dev/null 2>&1 \
		&& echo "    :8001  MB        ✓ activo" \
		|| echo "    :8001  MB        ✗ inactivo  →  make run-scenario-mb  (repo VFTModel)"
	@curl -sf --max-time 8 \
		"http://localhost:8002/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		> /dev/null 2>&1 \
		&& echo "    :8002  METRO     ✓ activo" \
		|| echo "    :8002  METRO     ✗ inactivo  →  make run-scenario-metro  (repo VFTModel)"
	@echo "  WDC Server:"
	@curl -sf --max-time 3 http://localhost:5050/ > /dev/null 2>&1 \
		&& echo "    :5050  WDC       ✓ activo" \
		|| echo "    :5050  WDC       ✗ inactivo  →  make serve  (en otra terminal)"
	@echo ""

verify-step-1: check

# ══════════════════════════════════════════════════════════════════════════════
#  PASO 2 — Calentar grafos en caché
# ══════════════════════════════════════════════════════════════════════════════
# Con caché activo todos los endpoints responden en <100 ms → Tableau no hace
# timeout al crear o refrescar un extracto .hyper.
# Tiempos sin caché (primera llamada del día):
#   build-auto:       < 1 min
#   T (travel-time):  2-5 min
#   B (betweenness):  5-8 min  ← el más lento con ~11 k nodos
#   DF (detour):      30-60 s

# Helper interno — requiere PORT=XXXX, no llamar directamente
_warmup-port:
	@echo "  [1/4] build-auto..."
	@curl -s --max-time 60 \
		"http://localhost:$(PORT)/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', d.get('nodos','?'), 'nodos,', d.get('aristas','?'), 'aristas')" 2>/dev/null \
		|| { echo "        ERROR: VFTModel :$(PORT) no responde. Verificar con make check."; exit 1; }
	@echo "  [2/4] average-travel-time (T) — puede tardar 2-5 min..."
	@curl -s --max-time 360 \
		"http://localhost:$(PORT)/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print('        OK — T =', d.get('T_average_travel_time_minutes','?'), 'min')" 2>/dev/null \
		|| echo "        WARN: timeout o fallo en T."
	@echo "  [3/4] betweenness-centrality (B) — puede tardar 5-8 min primera vez..."
	@curl -s --max-time 600 \
		"http://localhost:$(PORT)/api/v1/network/geolayers/betweenness?layer=b_puntos&limit=2000" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', d.get('metadata',{}).get('n_features','?'), 'nodos rankeados')" 2>/dev/null \
		|| echo "        WARN: timeout en B (B(v) no en caché — el extracto Tableau puede tardar)."
	@echo "  [4/4] detour-factor (DF) — puede tardar 30-60 s..."
	@curl -s --max-time 120 \
		"http://localhost:$(PORT)/api/v1/network/geolayers/detour?layer=df_puntos&sample_size=100&seed=42" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', len(d.get('features',[])), 'rutas O-D')" 2>/dev/null \
		|| echo "        WARN: timeout en DF."

warmup-baseline:
	@echo "── Calentando Baseline (:8000) ──────────────────────────────"
	@$(MAKE) _warmup-port PORT=8000
	@echo "  Baseline: caché listo."
	@echo ""

warmup-mb:
	@echo "── Calentando Escenario MB (:8001) ──────────────────────────"
	@$(MAKE) _warmup-port PORT=8001
	@echo "  MB: caché listo."
	@echo ""

warmup-metro:
	@echo "── Calentando Escenario METRO (:8002) ───────────────────────"
	@$(MAKE) _warmup-port PORT=8002
	@echo "  METRO: caché listo."
	@echo ""

warmup: warmup-baseline

warmup-scenarios: warmup-mb warmup-metro

warmup-all:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 2 — Calentando los 3 escenarios (~45 min total)"
	@echo "══════════════════════════════════════════════════════════"
	@$(MAKE) warmup-baseline
	@$(MAKE) warmup-mb
	@$(MAKE) warmup-metro
	@echo "Los 3 escenarios están en caché."
	@echo ""

verify-step-2:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 2 — Verificando caché de grafos (T por escenario)"
	@echo "══════════════════════════════════════════════════════════"
	@curl -s --max-time 10 \
		"http://localhost:8000/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes'); print('    Baseline  :8000  T =', t, 'min  ✓' if t else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    Baseline  :8000  ✗ inactivo o sin caché"
	@curl -s --max-time 10 \
		"http://localhost:8001/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes'); print('    MB        :8001  T =', t, 'min  ✓' if t else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    MB        :8001  ✗ inactivo o sin caché"
	@curl -s --max-time 10 \
		"http://localhost:8002/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes'); print('    METRO     :8002  T =', t, 'min  ✓' if t else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    METRO     :8002  ✗ inactivo o sin caché"
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
#  PASO 3 — Generar fuentes de datos (GeoJSON, GPKG, conectores)
# ══════════════════════════════════════════════════════════════════════════════

export-baseline:
	@echo "── Exportando Baseline (:8000) ──────────────────────────────"
	$(PYTHON) $(EXPORTS) --url http://localhost:8000 --scenario baseline

export-mb:
	@echo "── Exportando Escenario MB (:8001) ──────────────────────────"
	$(PYTHON) $(EXPORTS) --url http://localhost:8001 --scenario scenario_mb

export-metro:
	@echo "── Exportando Escenario METRO (:8002) ───────────────────────"
	$(PYTHON) $(EXPORTS) --url http://localhost:8002 --scenario scenario_metro

# Descargar lineas.geojson y poligonos.geojson desde Apimetro (reflejan la red del escenario)
export-lineas-baseline:
	@mkdir -p $(GEO_DIR)
	@echo "  Descargando lineas.geojson baseline (:8080)..."
	@curl -sf --max-time 30 "http://localhost:8080/movilidad/mapas/geojsonLinea" \
		-o $(GEO_DIR)/lineas.geojson \
		&& echo "  ✓ $(GEO_DIR)/lineas.geojson" \
		|| echo "  ✗ Error: Apimetro :8080 no disponible"
	@echo "  Descargando poligonos.geojson baseline (:8080)..."
	@curl -sf --max-time 30 "http://localhost:8080/movilidad/mapas/geojsonPoligono" \
		-o $(GEO_DIR)/poligonos.geojson \
		&& echo "  ✓ $(GEO_DIR)/poligonos.geojson" \
		|| echo "  ✗ Error: Apimetro :8080 no disponible"

export-lineas-mb:
	@mkdir -p $(GEO_DIR)/scenario_mb
	@echo "  Descargando lineas.geojson MB (:8083)..."
	@curl -sf --max-time 30 "http://localhost:8083/movilidad/mapas/geojsonLinea" \
		-o $(GEO_DIR)/scenario_mb/lineas.geojson \
		&& echo "  ✓ $(GEO_DIR)/scenario_mb/lineas.geojson" \
		|| echo "  ✗ Error: Apimetro :8083 no disponible"
	@curl -sf --max-time 30 "http://localhost:8083/movilidad/mapas/geojsonPoligono" \
		-o $(GEO_DIR)/scenario_mb/poligonos.geojson \
		&& echo "  ✓ $(GEO_DIR)/scenario_mb/poligonos.geojson" \
		|| echo "  ✗ Error: Apimetro :8083 no disponible"

export-lineas-metro:
	@mkdir -p $(GEO_DIR)/scenario_metro
	@echo "  Descargando lineas.geojson METRO (:8084)..."
	@curl -sf --max-time 30 "http://localhost:8084/movilidad/mapas/geojsonLinea" \
		-o $(GEO_DIR)/scenario_metro/lineas.geojson \
		&& echo "  ✓ $(GEO_DIR)/scenario_metro/lineas.geojson" \
		|| echo "  ✗ Error: Apimetro :8084 no disponible"
	@curl -sf --max-time 30 "http://localhost:8084/movilidad/mapas/geojsonPoligono" \
		-o $(GEO_DIR)/scenario_metro/poligonos.geojson \
		&& echo "  ✓ $(GEO_DIR)/scenario_metro/poligonos.geojson" \
		|| echo "  ✗ Error: Apimetro :8084 no disponible"

export-lineas: export-lineas-baseline export-lineas-mb export-lineas-metro

export-all:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 3 — Exportando fuentes de datos (3 escenarios)"
	@echo "══════════════════════════════════════════════════════════"
	@$(MAKE) export-baseline
	@$(MAKE) export-mb
	@$(MAKE) export-metro
	@echo ""
	@echo "  Exportando GeoJSONs Apimetro (lineas + polígonos)..."
	@$(MAKE) export-lineas
	@echo ""

verify-step-3:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 3 — Verificando fuentes de datos generadas"
	@echo "══════════════════════════════════════════════════════════"
	@echo "  GeoJSONs VFTModel (b_puntos, df_puntos, fc_puntos):"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/b_puntos.geojson')); print('    baseline/b_puntos.geojson       ', len(d['features']), 'features')" 2>/dev/null || echo "    baseline/b_puntos.geojson        ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/df_puntos.geojson')); print('    baseline/df_puntos.geojson      ', len(d['features']), 'features')" 2>/dev/null || echo "    baseline/df_puntos.geojson       ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/fc_puntos.geojson')); print('    baseline/fc_puntos.geojson      ', len(d['features']), 'features')" 2>/dev/null || echo "    baseline/fc_puntos.geojson       ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_mb/b_puntos.geojson')); print('    scenario_mb/b_puntos.geojson    ', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_mb/b_puntos.geojson     ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_mb/df_puntos.geojson')); print('    scenario_mb/df_puntos.geojson   ', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_mb/df_puntos.geojson    ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_mb/fc_puntos.geojson')); print('    scenario_mb/fc_puntos.geojson   ', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_mb/fc_puntos.geojson    ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_metro/b_puntos.geojson')); print('    scenario_metro/b_puntos.geojson ', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_metro/b_puntos.geojson  ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_metro/df_puntos.geojson')); print('    scenario_metro/df_puntos.geojson', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_metro/df_puntos.geojson ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_metro/fc_puntos.geojson')); print('    scenario_metro/fc_puntos.geojson', len(d['features']), 'features')" 2>/dev/null || echo "    scenario_metro/fc_puntos.geojson ✗ no existe"
	@echo "  GeoJSONs Apimetro (lineas — baseline:668, escenarios:676):"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/lineas.geojson')); n=len(d['features']); ok='✓' if n==668 else '?'; print(f'    baseline/lineas.geojson         {n} features {ok}')" 2>/dev/null || echo "    baseline/lineas.geojson          ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_mb/lineas.geojson')); n=len(d['features']); ok='✓' if n==676 else '✗ esperado 676'; print(f'    scenario_mb/lineas.geojson      {n} features {ok}')" 2>/dev/null || echo "    scenario_mb/lineas.geojson       ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_metro/lineas.geojson')); n=len(d['features']); ok='✓' if n==676 else '✗ esperado 676'; print(f'    scenario_metro/lineas.geojson   {n} features {ok}')" 2>/dev/null || echo "    scenario_metro/lineas.geojson    ✗ no existe"
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
#  PASO 4 — Generar archivos de Tableau y notas QGIS
# ══════════════════════════════════════════════════════════════════════════════

workbooks:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 4 — Generando workbooks Tableau de escenarios"
	@echo "══════════════════════════════════════════════════════════"
	$(PYTHON) $(COPY_WB) scenario_mb
	$(PYTHON) $(COPY_WB) scenario_metro
	@echo ""

# Servidor HTTP para los WDC — dejar corriendo mientras se trabaja en Tableau Desktop
serve:
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "  WDC Server → http://localhost:5050"
	@echo ""
	@echo "  Conectores disponibles:"
	@echo "    Apimetro  → http://localhost:5050/connectors/apimetro/apimetro_wdc.html"
	@echo "    VFTModel  → http://localhost:5050/connectors/VFTModel/vft_wdc.html"
	@echo ""
	@echo "  Detener con Ctrl+C"
	@echo "──────────────────────────────────────────────────────────"
	cd tableau && python3 -m http.server 5050

verify-step-4:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 4 — Verificando workbooks Tableau"
	@echo "══════════════════════════════════════════════════════════"
	@echo "  Existencia de TWBs:"
	@test -f $(WB_DIR)/dashboard_viz04_red_vftmodel.twb \
		&& echo "    ✓ dashboard_viz04_red_vftmodel.twb" \
		|| echo "    ✗ dashboard_viz04_red_vftmodel.twb  FALTA"
	@test -f $(WB_DIR)/dashboard_viz04_red_vftmodel_scenario_mb.twb \
		&& echo "    ✓ dashboard_viz04_red_vftmodel_scenario_mb.twb" \
		|| echo "    ✗ dashboard_viz04_red_vftmodel_scenario_mb.twb  FALTA"
	@test -f $(WB_DIR)/dashboard_viz04_red_vftmodel_scenario_metro.twb \
		&& echo "    ✓ dashboard_viz04_red_vftmodel_scenario_metro.twb" \
		|| echo "    ✗ dashboard_viz04_red_vftmodel_scenario_metro.twb  FALTA"
	@test -f $(WB_DIR)/dashboard_viz04_red_apimetro.twb \
		&& echo "    ✓ dashboard_viz04_red_apimetro.twb" \
		|| echo "    ✗ dashboard_viz04_red_apimetro.twb  FALTA"
	@test -f $(WB_DIR)/dashboard_viz04_red_apimetro_scenario_mb.twb \
		&& echo "    ✓ dashboard_viz04_red_apimetro_scenario_mb.twb" \
		|| echo "    ✗ dashboard_viz04_red_apimetro_scenario_mb.twb  FALTA"
	@test -f $(WB_DIR)/dashboard_viz04_red_apimetro_scenario_metro.twb \
		&& echo "    ✓ dashboard_viz04_red_apimetro_scenario_metro.twb" \
		|| echo "    ✗ dashboard_viz04_red_apimetro_scenario_metro.twb  FALTA"
	@echo "  Puertos en TWBs de escenario:"
	@grep -l "localhost:8001" $(WB_DIR)/*.twb 2>/dev/null | xargs -I{} basename {} | sed 's/^/    :8001  /' || echo "    ✗ Ningún TWB contiene :8001"
	@grep -l "localhost:8002" $(WB_DIR)/*.twb 2>/dev/null | xargs -I{} basename {} | sed 's/^/    :8002  /' || echo "    ✗ Ningún TWB contiene :8002"
	@grep -l "localhost:8083" $(WB_DIR)/*.twb 2>/dev/null | xargs -I{} basename {} | sed 's/^/    :8083  /' || echo "    ✗ Ningún TWB contiene :8083"
	@grep -l "localhost:8084" $(WB_DIR)/*.twb 2>/dev/null | xargs -I{} basename {} | sed 's/^/    :8084  /' || echo "    ✗ Ningún TWB contiene :8084"
	@echo "  QGIS (apertura manual en QGIS Desktop):"
	@ls maps/projects/*.qgz 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || echo "    Sin proyectos .qgz en maps/projects/"
	@echo "  Capas de escenario disponibles para QGIS:"
	@ls data/processed/scenarios/VFTOutput_*.gpkg 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || echo "    ✗ Sin GPKGs en data/processed/scenarios/"
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
#  PASO 5 — Verificar integridad global
# ══════════════════════════════════════════════════════════════════════════════

verify-step-5:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 5 — Verificación de integridad global"
	@echo "══════════════════════════════════════════════════════════"
	@echo "  T de referencia (CSV indicadores_comparativo.csv):"
	@python3 -c "import csv; [print(f'    {r[\"escenario_label\"]:12s}  T = {r[\"T_min\"]} min  ({r[\"nodos\"]} nodos, dnodos={r[\"nodos_delta\"]})') for r in csv.DictReader(open('tableau/exports/data/indicadores_comparativo.csv'))]" 2>/dev/null || echo "    ✗ CSV no encontrado"
	@echo "  T en vivo desde VFTModel (requiere caché activo):"
	@curl -s --max-time 10 \
		"http://localhost:8000/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes','?'); print('    Baseline  :8000  T =', t, 'min')" 2>/dev/null \
		|| echo "    Baseline  :8000  ✗ inactivo o sin caché"
	@curl -s --max-time 10 \
		"http://localhost:8001/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes','?'); print('    MB        :8001  T =', t, 'min')" 2>/dev/null \
		|| echo "    MB        :8001  ✗ inactivo o sin caché"
	@curl -s --max-time 10 \
		"http://localhost:8002/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); t=d.get('T_average_travel_time_minutes','?'); print('    METRO     :8002  T =', t, 'min')" 2>/dev/null \
		|| echo "    METRO     :8002  ✗ inactivo o sin caché"
	@echo "  Mejoras esperadas (vs CSV):"
	@echo "    MB vs Baseline:    −4.18 min  (104.74 vs 108.92)"
	@echo "    METRO vs Baseline: −10.80 min ( 98.12 vs 108.92)"
	@echo "  Lineas Apimetro (baseline:668, escenarios con anillo:676):"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/lineas.geojson'))['features']); print('    baseline:      ', n, 'lineas', '✓' if n==668 else '✗')" 2>/dev/null || echo "    baseline lineas.geojson ✗ no existe"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/scenario_mb/lineas.geojson'))['features']); print('    scenario_mb:   ', n, 'lineas', '✓' if n==676 else '✗ (esperado 676)')" 2>/dev/null || echo "    scenario_mb lineas.geojson ✗ no existe"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/scenario_metro/lineas.geojson'))['features']); print('    scenario_metro:', n, 'lineas', '✓' if n==676 else '✗ (esperado 676)')" 2>/dev/null || echo "    scenario_metro lineas.geojson ✗ no existe"
	@echo ""

verify: verify-step-1 verify-step-2 verify-step-3 verify-step-4 verify-step-5

# ══════════════════════════════════════════════════════════════════════════════
#  AYUDA Y GUÍA
# ══════════════════════════════════════════════════════════════════════════════

help:
	@echo ""
	@echo "Transportes Anillares — Pipeline de análisis comparativo"
	@echo "══════════════════════════════════════════════════════════"
	@echo ""
	@echo "FLUJO COMPLETO"
	@echo "  make all                Ejecutar los 5 pasos en secuencia"
	@echo ""
	@echo "PASO 1 — Conexiones"
	@echo "  make check              Verificar qué servidores están activos"
	@echo "  make verify-step-1      (alias de check)"
	@echo ""
	@echo "PASO 2 — Calentar grafos  (~10 min/escenario, solo si no hay caché)"
	@echo "  make warmup             Calentar solo baseline (:8000)"
	@echo "  make warmup-all         Los 3 escenarios en secuencia (~45 min)"
	@echo "  make warmup-baseline    Solo baseline (:8000)"
	@echo "  make warmup-mb          Solo escenario MB (:8001)"
	@echo "  make warmup-metro       Solo escenario METRO (:8002)"
	@echo "  make warmup-scenarios   MB + METRO (sin baseline)"
	@echo "  make verify-step-2      Ver T actual de cada escenario"
	@echo ""
	@echo "PASO 3 — Generar fuentes de datos"
	@echo "  make export-all         GeoJSONs + GPKGs + lineas (3 escenarios)"
	@echo "  make export-baseline    Solo VFTModel baseline (:8000)"
	@echo "  make export-mb          Solo VFTModel MB (:8001)"
	@echo "  make export-metro       Solo VFTModel METRO (:8002)"
	@echo "  make export-lineas      lineas.geojson + poligonos.geojson (3 Apimetro)"
	@echo "  make verify-step-3      Contar features en todos los archivos"
	@echo ""
	@echo "PASO 4 — Archivos de trabajo"
	@echo "  make workbooks          Generar TWBs de escenario (MB + METRO)"
	@echo "  make serve              Levantar WDC server en :5050 (otra terminal)"
	@echo "  make verify-step-4      Verificar TWBs y proyectos QGIS"
	@echo ""
	@echo "PASO 5 — Integridad"
	@echo "  make verify             Verificación completa (todos los pasos)"
	@echo "  make verify-step-5      Solo integridad global (T, features, CSV)"
	@echo ""
	@echo "OTROS"
	@echo "  make guide              Guía descriptiva del flujo de trabajo"
	@echo "  make help               Esta pantalla"
	@echo ""

guide:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  GUÍA DE TRABAJO — Análisis Comparativo de Escenarios"
	@echo "  Tesis: Transportes Anillares y su importancia CDMX/ZMVM"
	@echo "══════════════════════════════════════════════════════════"
	@echo ""
	@echo "PREREQUISITOS — Los 7 servicios deben estar corriendo:"
	@echo "  Apimetro baseline       make dev                (repo Apimetro, :8080)"
	@echo "  Apimetro MB             make docker-dev-scenario-mb  (:8083)"
	@echo "  Apimetro METRO          make docker-dev-scenario-metro (:8084)"
	@echo "  VFTModel baseline       make run                (repo VFTModel, :8000)"
	@echo "  VFTModel MB             make run-scenario-mb    (:8001)"
	@echo "  VFTModel METRO          make run-scenario-metro (:8002)"
	@echo "  WDC server              make serve  ← en esta terminal, dejar corriendo"
	@echo ""
	@echo "────────────────────────────────────────────────────────"
	@echo "PASO 1 — VERIFICAR CONEXIONES"
	@echo "  $$ make check"
	@echo "  Confirma qué instancias están activas. Si alguna falla, levantar"
	@echo "  el servicio correspondiente antes de continuar."
	@echo ""
	@echo "PASO 2 — CALENTAR GRAFOS  (primera sesión del día, ~45 min total)"
	@echo "  $$ make warmup-all"
	@echo "  Precarga T, B(v) y DF en memoria para los 3 escenarios."
	@echo "  Con caché activo todos los endpoints responden en <100 ms, lo que"
	@echo "  evita timeouts al crear o refrescar extractos .hyper en Tableau."
	@echo "  Para verificar: make verify-step-2"
	@echo ""
	@echo "PASO 3 — GENERAR FUENTES DE DATOS  (solo cuando los datos cambian)"
	@echo "  $$ make export-all      # GeoJSONs y GPKGs desde VFTModel"
	@echo "  $$ make export-lineas   # lineas.geojson y poligonos.geojson desde Apimetro"
	@echo "  Los GeoJSONs de escenario van a:"
	@echo "    tableau/exports/geo/scenario_mb/   y   .../scenario_metro/"
	@echo "  Los GPKGs de escenario van a:"
	@echo "    data/processed/scenarios/VFTOutput_scenario_*.gpkg"
	@echo "  Para verificar feature counts: make verify-step-3"
	@echo ""
	@echo "PASO 4 — GENERAR ARCHIVOS DE TRABAJO"
	@echo "  $$ make workbooks"
	@echo "  Copia y adapta los workbooks baseline → escenarios MB y METRO,"
	@echo "  actualizando puertos WDC y rutas de GeoJSON en cada TWB."
	@echo "  Abre los TWBs en Tableau Desktop y recrea los extractos .hyper."
	@echo ""
	@echo "  QGIS (paso manual — no automatizable desde CLI):"
	@echo "    1. Abrir maps/projects/*.qgz en QGIS Desktop"
	@echo "    2. Refrescar capa: data/processed/scenarios/VFTOutput_scenario_*.gpkg"
	@echo "    3. Exportar PNG → maps/exports/"
	@echo ""
	@echo "PASO 5 — VERIFICAR INTEGRIDAD"
	@echo "  $$ make verify"
	@echo "  Comprueba: servidores activos, T por escenario vs CSV de referencia,"
	@echo "  conteo de features en GeoJSONs, existencia de todos los TWBs y"
	@echo "  puertos correctos en los workbooks de escenario."
	@echo ""
	@echo "────────────────────────────────────────────────────────"
	@echo "SESIÓN RÁPIDA (grafos ya en caché, solo refrescar datos)"
	@echo "  $$ make check && make export-all && make export-lineas && make workbooks && make verify"
	@echo ""
	@echo "REGENERACIÓN COMPLETA (desde cero, después de cambios de red)"
	@echo "  $$ make check && make warmup-all && make export-all && make export-lineas && make workbooks && make verify"
	@echo ""
