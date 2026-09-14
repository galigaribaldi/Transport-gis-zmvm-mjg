# tableau/Makefile
# Comandos de sesión de trabajo para conectores Tableau del proyecto
# Transportes Anillares y su importancia en la CDMX y ZMVM
#
# Uso típico:
#   make check       → verificar que los servicios estén activos
#   make warmup      → calentar el grafo de VFTModel (primera vez del día)
#   make warmup-all  → calentar TODOS los endpoints antes de crear extractos
#   make serve       → levantar servidor HTTP para los WDC (dejar corriendo)

.PHONY: serve check warmup warmup-all

# ── Servidor HTTP para WDC ────────────────────────────────────────────────────
# Sirve todos los conectores desde tableau/ en localhost:5050
# Mantener corriendo mientras se trabaja en Tableau Desktop
serve:
	@echo "──────────────────────────────────────────────"
	@echo "  WDC Server → http://localhost:5050"
	@echo ""
	@echo "  Conectores disponibles:"
	@echo "  Apimetro  → http://localhost:5050/connectors/apimetro/apimetro_wdc.html"
	@echo "  VFTModel  → http://localhost:5050/connectors/VFTModel/vft_wdc.html"
	@echo ""
	@echo "  Detener con Ctrl+C"
	@echo "──────────────────────────────────────────────"
	python3 -m http.server 5050

# ── Verificar servicios backend ───────────────────────────────────────────────
# Solo comprueba reachability (cualquier respuesta HTTP = activo).
# No usa -f para que 4xx del servidor no se reporte como caído.
check:
	@echo "Verificando servicios backend..."
	@curl -sf --max-time 5 http://localhost:8080/health > /dev/null \
		&& echo "  Apimetro  (8080): ✓ activo" \
		|| echo "  Apimetro  (8080): ✗ no disponible  →  make dev   (repo apimetro)"
	@curl -s --max-time 10 \
		"http://localhost:8000/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		> /dev/null 2>&1 \
		&& echo "  VFTModel  (8000): ✓ activo" \
		|| echo "  VFTModel  (8000): ✗ no disponible  →  make run   (repo VFTModel)"

# ── Calentar grafo VFTModel (solo build-auto) ────────────────────────────────
# Rápido (~18 ms si ya hay caché). Suficiente para fc_puntos, fc_hubs, estaciones.
warmup:
	@echo "Calentando grafo VFTModel (REALISTIC_INTEGRATION, tolerance_m=85)..."
	@curl -s --max-time 60 \
		"http://localhost:8000/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('  Grafo listo —', d.get('nodos','?'), 'nodos,', d.get('aristas','?'), 'aristas')" 2>/dev/null \
		|| echo "  Error: VFTModel no responde. Ejecutar make run en el repo VFTModel primero."

# ── Calentar TODOS los endpoints lentos ──────────────────────────────────────
# Ejecutar SIEMPRE antes de crear un extracto WDC en Tableau.
# Tiempos en primera llamada (sin caché):
#   build-auto:              < 1 min
#   T (average-travel-time): 2-5 min
#   B (betweenness):         5-8 min  ← el más lento con 11 k nodos
#   DF (detour factor):      30-60 s
# Con caché todos responden en <100 ms → Tableau no hace timeout al crear el extracto.
warmup-all:
	@echo "Calentando todos los endpoints de VFTModel..."
	@echo "  [1/4] build-auto..."
	@curl -s --max-time 60 \
		"http://localhost:8000/api/v1/network/build-auto?mode=REALISTIC_INTEGRATION&tolerance_m=85" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', d.get('nodos','?'), 'nodos')" 2>/dev/null \
		|| { echo "        ERROR: VFTModel no responde."; exit 1; }
	@echo "  [2/4] average-travel-time (T) — puede tardar 2-5 min..."
	@curl -s --max-time 360 \
		"http://localhost:8000/api/v1/network/topological/average-travel-time" \
		| python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print('        OK — T =', d.get('T_average_travel_time_minutes','?'), 'min')" 2>/dev/null \
		|| echo "        ERROR: timeout o fallo en T."
	@echo "  [3/4] betweenness-centrality (B) — puede tardar 5-8 min primera vez..."
	@curl -s --max-time 600 \
		"http://localhost:8000/api/v1/network/geolayers/betweenness?layer=b_puntos&limit=2000" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', d.get('metadata',{}).get('n_features','?'), 'nodos rankeados')" 2>/dev/null \
		|| echo "        ERROR: timeout o fallo en B."
	@echo "  [4/4] detour-factor (DF) — puede tardar 30-60 s..."
	@curl -s --max-time 120 \
		"http://localhost:8000/api/v1/network/geolayers/detour?layer=df_puntos&sample_size=100&seed=42" \
		| python3 -c "import sys,json; d=json.load(sys.stdin); print('        OK —', len(d.get('features',[])), 'rutas O-D')" 2>/dev/null \
		|| echo "        ERROR: timeout o fallo en DF."
	@echo "Listo. Todos los endpoints en caché — ahora abre Tableau y crea el extracto."
