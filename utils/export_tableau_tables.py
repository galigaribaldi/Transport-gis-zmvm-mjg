"""
export_tableau_tables.py — Tablas planas para Tableau con las mismas columnas que el WDC de VFTModel.

Reemplaza las 4 fuentes WDC de dashboard_viz04_red_vftmodel.twb por CSV en disco (conexión en vivo),
para que actualizar sea: `make export-all` y abrir el workbook, sin servidor WDC ni refresco de extractos.

Tablas (mismos `id` de columna que tableau/connectors/VFTModel/vft_wdc.html):
    wdc_fc_puntos.csv · wdc_fc_hubs.csv · wdc_df_puntos.csv · wdc_t_escalar.csv
Destino: tableau/connectors/VFTModel/exports[/<escenario>]/  (copy_workbook_scenario.py ya redirige esa ruta)

Uso:
    python utils/export_tableau_tables.py            # 3 escenarios
    python utils/export_tableau_tables.py --check    # solo imprime los valores para comparar en Tableau
"""

import argparse
import csv
import json
import statistics
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GEO = REPO / "tableau" / "exports" / "geo"
CONN = REPO / "tableau" / "connectors" / "VFTModel" / "exports"

SCENARIOS = {"baseline": ("", 8000), "scenario_mb": ("scenario_mb", 8001), "scenario_metro": ("scenario_metro", 8002)}

COLS = {
    "fc_puntos": ["id", "nombre", "fc_total", "cx_entrada", "cx_salida", "sistemas", "sistemas_count",
                  "tipo_nodo", "lat", "lon"],
    "fc_hubs": ["id", "nombre", "estaciones_agrupadas", "fc_total", "sistemas", "sistemas_count", "lat", "lon"],
    "df_puntos": ["id", "nombre", "factor_desviacion", "origen", "destino", "dist_red_km", "dist_recta_km",
                  "sistemas", "categoria_df", "lat", "lon"],
    "t_escalar": ["T_minutos", "nodos_scc", "aristas_scc", "referencia_cdmx"],
}
SOURCES = {
    "fc_puntos": lambda sub: GEO / sub / "fc_puntos.geojson",
    "fc_hubs": lambda sub: CONN / sub / "fc_hubs.geojson",
    "df_puntos": lambda sub: CONN / sub / "df_puntos.geojson",
}


def _rows_from_geojson(path: Path, cols: list) -> list:
    rows = []
    for f in json.load(open(path, encoding="utf-8"))["features"]:
        p = dict(f["properties"])
        lon, lat = f["geometry"]["coordinates"][:2]
        if isinstance(p.get("sistemas"), list):
            p["sistemas"] = json.dumps(p["sistemas"])  # ASCII escapado, igual que el WDC: los alias del .twb usan esa clave
        rows.append({**{c: p.get(c) for c in cols}, "lat": lat, "lon": lon})
    return rows


def _t_escalar(port: int) -> list:
    url = f"http://localhost:{port}/api/v1/network/topological/average-travel-time"
    with urllib.request.urlopen(url, timeout=1200) as r:
        d = json.load(r).get("data", {})
    gi, ref = d.get("graph_info", {}), d.get("reference", {})
    return [{"T_minutos": d.get("T_average_travel_time_minutes"), "nodos_scc": gi.get("nodes"),
             "aristas_scc": gi.get("edges"), "referencia_cdmx": ref.get("expected_cdmx_approx")}]


def _write(path: Path, cols: list, rows: list) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        w.writerows(rows)


def export(name: str) -> None:
    sub, port = SCENARIOS[name]
    out_dir = CONN / sub
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"── {name} ──")
    for tabla, cols in COLS.items():
        out = out_dir / f"wdc_{tabla}.csv"
        try:
            rows = _t_escalar(port) if tabla == "t_escalar" else _rows_from_geojson(SOURCES[tabla](sub), cols)
        except FileNotFoundError as e:
            print(f"  ✗ {tabla}: falta {Path(e.filename).relative_to(REPO)} → make export-layers")
            continue
        except OSError:
            print(f"  ✗ {tabla}: VFTModel :{port} no responde — se conserva {out.name} anterior" if out.exists()
                  else f"  ✗ {tabla}: VFTModel :{port} no responde")
            continue
        _write(out, cols, rows)
        print(f"  ✓ {out.relative_to(REPO)}  ({len(rows)} filas)")


def check(name: str) -> None:
    sub, _ = SCENARIOS[name]
    d = CONN / sub

    def read(t):
        p = d / f"wdc_{t}.csv"
        return list(csv.DictReader(open(p, encoding="utf-8"))) if p.exists() else []

    t, fc, hubs, df = read("t_escalar"), read("fc_puntos"), read("fc_hubs"), read("df_puntos")
    print(f"── {name} ──")
    if t:
        print(f"  T = {float(t[0]['T_minutos']):.2f} min  (nodos SCC {t[0]['nodos_scc']}, ref. {t[0]['referencia_cdmx']})")
    if fc:
        top = max(fc, key=lambda r: float(r["fc_total"]))
        print(f"  FC: {len(fc)} nodos · máx {top['nombre']} ({top['fc_total']})")
    if hubs:
        h = max(hubs, key=lambda r: float(r["fc_total"]))
        print(f"  Macro-hubs: {len(hubs)} · 1.º {h['nombre'].split(' - ')[0]} (FC {h['fc_total']})")
    if df:
        v = [float(r["factor_desviacion"]) for r in df]
        print(f"  DF: {len(v)} rutas · min {min(v)} · max {max(v)} · media {statistics.mean(v):.3f}")
    if not any([t, fc, hubs, df]):
        print("  ✗ sin tablas → make export-tableau-tablas")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Tablas planas WDC → CSV para Tableau.")
    ap.add_argument("--scenario", choices=["all", *SCENARIOS], default="all")
    ap.add_argument("--check", action="store_true", help="Solo imprime valores clave para comparar en Tableau")
    a = ap.parse_args()
    for s in (SCENARIOS if a.scenario == "all" else [a.scenario]):
        (check if a.check else export)(s)
