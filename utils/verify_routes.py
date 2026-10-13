"""verify_routes.py — Comprueba df_rutas_lineas por escenario: DF ≥ 1 y misma muestra que df_puntos."""

import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GEO = REPO / "tableau" / "exports" / "geo"
CONN = REPO / "tableau" / "connectors" / "VFTModel" / "exports"

for name, sub in [("baseline", ""), ("scenario_mb", "scenario_mb"), ("scenario_metro", "scenario_metro")]:
    lineas = GEO / sub / "df_rutas_lineas.geojson"
    if not lineas.exists():
        print(f"    {name:15s} ✗ falta {lineas.relative_to(REPO)}")
        continue
    L = [f["properties"] for f in json.load(open(lineas, encoding="utf-8"))["features"]]
    df_min = min(p["factor_desviacion"] for p in L)
    puntos = CONN / sub / "df_puntos.geojson"
    if puntos.exists():
        P = {(f["properties"]["origen"], f["properties"]["destino"])
             for f in json.load(open(puntos, encoding="utf-8"))["features"]}
        n = sum((p["origen"], p["destino"]) in P for p in L)
        muestra = f"{n}/{len(L)} pares = df_puntos {'✓' if n == len(L) else '✗'}"
    else:
        muestra = "sin df_puntos para comparar (make export-layers)"
    print(f"    {name:15s} {len(L)} rutas · DF min {df_min} {'✓' if df_min >= 1 else '✗ DF<1'} · {muestra}")
