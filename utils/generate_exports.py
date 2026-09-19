"""
generate_exports.py — genera todos los GeoJSONs estáticos para Tableau.

Uso:
    cd Transport-gis-zmvm-mjg

    # Baseline (comportamiento original)
    python utils/generate_exports.py

    # Escenario MB
    python utils/generate_exports.py --url http://localhost:8001 --scenario scenario_mb

    # Escenario METRO
    python utils/generate_exports.py --url http://localhost:8002 --scenario scenario_metro

Requiere:
    - VFTModel corriendo en la URL indicada (calentar primero con make warmup-<escenario>)
    - Dependencias: httpx, geopandas, shapely  (disponibles en .venv)

Salidas:
    baseline     → tableau/exports/geo/               (sin GPKG)
    scenario_mb  → tableau/exports/geo/scenario_mb/   + data/processed/scenarios/VFTOutput_scenario_mb.gpkg
    scenario_metro → tableau/exports/geo/scenario_metro/ + data/processed/scenarios/VFTOutput_scenario_metro.gpkg
"""

from pathlib import Path
from typing import Optional
import sys
import json

sys.path.insert(0, str(Path(__file__).parents[1]))

from utils.clients.vft_client import VFTClient
from utils.exporters.geo_exporter import GeoExporter, TABLEAU_GEO_DIR

import geopandas as gpd

_REPO_ROOT = Path(__file__).parent.parent
_SCENARIOS_DIR = _REPO_ROOT / "data" / "processed" / "scenarios"


def _geo_dir(scenario: str) -> Path:
    if scenario == "baseline":
        return TABLEAU_GEO_DIR
    return TABLEAU_GEO_DIR / scenario


def _save_gpkg(gdfs: dict, scenario: str) -> None:
    _SCENARIOS_DIR.mkdir(parents=True, exist_ok=True)
    out = _SCENARIOS_DIR / f"VFTOutput_{scenario}.gpkg"
    if out.exists():
        out.unlink()
    for i, (layer_name, gdf) in enumerate(gdfs.items()):
        mode = "w" if i == 0 else "a"
        gdf.to_file(out, driver="GPKG", layer=layer_name, mode=mode)
    print(f"✅  GPKG → {out} ({len(gdfs)} capas)")


def run_camino_a(client: VFTClient, geo_dir: Path) -> dict:
    """
    Camino A — exportaciones vía REST.
    Requiere solo VFTModel activo; no necesita el SDK Python de VFTModel.
    Retorna dict con los GDFs exportados (usado para generar el GPKG en escenarios).
    """
    print("\n── Camino A: exportaciones REST ──────────────────────────────")

    print("  [warmup] build-auto...")
    info = client.build_graph()
    print(f"  Grafo: {info.get('nodos','?')} nodos")

    gdfs = {}

    print("  [1/4] df_puntos (Factor de Desviación)...")
    fc = client.fetch_detour_routes(sample_size=200, seed=42)
    gdf = GeoExporter.from_geolayer(fc)
    GeoExporter.save(gdf, "df_puntos", geo_dir)
    gdfs["df_puntos"] = gdf

    print("  [2/4] fc_puntos (Fuerza Capilar)...")
    fc = client.fetch_capillary_puntos(min_fc=3)
    gdf = GeoExporter.from_geolayer(fc)
    GeoExporter.save(gdf, "fc_puntos", geo_dir)
    gdfs["fc_puntos"] = gdf

    print("  [3/4] b_puntos (Centralidad B) — puede tardar hasta 8 min primera vez...")
    fc = client.fetch_betweenness(limit=2000)
    gdf = GeoExporter.from_geolayer(fc)
    GeoExporter.save(gdf, "b_puntos", geo_dir)
    gdfs["b_puntos"] = gdf

    print("  [4/4] cobertura_estaciones...")
    fc = client.fetch_coverage(radio_m=800)
    gdf = GeoExporter.from_geolayer(fc)
    GeoExporter.save(gdf, "cobertura_estaciones", geo_dir)
    gdfs["cobertura_estaciones"] = gdf

    return gdfs


def run_camino_b(routes_json_path: Optional[str] = None, geo_dir: Path = TABLEAU_GEO_DIR):
    """
    Camino B — exportar rutas O-D como LineStrings.

    Este camino requiere datos completos con map_data.network_route,
    que el REST API no devuelve. Hay dos formas de obtenerlos:

    Opción 1 — desde VFTModel notebook (recomendado):
        1. Abrir VFTModel/notebooks/04_Detaur_factor.ipynb
        2. Ejecutar hasta la celda de muestra_json
        3. Agregar al final:
               import json
               with open("routes_raw.json", "w") as f:
                   json.dump(muestra_json, f)
        4. Copiar routes_raw.json a Transport-gis-zmvm-mjg/utils/data/
        5. Ejecutar: python utils/generate_exports.py --linestrings utils/data/routes_raw.json

    Opción 2 — pasar la ruta como argumento a esta función.
    """
    if routes_json_path is None:
        default = Path(__file__).parent / "data" / "routes_raw.json"
        if default.exists():
            routes_json_path = str(default)
        else:
            print("\n── Camino B: LineStrings ─────────────────────────────────────")
            print("  ⚠️  No se encontró routes_raw.json.")
            print("  Sigue las instrucciones en run_camino_b() para generarlo.")
            return

    print(f"\n── Camino B: LineStrings desde {routes_json_path} ───────────────")
    with open(routes_json_path) as f:
        routes = json.load(f)

    print(f"  {len(routes)} rutas cargadas.")
    gdf = GeoExporter.routes_to_linestrings(routes)
    GeoExporter.save(gdf, "df_rutas_lineas", geo_dir)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Genera GeoJSONs para Tableau desde VFTModel.")
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="URL base de VFTModel (default: http://localhost:8000).",
    )
    parser.add_argument(
        "--scenario",
        default="baseline",
        choices=["baseline", "scenario_mb", "scenario_metro"],
        help="Escenario de salida — define la subcarpeta y si se genera GPKG (default: baseline).",
    )
    parser.add_argument(
        "--linestrings",
        metavar="PATH",
        help="Ruta a routes_raw.json para exportar LineStrings (Camino B).",
        default=None,
    )
    parser.add_argument(
        "--only-linestrings",
        action="store_true",
        help="Ejecutar solo el Camino B (omite exportaciones REST).",
    )
    args = parser.parse_args()

    client = VFTClient(base_url=args.url, timeout=600.0)
    geo_dir = _geo_dir(args.scenario)

    if not args.only_linestrings:
        gdfs = run_camino_a(client, geo_dir)
        if args.scenario != "baseline":
            _save_gpkg(gdfs, args.scenario)

    run_camino_b(args.linestrings, geo_dir)

    print("\nListo. Abre Tableau y reconecta las fuentes espaciales.")
