"""
prepare_garibelt_layers.py — Genera GeoJSONs enriquecidos con clasificación
Garibelt para consumo en QGIS (proyecto garibelt_red_actual.qgz).

Capas generadas en data/processed/garibelt/:
  fc_puntos_garibelt[_<escenario>].geojson   — nodos con fc_banda + fc_normalizado
  cobertura_garibelt[_<escenario>].geojson   — demarcaciones con categoria_cobertura
  b_puntos_top[_<escenario>].geojson         — top-50 nodos B(v) con clasificación visual

Uso:
    python utils/prepare_garibelt_layers.py                   # baseline
    python utils/prepare_garibelt_layers.py --scenario mb     # escenario MB
    python utils/prepare_garibelt_layers.py --scenario metro  # escenario METRO
    python utils/prepare_garibelt_layers.py --all             # los 3 escenarios
"""

import argparse
import json
from pathlib import Path
from collections import Counter

REPO_ROOT = Path(__file__).parent.parent
GEO_DIR   = REPO_ROOT / "tableau" / "exports" / "geo"
CONN_DIR  = REPO_ROOT / "tableau" / "connectors" / "VFTModel" / "exports"
OUT_DIR   = REPO_ROOT / "data" / "processed" / "garibelt"

SCENARIOS = {
    "baseline": {
        "geo_dir":  GEO_DIR,
        "conn_dir": CONN_DIR,
        "out_dir":  OUT_DIR,
        "suffix":   "",
    },
    "mb": {
        "geo_dir":  GEO_DIR / "scenario_mb",
        "conn_dir": CONN_DIR / "scenario_mb",
        "out_dir":  OUT_DIR / "scenario-mb",
        "suffix":   "_mb",
    },
    "metro": {
        "geo_dir":  GEO_DIR / "scenario_metro",
        "conn_dir": CONN_DIR / "scenario_metro",
        "out_dir":  OUT_DIR / "scenario-metro",
        "suffix":   "_metro",
    },
}

GARIBELT_COLORS = {
    "critico":   "#C0392B",
    "debil":     "#E67E22",
    "aceptable": "#2980B9",
    "idoneo":    "#27AE60",
}


def _classify_band(v: float) -> str:
    if v < 0.25:
        return "critico"
    elif v < 0.50:
        return "debil"
    elif v < 0.75:
        return "aceptable"
    return "idoneo"


def _write_geojson(path: Path, features: list, crs_epsg: int = 4326) -> None:
    geojson = {
        "type": "FeatureCollection",
        "crs": {"type": "name", "properties": {"name": f"urn:ogc:def:crs:EPSG::{crs_epsg}"}},
        "features": features,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(geojson, f, ensure_ascii=False, separators=(",", ":"))
    print(f"  ✓ {path.relative_to(REPO_ROOT)}  ({len(features)} features)")


def generate_fc_puntos(geo_dir: Path, suffix: str, out_dir: Path) -> None:
    src = geo_dir / "fc_puntos.geojson"
    if not src.exists():
        print(f"  ✗ {src.relative_to(REPO_ROOT)} no existe — omitido")
        return

    data = json.load(open(src, encoding="utf-8"))
    features = data["features"]

    fc_values = [f["properties"].get("fc_total") or 0 for f in features]
    fc_min, fc_max = min(fc_values), max(fc_values)

    out_features = []
    for f in features:
        p = dict(f["properties"])
        fc = p.get("fc_total") or 0
        fc_norm = (fc - fc_min) / (fc_max - fc_min) if fc_max > fc_min else 0.5
        fc_norm = round(max(0.0, min(1.0, fc_norm)), 4)
        banda = _classify_band(fc_norm)
        p["fc_normalizado"] = fc_norm
        p["fc_banda"]       = banda
        p["banda_color"]    = GARIBELT_COLORS[banda]
        out_features.append({"type": "Feature", "geometry": f["geometry"], "properties": p})

    _write_geojson(out_dir / f"fc_puntos_garibelt{suffix}.geojson", out_features)
    bandas = Counter(f["properties"]["fc_banda"] for f in out_features)
    total = len(out_features)
    for b in ["critico", "debil", "aceptable", "idoneo"]:
        n = bandas.get(b, 0)
        print(f"    {b}: {n} ({100*n/total:.1f}%)")


def generate_cobertura(conn_dir: Path, suffix: str, out_dir: Path) -> None:
    src = conn_dir / "cobertura_por_alcaldia.geojson"
    if not src.exists():
        print(f"  ✗ {src.relative_to(REPO_ROOT)} no existe — omitido")
        return

    data = json.load(open(src, encoding="utf-8"))
    CAT_COLORS = {
        "alta":          "#27AE60",
        "media":         "#2980B9",
        "baja":          "#E67E22",
        "sin_cobertura": "#C0392B",
    }
    out_features = []
    for f in data["features"]:
        p = dict(f["properties"])
        cat = p.get("categoria_cobertura") or "sin_cobertura"
        p["banda_color"] = CAT_COLORS.get(cat, "#888888")
        out_features.append({"type": "Feature", "geometry": f["geometry"], "properties": p})

    _write_geojson(out_dir / f"cobertura_garibelt{suffix}.geojson", out_features)


def generate_b_puntos_top(geo_dir: Path, suffix: str, out_dir: Path) -> None:
    src = geo_dir / "b_puntos.geojson"
    if not src.exists():
        print(f"  ✗ {src.relative_to(REPO_ROOT)} no existe — omitido")
        return

    data = json.load(open(src, encoding="utf-8"))
    features = data["features"]

    seen: dict = {}
    for f in features:
        p = f["properties"]
        key = (p.get("nombre"), p.get("sistema"))
        b = p.get("betweenness_centrality") or 0
        if key not in seen or b > seen[key]["properties"]["betweenness_centrality"]:
            seen[key] = f

    top = sorted(seen.values(),
                 key=lambda f: f["properties"]["betweenness_centrality"],
                 reverse=True)[:50]

    b_max = top[0]["properties"]["betweenness_centrality"]
    out_features = []
    for rank, f in enumerate(top, start=1):
        p = dict(f["properties"])
        b = p["betweenness_centrality"]
        b_norm = round(b / b_max, 4)
        if rank <= 5:
            categoria, color = "top5",    "#C0392B"
        elif rank <= 15:
            categoria, color = "top6_15", "#E67E22"
        else:
            categoria, color = "top16_50","#2980B9"
        p["rank"]          = rank
        p["b_normalizado"] = b_norm
        p["categoria_b"]   = categoria
        p["banda_color"]   = color
        out_features.append({"type": "Feature", "geometry": f["geometry"], "properties": p})

    _write_geojson(out_dir / f"b_puntos_top{suffix}.geojson", out_features)
    print(f"    top-5:    {', '.join(f['properties']['nombre'] for f in out_features[:5])}")


def run_scenario(name: str) -> None:
    cfg = SCENARIOS[name]
    cfg["out_dir"].mkdir(parents=True, exist_ok=True)
    label = name.upper() if name != "baseline" else "Baseline"
    print(f"\n── Generando capas Garibelt — {label} ──────────────────────────")

    print(f"\n[1/3] fc_puntos_garibelt{cfg['suffix']}.geojson")
    generate_fc_puntos(cfg["geo_dir"], cfg["suffix"], cfg["out_dir"])

    print(f"\n[2/3] cobertura_garibelt{cfg['suffix']}.geojson")
    generate_cobertura(cfg["conn_dir"], cfg["suffix"], cfg["out_dir"])

    print(f"\n[3/3] b_puntos_top{cfg['suffix']}.geojson")
    generate_b_puntos_top(cfg["geo_dir"], cfg["suffix"], cfg["out_dir"])

    print(f"\nSalida: {cfg['out_dir'].relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Genera GeoJSONs Garibelt para QGIS desde exports VFTModel."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--scenario", choices=["baseline", "mb", "metro"],
        default="baseline",
        help="Escenario a procesar (default: baseline)"
    )
    group.add_argument(
        "--all", action="store_true",
        help="Procesar los 3 escenarios en secuencia"
    )
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if args.all:
        for s in ["baseline", "mb", "metro"]:
            run_scenario(s)
        print("\nListo — 3 escenarios generados.\n")
    else:
        run_scenario(args.scenario)
        print(f"Listo para abrir en garibelt_red_actual.qgz\n")
