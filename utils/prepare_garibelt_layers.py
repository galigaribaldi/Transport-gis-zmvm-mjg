"""
prepare_garibelt_layers.py — Genera GeoJSONs enriquecidos con clasificación
Garibelt para consumo en QGIS (proyecto garibelt_red_actual.qgz).

Capas generadas en data/processed/garibelt/:
  fc_puntos_garibelt.geojson   — 10,537 nodos con fc_banda + fc_normalizado
  cobertura_garibelt.geojson   — 141 demarcaciones con categoria_cobertura (copia enriquecida)
  b_puntos_top.geojson         — top-50 nodos B(v) con clasificación visual

Uso:
    python utils/prepare_garibelt_layers.py
"""

import json
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
GEO_DIR   = REPO_ROOT / "tableau" / "exports" / "geo"
CONN_DIR  = REPO_ROOT / "tableau" / "connectors" / "VFTModel" / "exports"
OUT_DIR   = REPO_ROOT / "data" / "processed" / "garibelt"

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


def generate_fc_puntos() -> None:
    """fc_puntos_garibelt.geojson — agrega fc_normalizado y fc_banda."""
    src = GEO_DIR / "fc_puntos.geojson"
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
        out_features.append({
            "type": "Feature",
            "geometry": f["geometry"],
            "properties": p,
        })

    _write_geojson(OUT_DIR / "fc_puntos_garibelt.geojson", out_features)
    # Resumen de bandas
    from collections import Counter
    bandas = Counter(f["properties"]["fc_banda"] for f in out_features)
    total = len(out_features)
    for b in ["critico", "debil", "aceptable", "idoneo"]:
        n = bandas.get(b, 0)
        print(f"    {b}: {n} ({100*n/total:.1f}%)")


def generate_cobertura() -> None:
    """cobertura_garibelt.geojson — copia enriquecida con banda_color."""
    src = CONN_DIR / "cobertura_por_alcaldia.geojson"
    data = json.load(open(src, encoding="utf-8"))
    out_features = []
    CAT_COLORS = {
        "alta":   "#27AE60",
        "media":  "#2980B9",
        "baja":   "#E67E22",
        "sin_cobertura": "#C0392B",
    }
    for f in data["features"]:
        p = dict(f["properties"])
        cat = p.get("categoria_cobertura") or "sin_cobertura"
        p["banda_color"] = CAT_COLORS.get(cat, "#888888")
        out_features.append({
            "type": "Feature",
            "geometry": f["geometry"],
            "properties": p,
        })
    _write_geojson(OUT_DIR / "cobertura_garibelt.geojson", out_features)


def generate_b_puntos_top() -> None:
    """b_puntos_top.geojson — top-50 nodos B(v) únicos con clasificación visual."""
    src = GEO_DIR / "b_puntos.geojson"
    data = json.load(open(src, encoding="utf-8"))
    features = data["features"]

    # Deduplicar por nombre+sistema, quedarse con el de mayor B
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

    # Clasificación visual por cuartil del top-50
    b_max = top[0]["properties"]["betweenness_centrality"]
    out_features = []
    for rank, f in enumerate(top, start=1):
        p = dict(f["properties"])
        b = p["betweenness_centrality"]
        b_norm = round(b / b_max, 4)  # normalizado respecto al máximo del top-50
        if rank <= 5:
            categoria = "top5"
            color = "#C0392B"
        elif rank <= 15:
            categoria = "top6_15"
            color = "#E67E22"
        else:
            categoria = "top16_50"
            color = "#2980B9"
        p["rank"]          = rank
        p["b_normalizado"] = b_norm
        p["categoria_b"]   = categoria
        p["banda_color"]   = color
        out_features.append({
            "type": "Feature",
            "geometry": f["geometry"],
            "properties": p,
        })

    _write_geojson(OUT_DIR / "b_puntos_top.geojson", out_features)
    print(f"    top-5:    {', '.join(f['properties']['nombre'] for f in out_features[:5])}")


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("\n── Generando capas Garibelt para QGIS ──────────────────────────")

    print("\n[1/3] fc_puntos_garibelt.geojson")
    generate_fc_puntos()

    print("\n[2/3] cobertura_garibelt.geojson")
    generate_cobertura()

    print("\n[3/3] b_puntos_top.geojson")
    generate_b_puntos_top()

    print(f"\nSalida: {OUT_DIR.relative_to(REPO_ROOT)}/")
    print("Listo para abrir en garibelt_red_actual.qgz\n")
