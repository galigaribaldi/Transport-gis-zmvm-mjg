"""
check_paths.py — verifica que existan todos los archivos que usan los proyectos de Tableau y QGIS.

Lee las conexiones de cada .twb (tableau/workbooks y tableau/templates) y las capas de cada .qgz
(maps/projects). Las rutas que contienen el nombre del repo se resuelven contra la raíz actual,
de modo que el chequeo funciona aunque el repo se clone en otra carpeta.

Uso:
    python3 utils/check_paths.py              # reporte por proyecto; sale con 1 si falta algo
    python3 utils/check_paths.py --protegidas # lista única de rutas del repo que no se deben mover
    make check-paths

Solo usa la biblioteca estándar. No modifica ningún archivo.
"""
from __future__ import annotations

import argparse
import sys
import zipfile
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REPO_NAME = "Transport-gis-zmvm-mjg"
CLASES_ARCHIVO = {"textscan", "ogrdirect", "excel-direct", "hyper"}


def _a_repo(ruta: str) -> Path | None:
    """Convierte una ruta absoluta con el nombre del repo en una ruta dentro de REPO."""
    marca = f"/{REPO_NAME}/"
    if marca in ruta:
        return REPO / ruta.split(marca, 1)[1]
    return None


def refs_twb(twb: Path):
    """(tipo, ruta_original, Path resuelto o None, nota) por cada archivo que usa el workbook."""
    raiz = ET.parse(twb).getroot()
    vistos = set()
    for ext in raiz.iter("extract"):
        activo = ext.get("enabled") == "true"
        for c in ext.iter("connection"):
            if c.get("dbname"):
                vistos.add(("extracto", c.get("dbname"), "activo" if activo else "desactivado"))
    for c in raiz.iter("connection"):
        cls, d, f = c.get("class"), c.get("directory"), c.get("filename")
        if cls in CLASES_ARCHIVO and f:
            vistos.add((cls, f"{d}/{f}" if d else f, ""))
        elif cls == "webdata-direct" and f:
            vistos.add(("wdc", f"tableau/connectors/apimetro/{f}" if "apimetro" in f else f, "requiere servidor WDC"))
    for tipo, ruta, nota in sorted(vistos):
        p = _a_repo(ruta) or (REPO / ruta if not ruta.startswith("/") else Path(ruta))
        yield tipo, ruta, p, nota


def refs_qgz(qgz: Path):
    """(proveedor, ruta_original, Path resuelto, nota) por cada capa basada en archivo."""
    with zipfile.ZipFile(qgz) as z:
        qgs = next(n for n in z.namelist() if n.endswith(".qgs"))
        raiz = ET.fromstring(z.read(qgs))
    vistos = set()
    for capa in raiz.iter("maplayer"):
        prov = capa.findtext("provider") or ""
        ds = (capa.findtext("datasource") or "").strip()
        if prov in ("wms", "xyz", "virtual", "memory") or not ds or ds.startswith(("type=", "url=", "crs=")):
            continue
        ruta = ds.split("|")[0]
        if ruta.startswith("file://"):
            ruta = ruta[7:]
        vistos.add((prov, ruta))
    for prov, ruta in sorted(vistos, key=lambda x: x[1]):
        p = (qgz.parent / ruta).resolve() if not ruta.startswith("/") else (_a_repo(ruta) or Path(ruta))
        nota = "" if not ruta.startswith("/") else "ruta absoluta (usar relativa)"
        yield prov, ruta, p, nota


def main() -> int:
    ap = argparse.ArgumentParser(description="Verifica rutas de los proyectos Tableau y QGIS.")
    ap.add_argument("--protegidas", action="store_true", help="Lista las rutas del repo que usan los proyectos")
    args = ap.parse_args()

    proyectos = [(p, refs_twb) for p in sorted((REPO / "tableau").glob("*/*.twb"))]
    proyectos += [(p, refs_qgz) for p in sorted((REPO / "maps" / "projects").glob("*.qgz"))]

    usado_por = defaultdict(set)
    faltan, avisos = 0, 0
    for proyecto, lector in proyectos:
        rel = proyecto.relative_to(REPO)
        if not args.protegidas:
            print(f"\n{rel}")
        for tipo, ruta, p, nota in lector(proyecto):
            dentro = p.is_relative_to(REPO)
            existe = p.exists()
            if dentro and nota != "desactivado":
                usado_por[p.relative_to(REPO).as_posix()].add(rel.as_posix())
            if nota == "desactivado":
                estado = "·  "          # extracto desactivado: no se usa al abrir
            elif existe:
                estado = "✓  "
            elif dentro:
                estado, faltan = "✗  ", faltan + 1
            else:
                estado, avisos = "?  ", avisos + 1
            if not args.protegidas:
                mostrado = p.relative_to(REPO).as_posix() if dentro else ruta
                extra = f"  ({nota})" if nota else ("  (fuera del repo)" if not dentro else "")
                print(f"  {estado}[{tipo}] {mostrado}{extra}")

    if args.protegidas:
        for ruta in sorted(usado_por):
            print(f"{ruta}\t{', '.join(sorted(Path(x).stem for x in usado_por[ruta]))}")
        return 0

    print(f"\nProyectos: {len(proyectos)} · rutas del repo en uso: {len(usado_por)} · "
          f"faltan: {faltan} · fuera del repo sin verificar: {avisos}")
    print("Leyenda: ✓ existe · ✗ falta (rompe el proyecto) · · extracto desactivado · ? fuera del repo y no encontrado")
    return 1 if faltan else 0


if __name__ == "__main__":
    sys.exit(main())
