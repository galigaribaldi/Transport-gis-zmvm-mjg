"""
compare_garibelt_scenarios.py — Datos comparativos Garibelt Baseline · MB · Metro.

Lee las capas y CSVs ya generados por `make export-all` (no llama a la API).

Salidas:
  QGIS    data/processed/garibelt/comparativo/cambio_banda.geojson
  Tableau tableau/exports/data/garibelt/comparativo/
            kpi_comparativo.csv         perfil Garibelt por escenario (formato largo)
            bv_comparativo.csv          B(v) por nodo en los 3 escenarios + deltas y rangos
            cobertura_comparativa.csv   cobertura por demarcación + deltas
            distribucion_bandas.csv     nodos por banda × dimensión × escenario
            transicion_bandas.csv       matriz Baseline → MB / Metro por dimensión

Uso:
    python utils/compare_garibelt_scenarios.py
"""

import json
from pathlib import Path

import pandas as pd

REPO = Path(__file__).parent.parent
LAYERS = REPO / "data" / "processed" / "garibelt"
CSVS = REPO / "tableau" / "exports" / "data" / "garibelt"
OUT_QGIS = LAYERS / "comparativo"
OUT_TAB = CSVS / "comparativo"

ESC = {
    "baseline": {"label": "Red Actual", "perfil": LAYERS / "perfil_nodos_baseline.geojson",
                 "csv": CSVS / "escenario-base", "sfx": "baseline"},
    "mb":       {"label": "Anillo MB", "perfil": LAYERS / "scenario-mb" / "perfil_nodos_mb.geojson",
                 "csv": CSVS / "escenario-mb", "sfx": "scenario_mb"},
    "metro":    {"label": "Anillo Metro", "perfil": LAYERS / "scenario-metro" / "perfil_nodos_metro.geojson",
                 "csv": CSVS / "escenario-metro", "sfx": "scenario_metro"},
}
BANDA_ORDEN = {"critico": 0, "debil": 1, "aceptable": 2, "idoneo": 3}


def load_perfil(esc: str) -> pd.DataFrame:
    feats = json.load(open(ESC[esc]["perfil"], encoding="utf-8"))["features"]
    rows = [{**f["properties"], "lon": f["geometry"]["coordinates"][0],
             "lat": f["geometry"]["coordinates"][1]} for f in feats]
    return pd.DataFrame(rows).set_index("id")


def load_csv(esc: str, nombre: str) -> pd.DataFrame:
    return pd.read_csv(ESC[esc]["csv"] / f"{nombre}_{ESC[esc]['sfx']}.csv")


def cambio(origen: str, destino: str) -> str:
    if pd.isna(origen):
        return "nuevo"
    d = BANDA_ORDEN[destino] - BANDA_ORDEN[origen]
    return "mejora" if d > 0 else "empeora" if d < 0 else "igual"


def kpi() -> pd.DataFrame:
    df = pd.concat([load_csv(e, "garibelt_perfil").assign(escenario=e, escenario_label=ESC[e]["label"])
                    for e in ESC], ignore_index=True)
    return df[["escenario", "escenario_label", "dimension", "indicador_fuente",
               "valor_bruto", "valor_normalizado", "banda"]]


def bv(perfiles: dict) -> pd.DataFrame:
    df = perfiles["baseline"][["nombre", "sistema", "lon", "lat"]].combine_first(
        perfiles["metro"][["nombre", "sistema", "lon", "lat"]])
    for e, p in perfiles.items():
        df[f"bv_{e}"] = p["betweenness_centrality"]
        df[f"rank_{e}"] = p["betweenness_centrality"].rank(ascending=False, method="min")
    alc = pd.concat([load_csv(e, "b_ranking") for e in ESC]).drop_duplicates("id").set_index("id")
    df["alcaldia_municipio"] = alc["alcaldia_municipio"]
    df["es_nodo_anillo"] = ~df.index.isin(perfiles["baseline"].index)
    df["delta_mb"] = df["bv_mb"] - df["bv_baseline"]
    df["delta_metro"] = df["bv_metro"] - df["bv_baseline"]
    df["delta_metro_pct"] = 100 * df["delta_metro"] / df["bv_baseline"].where(df["bv_baseline"] > 0)
    return df.reset_index().sort_values("bv_metro", ascending=False)


def cobertura() -> pd.DataFrame:
    base = load_csv("baseline", "cobertura_alcaldias").set_index("nombre")
    df = base[["area_total_km2"]].copy()
    for e in ESC:
        c = load_csv(e, "cobertura_alcaldias").set_index("nombre")
        df[f"cob_{e}"] = c["cobertura_pct"]
        df[f"categoria_{e}"] = c["categoria_cobertura"]
    df["delta_mb"] = (df["cob_mb"] - df["cob_baseline"]).round(2)
    df["delta_metro"] = (df["cob_metro"] - df["cob_baseline"]).round(2)
    df["cambia"] = (df["delta_mb"].abs() > 0.005) | (df["delta_metro"].abs() > 0.005)
    return df.reset_index().sort_values("delta_metro", ascending=False)


def distribucion(perfiles: dict) -> pd.DataFrame:
    rows = []
    for e, p in perfiles.items():
        for dim in ["banda_dominante", "fc_banda", "b_banda"]:
            n = p[dim].value_counts()
            for banda, cnt in n.items():
                rows.append({"escenario": e, "escenario_label": ESC[e]["label"], "dimension": dim,
                             "banda": banda, "orden_banda": BANDA_ORDEN.get(banda),
                             "n_nodos": int(cnt), "pct": round(100 * cnt / n.sum(), 2)})
    return pd.DataFrame(rows)


def transicion(perfiles: dict) -> pd.DataFrame:
    rows = []
    base = perfiles["baseline"]
    for e in ["mb", "metro"]:
        for dim in ["banda_dominante", "fc_banda"]:
            j = perfiles[e][[dim]].join(base[[dim]], rsuffix="_base", how="left")
            j[f"{dim}_base"] = j[f"{dim}_base"].fillna("nuevo")
            for (o, d), cnt in j.groupby([f"{dim}_base", dim]).size().items():
                rows.append({"escenario_destino": e, "escenario_label": ESC[e]["label"],
                             "dimension": dim, "banda_origen": o, "banda_destino": d,
                             "n_nodos": int(cnt), "cambia": o != d})
    return pd.DataFrame(rows)


def cambio_banda_geojson(perfiles: dict) -> list:
    b, m, t = (perfiles[e]["banda_dominante"] for e in ["baseline", "mb", "metro"])
    df = pd.DataFrame({"banda_baseline": b, "banda_mb": m, "banda_metro": t})
    df["cambio_mb"] = [cambio(o, d) for o, d in zip(df["banda_baseline"], df["banda_mb"])]
    df["cambio_metro"] = [cambio(o, d) for o, d in zip(df["banda_baseline"], df["banda_metro"])]
    df = df[(df["cambio_mb"].isin(["mejora", "empeora"])) | (df["cambio_metro"].isin(["mejora", "empeora"]))]
    ref = perfiles["metro"]
    feats = []
    for nid, r in df.iterrows():
        p = ref.loc[nid]
        props = {"id": nid, "nombre": p["nombre"], "sistema": p["sistema"],
                 **{k: (None if pd.isna(v) else v) for k, v in r.items()}}
        feats.append({"type": "Feature", "properties": props,
                      "geometry": {"type": "Point", "coordinates": [p["lon"], p["lat"]]}})
    return feats


def delta_bv_geojson(bv_df: pd.DataFrame, umbral: float = 0.01) -> list:
    """Nodos con |ΔB(v) Metro − Base| ≥ umbral, más los nodos del anillo en el Top 50 de Metro."""
    df = bv_df.copy()
    df["delta_metro_plot"] = df["delta_metro"].fillna(df["bv_metro"])
    sel = (df["delta_metro_plot"].abs() >= umbral) | (df["es_nodo_anillo"] & (df["rank_metro"] <= 50))
    df = df[sel]
    df["tipo_cambio"] = ["nodo_anillo" if a else "gana" if d > 0 else "pierde"
                         for a, d in zip(df["es_nodo_anillo"], df["delta_metro_plot"])]
    cols = ["id", "nombre", "sistema", "alcaldia_municipio", "bv_baseline", "bv_metro",
            "rank_baseline", "rank_metro", "delta_metro_plot", "delta_metro_pct", "es_nodo_anillo", "tipo_cambio"]
    return [{"type": "Feature",
             "properties": {c: (None if pd.isna(r[c]) else r[c]) for c in cols},
             "geometry": {"type": "Point", "coordinates": [r["lon"], r["lat"]]}}
            for _, r in df.iterrows()]


def cobertura_delta_geojson(cob_df: pd.DataFrame) -> list:
    """Demarcaciones cuya cobertura cambia con el anillo (geometría de la capa MB)."""
    src = LAYERS / "scenario-mb" / "cobertura_garibelt_mb.geojson"
    geoms = {f["properties"]["nombre"]: f["geometry"] for f in json.load(open(src, encoding="utf-8"))["features"]}
    df = cob_df[cob_df["cambia"]]
    cols = ["nombre", "cob_baseline", "cob_mb", "delta_mb", "categoria_baseline", "categoria_mb", "area_total_km2"]
    return [{"type": "Feature",
             "properties": {**{c: r[c] for c in cols},
                            "km2_ganados": round(r["area_total_km2"] * r["delta_mb"] / 100, 2)},
             "geometry": geoms[r["nombre"]]}
            for _, r in df.iterrows()]


def main() -> None:
    OUT_QGIS.mkdir(parents=True, exist_ok=True)
    OUT_TAB.mkdir(parents=True, exist_ok=True)
    perfiles = {e: load_perfil(e) for e in ESC}

    tablas = {
        "kpi_comparativo": kpi(),
        "bv_comparativo": bv(perfiles),
        "cobertura_comparativa": cobertura(),
        "distribucion_bandas": distribucion(perfiles),
        "transicion_bandas": transicion(perfiles),
    }
    for nombre, df in tablas.items():
        path = OUT_TAB / f"{nombre}.csv"
        df.to_csv(path, index=False, encoding="utf-8")
        print(f"  ✓ {path.relative_to(REPO)}  ({len(df)} filas)")

    capas = {
        "cambio_banda": cambio_banda_geojson(perfiles),
        "delta_bv": delta_bv_geojson(tablas["bv_comparativo"]),
        "cobertura_delta": cobertura_delta_geojson(tablas["cobertura_comparativa"]),
    }
    for nombre, feats in capas.items():
        path = OUT_QGIS / f"{nombre}.geojson"
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"type": "FeatureCollection", "features": feats}, f, ensure_ascii=False)
        print(f"  ✓ {path.relative_to(REPO)}  ({len(feats)} features)")


if __name__ == "__main__":
    main()
