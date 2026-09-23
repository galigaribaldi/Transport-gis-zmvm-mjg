"""
export_garibelt_csv.py — Exporta propiedades de los GeoJSONs existentes a CSVs
planos para consumo en Tableau (dashboard_viz05_garibelt.twb).

Uso:
    # Solo archivos en disco (sin servidor):
    python utils/export_garibelt_csv.py --scenario baseline

    # Incluir garibelt_perfil.csv desde la API (requiere warmup activo):
    python utils/export_garibelt_csv.py --scenario baseline --include-api

Escenarios válidos: baseline, scenario_mb, scenario_metro

Salida en: tableau/exports/data/garibelt/
    b_ranking_{scenario}.csv
    fc_distribucion_{scenario}.csv
    df_distribucion_{scenario}.csv
    cobertura_alcaldias_{scenario}.csv
    garibelt_perfil_{scenario}.csv    (solo con --include-api)
"""

import sys
import json
import csv
import argparse
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
GEO_DIR   = REPO_ROOT / "tableau" / "exports" / "geo"
CONN_DIR  = REPO_ROOT / "tableau" / "connectors" / "VFTModel" / "exports"
OUT_DIR   = REPO_ROOT / "tableau" / "exports" / "data" / "garibelt"

VFT_PORTS = {
    "baseline":      8000,
    "scenario_mb":   8001,
    "scenario_metro": 8002,
}

ESCENARIO_LABELS = {
    "baseline":      "Baseline",
    "scenario_mb":   "MB (BRT)",
    "scenario_metro": "METRO",
}

GARIBELT_THRESHOLDS = [0.25, 0.50, 0.75]


def _classify_band(v: float) -> str:
    if v < 0.25:
        return "critico"
    elif v < 0.50:
        return "debil"
    elif v < 0.75:
        return "aceptable"
    return "idoneo"


def _geo_src(scenario: str) -> Path:
    """Directorio de GeoJSONs VFTModel para el escenario dado."""
    if scenario == "baseline":
        return GEO_DIR
    return GEO_DIR / scenario


def _conn_src(scenario: str) -> Path:
    """Directorio de conectores VFTModel para el escenario dado."""
    if scenario == "baseline":
        return CONN_DIR
    return CONN_DIR / scenario


def _load_features(path: Path) -> list:
    with open(path, encoding="utf-8") as f:
        return json.load(f).get("features", [])


def _write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    print(f"  ✓ {path.relative_to(REPO_ROOT)}  ({len(rows)} filas)")


# ── Exportaciones desde GeoJSON ───────────────────────────────────────────────

def export_b_ranking(scenario: str) -> None:
    """b_ranking_{scenario}.csv — top nodos por betweenness_centrality."""
    src = _geo_src(scenario) / "b_puntos.geojson"
    if not src.exists():
        print(f"  ✗ {src.name} no existe — omitido")
        return

    features = _load_features(src)
    rows = []
    for f in features:
        p = f["properties"]
        rows.append({
            "escenario":              scenario,
            "escenario_label":        ESCENARIO_LABELS[scenario],
            "id":                     p.get("id"),
            "nombre":                 p.get("nombre"),
            "sistema":                p.get("sistema"),
            "alcaldia_municipio":     p.get("alcaldia_municipio"),
            "es_cetram":              p.get("es_cetram"),
            "betweenness_centrality": p.get("betweenness_centrality"),
        })

    # Ordenar por betweenness descendente
    rows.sort(key=lambda r: r["betweenness_centrality"] or 0, reverse=True)
    fields = ["escenario", "escenario_label", "id", "nombre", "sistema",
              "alcaldia_municipio", "es_cetram", "betweenness_centrality"]
    _write_csv(OUT_DIR / f"b_ranking_{scenario}.csv", rows, fields)


def export_fc_distribucion(scenario: str) -> None:
    """fc_distribucion_{scenario}.csv — distribución de fuerza capilar por nodo."""
    src = _geo_src(scenario) / "fc_puntos.geojson"
    if not src.exists():
        print(f"  ✗ {src.name} no existe — omitido")
        return

    features = _load_features(src)
    # Normalización min-max con los datos del propio archivo (replica _build_node_enrichment)
    fc_values = [f["properties"].get("fc_total") or 0 for f in features]
    fc_min = min(fc_values)
    fc_max = max(fc_values)

    rows = []
    for f in features:
        p = f["properties"]
        fc = p.get("fc_total") or 0
        fc_norm = max(0.0, min(1.0, (fc - fc_min) / (fc_max - fc_min))) if fc_max > fc_min else 0.5
        rows.append({
            "escenario":       scenario,
            "escenario_label": ESCENARIO_LABELS[scenario],
            "id":              p.get("id"),
            "nombre":          p.get("nombre"),
            "tipo_nodo":       p.get("tipo_nodo"),
            "sistemas":        p.get("sistemas"),
            "sistemas_count":  p.get("sistemas_count"),
            "cx_entrada":      p.get("cx_entrada"),
            "cx_salida":       p.get("cx_salida"),
            "fc_total":        fc,
            "fc_normalizado":  round(fc_norm, 4),
            "fc_banda":        _classify_band(fc_norm),
        })

    fields = ["escenario", "escenario_label", "id", "nombre", "tipo_nodo",
              "sistemas", "sistemas_count", "cx_entrada", "cx_salida",
              "fc_total", "fc_normalizado", "fc_banda"]
    _write_csv(OUT_DIR / f"fc_distribucion_{scenario}.csv", rows, fields)


def export_df_distribucion(scenario: str) -> None:
    """df_distribucion_{scenario}.csv — distribución del Detour Factor."""
    src = _geo_src(scenario) / "df_puntos.geojson"
    if not src.exists():
        print(f"  ✗ {src.name} no existe — omitido")
        return

    features = _load_features(src)
    rows = []
    for f in features:
        p = f["properties"]
        rows.append({
            "escenario":         scenario,
            "escenario_label":   ESCENARIO_LABELS[scenario],
            "id":                p.get("id"),
            "origen":            p.get("origen"),
            "destino":           p.get("destino"),
            "factor_desviacion": p.get("factor_desviacion"),
            "dist_red_km":       p.get("dist_red_km"),
            "dist_recta_km":     p.get("dist_recta_km"),
            "sistemas":          p.get("sistemas"),
            "categoria_df":      p.get("categoria_df"),
        })

    rows.sort(key=lambda r: r["factor_desviacion"] or 0)
    fields = ["escenario", "escenario_label", "id", "origen", "destino",
              "factor_desviacion", "dist_red_km", "dist_recta_km",
              "sistemas", "categoria_df"]
    _write_csv(OUT_DIR / f"df_distribucion_{scenario}.csv", rows, fields)


def export_cobertura_alcaldias(scenario: str) -> None:
    """cobertura_alcaldias_{scenario}.csv — cobertura 800m por alcaldía/municipio."""
    src = _conn_src(scenario) / "cobertura_por_alcaldia.geojson"
    if not src.exists():
        print(f"  ✗ {src.name} no existe — omitido")
        return

    features = _load_features(src)
    rows = []
    for f in features:
        p = f["properties"]
        pct = p.get("cobertura_pct") or 0
        rows.append({
            "escenario":           scenario,
            "escenario_label":     ESCENARIO_LABELS[scenario],
            "id":                  p.get("id"),
            "nombre":              p.get("nombre"),
            "area_total_km2":      p.get("area_total_km2"),
            "area_cubierta_km2":   p.get("area_cubierta_km2"),
            "cobertura_pct":       pct,
            "cobertura_deficit":   p.get("cobertura_deficit"),
            "categoria_cobertura": p.get("categoria_cobertura"),
        })

    rows.sort(key=lambda r: r["cobertura_pct"] or 0, reverse=True)
    fields = ["escenario", "escenario_label", "id", "nombre",
              "area_total_km2", "area_cubierta_km2",
              "cobertura_pct", "cobertura_deficit", "categoria_cobertura"]
    _write_csv(OUT_DIR / f"cobertura_alcaldias_{scenario}.csv", rows, fields)


# ── Exportación desde API (requiere servidor y warmup activo) ─────────────────

def export_garibelt_perfil(scenario: str) -> None:
    """garibelt_perfil_{scenario}.csv — 5 dimensiones Garibelt desde /network-profile."""
    port = VFT_PORTS[scenario]
    url  = f"http://localhost:{port}/api/v1/network/topological/network-profile"

    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            data = json.loads(resp.read()).get("data", {})
    except Exception as e:
        print(f"  ✗ /network-profile :{port} no disponible ({e}) — omitido")
        return

    dims = data.get("dimensions", [])
    if not dims:
        print(f"  ✗ /network-profile :{port} devolvió 0 dimensiones — omitido")
        return

    rows = []
    for d in dims:
        rows.append({
            "escenario":          scenario,
            "escenario_label":    ESCENARIO_LABELS[scenario],
            "dimension":          d.get("dimension"),
            "indicador_fuente":   d.get("indicador_fuente"),
            "valor_bruto":        d.get("valor_bruto"),
            "valor_normalizado":  d.get("valor_normalizado"),
            "banda":              d.get("banda"),
            "metrica_descripcion": d.get("metrica_descripcion"),
        })

    fields = ["escenario", "escenario_label", "dimension", "indicador_fuente",
              "valor_bruto", "valor_normalizado", "banda", "metrica_descripcion"]
    _write_csv(OUT_DIR / f"garibelt_perfil_{scenario}.csv", rows, fields)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Exporta GeoJSONs Garibelt a CSVs planos para Tableau."
    )
    parser.add_argument(
        "--scenario", required=True,
        choices=list(VFT_PORTS.keys()),
        help="Escenario a exportar: baseline | scenario_mb | scenario_metro"
    )
    parser.add_argument(
        "--include-api", action="store_true",
        help="Incluir garibelt_perfil.csv desde /network-profile (requiere warmup activo)"
    )
    args = parser.parse_args()
    scenario = args.scenario

    print(f"\n── Exportando CSVs Garibelt: {scenario} ──────────────────────────")
    export_b_ranking(scenario)
    export_fc_distribucion(scenario)
    export_df_distribucion(scenario)
    export_cobertura_alcaldias(scenario)

    if args.include_api:
        export_garibelt_perfil(scenario)
    else:
        print(f"  (garibelt_perfil_{scenario}.csv omitido — usar --include-api cuando warmup esté listo)")

    print(f"\nSalida: {OUT_DIR.relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    main()
