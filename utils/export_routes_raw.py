"""
export_routes_raw.py — Muestra de rutas O-D con geometría (network_route) desde el código de VFTModel.

Reemplaza el paso manual del notebook VFTModel/notebooks/04_Detaur_factor.ipynb (celdas 1, 2 y 4):
la API REST de VFTModel no devuelve la geometría de las rutas, por eso se construye el grafo
localmente con el mismo código y parámetros que el servidor (REALISTIC_INTEGRATION, tolerancia Q1).

Debe ejecutarse con el intérprete de VFTModel (no modifica VFTModel, solo importa su código):
    ../VFTModel/.venv/bin/python utils/export_routes_raw.py --scenario baseline

Salida: utils/data/routes_raw_<scenario>.json  (gitignored; insumo de generate_exports.py --linestrings)
Requiere Apimetro del escenario corriendo (baseline :8080 · mb :8083 · metro :8084).
"""

import argparse
import asyncio
import json
import os
import statistics
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VFT = Path(os.getenv("VFTMODEL_DIR", REPO.parent / "VFTModel")).resolve()

APIMETRO = {
    "baseline": "http://localhost:8080/movilidad",
    "mb": "http://localhost:8083/movilidad",
    "metro": "http://localhost:8084/movilidad",
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--scenario", choices=list(APIMETRO), default="baseline")
    parser.add_argument("--sample-size", type=int, default=100)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    # APIMETRO_URL se lee al importar el cliente de VFTModel: fijarla antes de importar.
    os.environ["APIMETRO_URL"] = APIMETRO[args.scenario]
    os.environ.setdefault("MPLBACKEND", "Agg")
    sys.path.insert(0, str(VFT))

    from src.infrastructure.go_client.client import fetch_full_network
    from src.api.schemas.schemas import GeoJSONTransportSchema
    from src.core.services.graph_builder import VFTGraphBuilder
    from src.core.algorithms.topological.detaurFactor import DetourFactorOrchestrator

    print(f"── Rutas O-D {args.scenario} ({os.environ['APIMETRO_URL']}) ──")
    raw = asyncio.run(fetch_full_network())
    G = VFTGraphBuilder(GeoJSONTransportSchema(**raw)).build_graph(mode="REALISTIC_INTEGRATION")
    print(f"  Grafo: {G.number_of_nodes()} nodos, {G.number_of_edges()} aristas")

    routes = DetourFactorOrchestrator(G).calculate_sample_routes(
        sample_size=args.sample_size, seed=args.seed, return_json=True
    )

    out = REPO / "utils" / "data" / f"routes_raw_{args.scenario}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(routes, f, ensure_ascii=False, default=str)

    dfs = [float(r["metrics"]["Factor_Desviacion"]) for r in routes]
    print(f"  ✓ {out.relative_to(REPO)}  {len(routes)} rutas | DF min {min(dfs)} · "
          f"max {max(dfs)} · media {statistics.mean(dfs):.3f}")
    if min(dfs) < 1.0:
        print("  ⚠ DF < 1.0: revisar graph_builder (VFTModel #22)")


if __name__ == "__main__":
    main()
