"""
copy_workbook_scenario.py — copia los workbooks Tableau (VFTModel y Apimetro)
y adapta todas las fuentes de datos para un escenario específico.

Uso:
    python utils/copy_workbook_scenario.py scenario_mb
    python utils/copy_workbook_scenario.py scenario_metro

Cambios que aplica en VFTModel:
    - WDC VFTModel:              localhost:8000 → localhost:8001/8002
    - exports/geo:               → exports/geo/<escenario>
    - connectors/VFTModel/exports → connectors/VFTModel/exports/<escenario>

Cambios que aplica en Apimetro:
    - WDC Apimetro:              localhost:8080 → localhost:8083/8084
    - exports/geo:               → exports/geo/<escenario>

Nota: antes de abrir los workbooks de escenario en Tableau,
asegurarse de que lineas.geojson y poligonos.geojson existen en
tableau/exports/geo/<escenario>/ (ver instrucciones en README del directorio).
"""

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
WORKBOOKS_DIR = REPO_ROOT / "tableau" / "workbooks"

# Puerto VFTModel por escenario
VFT_PORTS = {
    "scenario_mb":    8001,
    "scenario_metro": 8002,
}

# Puerto Apimetro por escenario
APIMETRO_PORTS = {
    "scenario_mb":    8083,
    "scenario_metro": 8084,
}


def _replace_geo_dir(content: str, scenario: str) -> str:
    for quote in ("'", '"'):
        content = content.replace(
            f"tableau/exports/geo{quote}",
            f"tableau/exports/geo/{scenario}{quote}",
        )
    return content


def copy_vftmodel(scenario: str) -> Path:
    src = WORKBOOKS_DIR / "dashboard_viz04_red_vftmodel.twb"
    out = WORKBOOKS_DIR / f"dashboard_viz04_red_vftmodel_{scenario}.twb"
    port = VFT_PORTS[scenario]

    content = src.read_text(encoding="utf-8")

    # WDC VFTModel: cambiar puerto
    content = content.replace("localhost:8000&quot;", f"localhost:{port}&quot;")

    # GeoJSONs de exportación (b_puntos, fc_puntos, etc.)
    content = _replace_geo_dir(content, scenario)

    # GeoJSONs de conectores (df_por_alcaldia, cobertura_*, etc.)
    for quote in ("'", '"'):
        content = content.replace(
            f"connectors/VFTModel/exports{quote}",
            f"connectors/VFTModel/exports/{scenario}{quote}",
        )

    out.write_text(content, encoding="utf-8")
    print(f"✅  {out.name}")
    print(f"    WDC VFTModel   → localhost:{port}")
    print(f"    exports/geo    → exports/geo/{scenario}/")
    print(f"    VFTModel/exports → VFTModel/exports/{scenario}/")
    return out


def copy_apimetro(scenario: str) -> Path:
    src = WORKBOOKS_DIR / "dashboard_viz04_red_apimetro.twb"
    out = WORKBOOKS_DIR / f"dashboard_viz04_red_apimetro_{scenario}.twb"
    port = APIMETRO_PORTS[scenario]

    content = src.read_text(encoding="utf-8")

    # WDC Apimetro: cambiar puerto en connectionData Y en el caption/nombre visible
    content = content.replace("localhost:8080&quot;", f"localhost:{port}&quot;")
    content = content.replace("localhost:8080", f"localhost:{port}")

    # GeoJSONs estáticos (lineas.geojson refleja la red del escenario)
    content = _replace_geo_dir(content, scenario)

    out.write_text(content, encoding="utf-8")
    print(f"✅  {out.name}")
    print(f"    WDC Apimetro   → localhost:{port}")
    print(f"    exports/geo    → exports/geo/{scenario}/")
    return out


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in VFT_PORTS:
        print(f"Uso: python {sys.argv[0]} <escenario>")
        print(f"Escenarios: {', '.join(VFT_PORTS)}")
        sys.exit(1)

    scenario = sys.argv[1]
    print(f"\n── Escenario: {scenario} ──────────────────────────────────────")
    copy_vftmodel(scenario)
    print()
    copy_apimetro(scenario)
    print()

    geo_dir = REPO_ROOT / "tableau" / "exports" / "geo" / scenario
    apimetro_port = APIMETRO_PORTS[scenario]
    missing = [f for f in ("lineas.geojson", "poligonos.geojson") if not (geo_dir / f).exists()]
    if missing:
        print(f"⚠️  Pendiente en {geo_dir.relative_to(REPO_ROOT)}/: {', '.join(missing)}")
        print(f"   Ejecutar: make export-lineas-{scenario.replace('scenario_', '')}  (Apimetro :{apimetro_port})")
    else:
        print(f"✅  GeoJSONs Apimetro ya presentes en tableau/exports/geo/{scenario}/")
