"""
build_demanda_alcaldia.py
Genera demanda_alcaldia.csv con afluencia total por alcaldía/municipio.

Cruza:
  - GET /movilidad/analitico/afluencia-estacion  → afluencia por estación/año/mes
  - GET /movilidad/mapas/geojsonEstacion          → estaciones con alcaldia_municipio

Salida: tableau/exports/data/demanda_alcaldia.csv

Uso:
    cd Transport-gis-zmvm-mjg
    python3 tableau/scripts/build_demanda_alcaldia.py
"""

import os
import pathlib
import sys

try:
    import requests
except ImportError:
    sys.exit("Instala requests: pip3 install requests")

try:
    import pandas as pd
except ImportError:
    sys.exit("Instala pandas: pip3 install pandas")

APIMETRO_URL = os.getenv("APIMETRO_URL", "http://localhost:8080")
OUTPUT_DIR = pathlib.Path(__file__).parent.parent / "exports" / "data"
OUTPUT_FILE = OUTPUT_DIR / "demanda_alcaldia.csv"


def fetch_json(url: str, label: str):
    print(f"  GET {url}")
    r = requests.get(url, timeout=120)
    r.raise_for_status()
    print(f"  OK — {len(r.content) // 1024} KB recibidos ({label})")
    return r.json()


def main():
    print("\n=== build_demanda_alcaldia.py ===\n")

    # ── 1. Afluencia por estación ────────────────────────────────────────────
    raw_afluencia = fetch_json(
        f"{APIMETRO_URL}/movilidad/analitico/afluencia-estacion",
        "afluencia-estacion",
    )
    records = raw_afluencia["data"] if isinstance(raw_afluencia, dict) and "data" in raw_afluencia else raw_afluencia
    df_afluencia = pd.DataFrame(records)
    print(f"\n  Registros de afluencia : {len(df_afluencia):,}")
    print(f"  Columnas               : {list(df_afluencia.columns)}\n")

    # ── 2. Estaciones con alcaldía ──────────────────────────────────────────
    geojson = fetch_json(
        f"{APIMETRO_URL}/movilidad/mapas/geojsonEstacion",
        "geojsonEstacion",
    )
    estaciones = [
        {
            "nombre_estacion": f["properties"].get("nombre", ""),
            "alcaldia_municipio": f["properties"].get("alcaldia_municipio", ""),
            "sistema": f["properties"].get("sistema", ""),
        }
        for f in geojson["features"]
    ]
    df_estaciones = (
        pd.DataFrame(estaciones)
        .query("sistema == 'METRO'")
        .drop_duplicates("nombre_estacion")
    )
    print(f"\n  Estaciones únicas      : {len(df_estaciones):,}\n")

    # ── 3. Detectar columna de nombre de estación en afluencia ──────────────
    candidatos = ["nombre_estacion", "estacion", "nombre", "NombreEstacion"]
    station_col = next((c for c in candidatos if c in df_afluencia.columns), None)

    if station_col is None:
        sys.exit(
            f"ERROR: no se encontró columna de nombre de estación.\n"
            f"Columnas disponibles: {list(df_afluencia.columns)}"
        )
    print(f"  Columna de estación detectada: '{station_col}'")

    # ── 4. Cruzar y agregar ─────────────────────────────────────────────────
    df_merged = df_afluencia.merge(
        df_estaciones,
        left_on=station_col,
        right_on="nombre_estacion",
        how="left",
    )

    sin_alcaldia = df_merged["alcaldia_municipio"].isna().sum()
    if sin_alcaldia:
        print(f"  Advertencia: {sin_alcaldia:,} registros sin alcaldía (se omiten)")

    df_demanda = (
        df_merged
        .dropna(subset=["alcaldia_municipio"])
        .groupby("alcaldia_municipio", dropna=True)["afluencia"]
        .sum()
        .reset_index()
        .rename(columns={
            "alcaldia_municipio": "Alcaldia_Municipio",
            "afluencia": "Total_Afluencia",
        })
        .sort_values("Total_Afluencia", ascending=False)
        .reset_index(drop=True)
    )

    # ── 5. Exportar ─────────────────────────────────────────────────────────
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    df_demanda.to_csv(OUTPUT_FILE, index=False, encoding="utf-8")

    print(f"\n  Archivo generado: {OUTPUT_FILE}")
    print(f"  Filas           : {len(df_demanda)}\n")
    print("  Top 10 alcaldías por afluencia:")
    print(df_demanda.head(10).to_string(index=False))
    print("\nListo.\n")


if __name__ == "__main__":
    main()
