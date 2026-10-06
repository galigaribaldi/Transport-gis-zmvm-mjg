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

PYTHON      ?= .venv/bin/python
SHOW_C      ?=
EXPORTS      = utils/generate_exports.py
COPY_WB      = utils/copy_workbook_scenario.py
GARIBELT_CSV = utils/export_garibelt_csv.py
GEO_DIR      = tableau/exports/geo
WB_DIR       = tableau/workbooks
GARIBELT_DIR = tableau/exports/data/garibelt

.PHONY: all help guide \
        check \
        warmup warmup-all warmup-scenarios \
        warmup-baseline warmup-mb warmup-metro \
        _warmup-port \
        export-all export-baseline export-mb export-metro \
        export-lineas export-lineas-baseline export-lineas-mb export-lineas-metro \
        export-garibelt-csv-all export-layers _export-port-layers export-garibelt-layers export-comparativo \
        export-garibelt-csv-baseline export-garibelt-csv-mb export-garibelt-csv-metro \
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
#   B (betweenness):  10-20 min  ← el más lento con ~11 k nodos
#   DF (detour):      30-60 s

# Helper interno — requiere PORT=XXXX, no llamar directamente
# network-profile calcula y cachea T + B(v) internamente (cambio VFTModel cobertura Oct-2026)
_warmup-port:
	@echo "  [1/2] build-auto..."
	@curl -s --max-time 60 \
		"http://localhost:$(PORT)/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', d.get('nodos','?'), 'nodos,', d.get('aristas','?'), 'aristas')" 2>/dev/null \
		|| { echo "        ERROR: VFTModel :$(PORT) no responde. Verificar con make check."; exit 1; }
	@echo "  [2/2] network-profile (Garibelt) — calcula T + B(v) internamente, ~20 min primera vez..."
	@curl -s --max-time 3600 \
		"http://localhost:$(PORT)/api/v1/network/topological/network-profile?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		| SHOW_C=$(SHOW_C) python3 -c "import sys,json,os; r=json.load(sys.stdin); d=r.get('data',{}); dims=d.get('dimensions',[]); cd=d.get('cobertura_dominios',{}) if os.getenv('SHOW_C') else {}; extra=' | C141='+str(cd.get('entidades',{}).get('valor_bruto','?'))+'% | C76='+str(cd.get('zmvm_76',{}).get('valor_bruto','?'))+'%' if cd else ''; print('        OK —', len(dims), 'dimensiones Garibelt compiladas'+extra)" 2>/dev/null \
		|| echo "        WARN: timeout en network-profile."

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
	@echo "  PASO 2 — Calentando los 3 escenarios en paralelo (~20 min)"
	@echo "══════════════════════════════════════════════════════════"
	@mkdir -p /tmp/vft_warmup && rm -f /tmp/vft_warmup/estado.log
	@for p in 8000 8001 8002; do \
	  ( \
	    curl -s --max-time 3600 "localhost:$$p/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
	      > /tmp/vft_warmup/build_$$p.json; \
	    curl -s --max-time 3600 "localhost:$$p/api/v1/network/topological/network-profile?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
	      > /tmp/vft_warmup/profile_$$p.json; \
	    echo "$$p terminado $$(date +%T)" >> /tmp/vft_warmup/estado.log; \
	  ) & \
	done; \
	wait
	@echo "  Los 3 escenarios están en caché."
	@echo "  Resultados en /tmp/vft_warmup/"
	@echo ""

verify-step-2:
	@echo ""
	@echo "══════════════════════════════════════════════════════════"
	@echo "  PASO 2 — Verificando caché de grafos (T + Garibelt)"
	@echo "══════════════════════════════════════════════════════════"
	@echo "  T por escenario:"
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
	@echo "  ProfileCache Garibelt (network-profile):"
	@curl -s --max-time 5 \
		"http://localhost:8000/api/v1/network/topological/network-profile" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); n=len(d.get('dimensions',[])); print('    Baseline  :8000  Garibelt =', n, 'dims  ✓' if n==5 else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    Baseline  :8000  Garibelt ✗  →  make warmup-baseline"
	@curl -s --max-time 5 \
		"http://localhost:8001/api/v1/network/topological/network-profile" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); n=len(d.get('dimensions',[])); print('    MB        :8001  Garibelt =', n, 'dims  ✓' if n==5 else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    MB        :8001  Garibelt ✗  →  make warmup-mb"
	@curl -s --max-time 5 \
		"http://localhost:8002/api/v1/network/topological/network-profile" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); n=len(d.get('dimensions',[])); print('    METRO     :8002  Garibelt =', n, 'dims  ✓' if n==5 else '  ✗ sin caché')" 2>/dev/null \
		|| echo "    METRO     :8002  Garibelt ✗  →  make warmup-metro"
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

# ── CSVs Garibelt para Tableau (Paso 3 — requiere warmup activo para --include-api) ──
# Lee GeoJSONs ya generados en disco + llama /network-profile para el perfil escalar.
# Prerequisito: make warmup-all (ProfileCache debe estar activo).

export-garibelt-csv-baseline:
	@echo "── CSVs Garibelt Baseline ────────────────────────────────"
	$(PYTHON) $(GARIBELT_CSV) --scenario baseline --include-api

export-garibelt-csv-mb:
	@echo "── CSVs Garibelt MB ──────────────────────────────────────"
	$(PYTHON) $(GARIBELT_CSV) --scenario scenario_mb --include-api

export-garibelt-csv-metro:
	@echo "── CSVs Garibelt METRO ───────────────────────────────────"
	$(PYTHON) $(GARIBELT_CSV) --scenario scenario_metro --include-api

export-garibelt-csv-all:
	@echo ""
	@echo "── Exportando CSVs Garibelt (3 escenarios) ───────────────"
	@$(MAKE) export-garibelt-csv-baseline
	@$(MAKE) export-garibelt-csv-mb
	@$(MAKE) export-garibelt-csv-metro
	@echo ""

# ── Capas por demarcación (Spatial File Tableau) + perfil_nodos (QGIS) ──────
# Helper interno — requiere PORT, CONN (dir conector) y PROC (dir data/processed/garibelt)
VFT_Q = mode=REALISTIC_INTEGRATION&tolerance_m=85

_export-port-layers:
	@mkdir -p $(CONN) $(PROC)
	@for l in cobertura_por_alcaldia cobertura_800m; do \
		curl -sf --max-time 600 "http://localhost:$(PORT)/api/v1/network/geolayers/coverage?layer=$$l&radio_m=800&$(VFT_Q)" \
			-o $(CONN)/$$l.geojson && echo "  ✓ $(CONN)/$$l.geojson" || echo "  ✗ $$l :$(PORT)"; \
	done
	@curl -sf --max-time 600 "http://localhost:$(PORT)/api/v1/network/geolayers/detour?layer=df_por_alcaldia&sample_size=100&seed=42&$(VFT_Q)" \
		-o $(CONN)/df_por_alcaldia.geojson && echo "  ✓ $(CONN)/df_por_alcaldia.geojson" || echo "  ✗ df_por_alcaldia :$(PORT)"
	@curl -sf --max-time 600 "http://localhost:$(PORT)/api/v1/network/geolayers/profile?layer=perfil_nodos&$(VFT_Q)" \
		-o $(PROC)/perfil_nodos_$(TAG).geojson && echo "  ✓ $(PROC)/perfil_nodos_$(TAG).geojson" || echo "  ✗ perfil_nodos :$(PORT)"

CONN_DIR = tableau/connectors/VFTModel/exports
PROC_DIR = data/processed/garibelt

export-layers:
	@echo "── Capas por demarcación + perfil_nodos (3 escenarios) ───"
	@$(MAKE) _export-port-layers PORT=8000 CONN=$(CONN_DIR)                PROC=$(PROC_DIR)                TAG=baseline
	@$(MAKE) _export-port-layers PORT=8001 CONN=$(CONN_DIR)/scenario_mb    PROC=$(PROC_DIR)/scenario-mb    TAG=mb
	@$(MAKE) _export-port-layers PORT=8002 CONN=$(CONN_DIR)/scenario_metro PROC=$(PROC_DIR)/scenario-metro TAG=metro

# Capas Garibelt para QGIS (fc_puntos_garibelt, cobertura_garibelt, b_puntos_top) — lee de disco
export-garibelt-layers:
	@echo "── Capas Garibelt QGIS (3 escenarios) ────────────────────"
	$(PYTHON) utils/prepare_garibelt_layers.py --all

# Datos comparativos Base · MB · Metro (QGIS cambio_banda + CSVs Tableau) — lee de disco
export-comparativo:
	@echo "── Datos comparativos Garibelt ───────────────────────────"
	$(PYTHON) utils/compare_garibelt_scenarios.py

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
	@$(MAKE) export-layers
	@echo ""
	@$(MAKE) export-garibelt-layers
	@echo ""
	@echo "  Exportando CSVs Garibelt para Tableau..."
	@$(MAKE) export-garibelt-csv-all
	@echo ""
	@$(MAKE) export-comparativo

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
	@echo "  GeoJSONs Apimetro (lineas — baseline:678, escenarios:686):"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/lineas.geojson')); n=len(d['features']); ok='✓' if n==678 else '?'; print(f'    baseline/lineas.geojson         {n} features {ok}')" 2>/dev/null || echo "    baseline/lineas.geojson          ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_mb/lineas.geojson')); n=len(d['features']); ok='✓' if n==686 else '✗ esperado 686'; print(f'    scenario_mb/lineas.geojson      {n} features {ok}')" 2>/dev/null || echo "    scenario_mb/lineas.geojson       ✗ no existe"
	@python3 -c "import json; d=json.load(open('$(GEO_DIR)/scenario_metro/lineas.geojson')); n=len(d['features']); ok='✓' if n==686 else '✗ esperado 686'; print(f'    scenario_metro/lineas.geojson   {n} features {ok}')" 2>/dev/null || echo "    scenario_metro/lineas.geojson    ✗ no existe"
	@echo "  CSVs Garibelt ($(GARIBELT_DIR)/):"
	@for sd in baseline:escenario-base scenario_mb:escenario-mb scenario_metro:escenario-metro; do \
		s=$${sd%%:*}; d=$${sd##*:}; \
		for csv in b_ranking fc_distribucion df_distribucion cobertura_alcaldias garibelt_perfil; do \
			f="$(GARIBELT_DIR)/$$d/$${csv}_$${s}.csv"; \
			if [ -f "$$f" ]; then \
				rows=$$(tail -n +2 "$$f" | wc -l | tr -d ' '); \
				echo "    $${csv}_$${s}.csv   $$rows filas ✓"; \
			else \
				echo "    $${csv}_$${s}.csv   ✗ no existe"; \
			fi \
		done \
	done
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
	@echo "    MB vs Baseline:    −4.92 min  (108.99 vs 113.91)"
	@echo "    METRO vs Baseline: −11.99 min (101.92 vs 113.91)"
	@echo "  Lineas Apimetro (baseline:678, escenarios con anillo:686):"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/lineas.geojson'))['features']); print('    baseline:      ', n, 'lineas', '✓' if n==678 else '✗')" 2>/dev/null || echo "    baseline lineas.geojson ✗ no existe"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/scenario_mb/lineas.geojson'))['features']); print('    scenario_mb:   ', n, 'lineas', '✓' if n==686 else '✗ (esperado 686)')" 2>/dev/null || echo "    scenario_mb lineas.geojson ✗ no existe"
	@python3 -c "import json; n=len(json.load(open('$(GEO_DIR)/scenario_metro/lineas.geojson'))['features']); print('    scenario_metro:', n, 'lineas', '✓' if n==686 else '✗ (esperado 686)')" 2>/dev/null || echo "    scenario_metro lineas.geojson ✗ no existe"
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
	@echo "PASO 2 — Calentar grafos  (~20 min paralelo primera vez, solo si no hay caché)"
	@echo "  make warmup             Calentar solo baseline (:8000)"
	@echo "  make warmup-all         Los 3 escenarios en paralelo (~20 min)"
	@echo "  make warmup-baseline    Solo baseline (:8000)"
	@echo "  make warmup-mb          Solo escenario MB (:8001)"
	@echo "  make warmup-metro       Solo escenario METRO (:8002)"
	@echo "  make warmup-scenarios   MB + METRO (sin baseline)"
	@echo "  make verify-step-2      Ver T actual de cada escenario"
	@echo "  Flag: SHOW_C=1          Mostrar C₁₄₁ y C₇₆ en el log del warmup"
	@echo ""
	@echo "PASO 3 — Generar fuentes de datos"
	@echo "  make export-all         GeoJSONs + GPKGs + lineas (3 escenarios)"
	@echo "  make export-baseline    Solo VFTModel baseline (:8000)"
	@echo "  make export-mb          Solo VFTModel MB (:8001)"
	@echo "  make export-metro       Solo VFTModel METRO (:8002)"
	@echo "  make export-lineas      lineas.geojson + poligonos.geojson (3 Apimetro)"
	@echo "  make export-layers      cobertura/df por demarcación (Tableau) + perfil_nodos (QGIS)"
	@echo "  make export-garibelt-layers  fc/cobertura/b_puntos Garibelt para QGIS"
	@echo "  make export-comparativo cambio_banda (QGIS) + CSVs comparativos (Tableau)"
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
	@echo "PASO 2 — CALENTAR GRAFOS  (primera sesión del día, ~20 min paralelo)"
	@echo "  $$ make warmup-all"
	@echo "  Precarga T + B(v) en memoria para los 3 escenarios en paralelo."
	@echo "  network-profile calcula T y B(v) internamente (~20 min primera vez)."
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
