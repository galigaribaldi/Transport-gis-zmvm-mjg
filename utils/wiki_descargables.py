"""
wiki_descargables.py — genera la página «Descargables» de la wiki a partir de los exports del repo.

Cada grupo de exports (mapas QGIS, dashboards Tableau, gráficas de notebooks) se asocia a un
GitHub Release. Para cada archivo la página ofrece:
  - Ver:       vista del archivo en el repo (GitHub muestra el PDF; los archivos viven en Git LFS)
  - Descargar: el asset del Release si existe y coincide en tamaño con el archivo del repo;
               si no, la descarga directa desde Git LFS
Los PNG se incrustan como vista previa.

Uso:
    python3 utils/wiki_descargables.py                       # Markdown a stdout, sin consultar GitHub
    python3 utils/wiki_descargables.py --releases            # consulta los Releases con `gh` (solo lectura)
    python3 utils/wiki_descargables.py --releases --out ../Transport-gis-zmvm-mjg.wiki/Descargables.md
    python3 utils/wiki_descargables.py --comandos            # imprime los `gh release create/upload` pendientes

No crea ni modifica Releases: los comandos se imprimen para ejecutarlos a mano.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GH_REPO = "galigaribaldi/Transport-gis-zmvm-mjg"
RAMA = "main"
VER = f"https://github.com/{GH_REPO}/blob/{RAMA}/"
LFS = f"https://media.githubusercontent.com/media/{GH_REPO}/{RAMA}/"
ASSET = f"https://github.com/{GH_REPO}/releases/download/"

# (título, carpeta, patrón, tag del Release, descripción del Release)
GRUPOS = [
    ("Mapas QGIS · Red actual", "maps/exports/pdf/Scenarios/Red_Actual", "**/*.pdf",
     "v2026-2-tesis-mapas-red-actual", "Mapas base e indicadores VFTModel de la red actual (Caso 1, datos 2025)."),
    ("Mapas QGIS · Propuestas anillares", "maps/exports/pdf/Scenarios", "Propuesta_*/**/*.pdf",
     "v2026-2-tesis-mapas-propuesta", "Trazado del anillo y lámina extendida, Caso 2 (Anillo MB) y Caso 3 (Anillo Metro)."),
    ("Mapas QGIS · Clasificación Garibelt y comparativos", "maps/exports/pdf/Clasificacion_Garibelt", "**/*.pdf",
     "v2026-2-tesis-mapas-garibelt", "Clasificación Garibelt por caso y comparativos entre casos (B(v), cobertura, cambio de banda)."),
    ("Dashboards Tableau · Apimetro", "tableau/exports/pdf/Apimetro", "**/*.pdf",
     "v2026-2-tesis-dashboards-apimetro", "Dashboards y gráficas de la red Apimetro (afluencia, jerarquía, calidad de servicio)."),
    ("Dashboards Tableau · VFTModel", "tableau/exports/pdf/VFTModel", "**/*.pdf",
     "v2026-2-tesis-dashboards-vftmodel", "Dashboards y gráficas de indicadores VFTModel de la red actual."),
    ("Dashboards Tableau · Clasificación Garibelt", "tableau/exports/pdf/Clasificacion_Garibelt", "**/*.pdf",
     "v2026-2-tesis-dashboards-garibelt", "KPI, Clasificación, Espectro y Betweenness por caso, y comparativo Caso 1 · 2 · 3."),
    ("Gráficas · Capítulo 6", "analysis/notebooks/output/cap6", "*.*",
     "v2026-2-tesis-graficas-cap6", "Gráficas G1–G8 del Cap. 6 (graficas_cap6.ipynb), PDF vectorial y PNG 300 dpi."),
]


def _assets_release(tag: str) -> dict[str, int] | None:
    """Assets del Release (nombre → bytes), o None si el tag no existe. Solo lectura vía `gh`."""
    r = subprocess.run(["gh", "release", "view", tag, "--repo", GH_REPO, "--json", "assets"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return {a["name"]: a["size"] for a in json.loads(r.stdout)["assets"]}


def _archivos(carpeta: str, patron: str) -> list[Path]:
    base = REPO / carpeta
    return sorted(p for p in base.glob(patron) if p.is_file() and p.suffix.lower() in (".pdf", ".png"))


def _titulo(p: Path) -> str:
    return p.stem.replace("_", " ")


def _seccion(p: Path, carpeta: str) -> str:
    rel = p.parent.relative_to(REPO / carpeta).as_posix()
    return rel.replace("_", " ").replace("/", " · ") if rel != "." else "—"


def _mb(n: int) -> str:
    return f"{n / 1_048_576:.1f} MB" if n >= 1_048_576 else f"{n / 1024:.0f} KB"


def generar(consultar: bool) -> tuple[str, list[str]]:
    lineas, comandos = [], []
    lineas += [
        "# Descargables",
        "",
        "Mapas, dashboards y gráficas exportados en este repositorio. Los archivos viven en **Git LFS**; "
        "las versiones de entrega se publican como **[GitHub Releases](https://github.com/"
        f"{GH_REPO}/releases)**, que no consumen la cuota de descarga de LFS.",
        "",
        "- **Ver** abre el archivo en GitHub (el visor muestra el PDF).",
        "- **Descargar** baja el asset del Release; si el Release aún no existe o está desactualizado, "
        "baja el archivo directo de Git LFS.",
        "",
        "> Página generada con `python3 utils/wiki_descargables.py --releases`. No la edites a mano: "
        "vuelve a generarla después de re-exportar o publicar un Release.",
        "",
    ]
    resumen = ["| Grupo | Archivos | Tamaño | Release | Estado |", "|---|---|---|---|---|"]
    cuerpo = []
    for titulo, carpeta, patron, tag, desc in GRUPOS:
        archivos = _archivos(carpeta, patron)
        if not archivos:
            continue
        assets = _assets_release(tag) if consultar else None
        total = sum(a.stat().st_size for a in archivos)
        if assets is None:
            estado = "sin publicar" if consultar else "no consultado"
        else:
            vigentes = sum(1 for a in archivos if assets.get(a.name) == a.stat().st_size)
            estado = "✓ vigente" if vigentes == len(archivos) else f"⚠ {len(archivos) - vigentes} por actualizar"
        ancla = titulo.lower().replace(" · ", "--").replace(" ", "-")
        resumen.append(f"| [{titulo}](#{ancla}) | {len(archivos)} | {_mb(total)} | `{tag}` | {estado} |")

        cuerpo += [f"## {titulo}", "", desc, "",
                   f"Carpeta: `{carpeta}/` · Release: [`{tag}`](https://github.com/{GH_REPO}/releases/tag/{tag})", "",
                   "| Recurso | Sección | Formato | Tamaño | Ver | Descargar |", "|---|---|---|---|---|---|"]
        pendientes = []
        for a in archivos:
            rel = a.relative_to(REPO).as_posix()
            n = a.stat().st_size
            en_release = assets is not None and assets.get(a.name) == n
            descarga = f"[Release]({ASSET}{tag}/{a.name})" if en_release else f"[LFS]({LFS}{rel})"
            if assets is not None and not en_release:
                descarga += " ⚠" if a.name in assets else ""
                pendientes.append(rel)
            elif assets is None:
                pendientes.append(rel)
            cuerpo.append(f"| {_titulo(a)} | {_seccion(a, carpeta)} | {a.suffix[1:].upper()} | {_mb(n)} "
                          f"| [Ver]({VER}{rel}) | {descarga} |")
        pngs = [a for a in archivos if a.suffix.lower() == ".png"]
        if pngs:
            cuerpo += ["", "<details><summary>Vista previa</summary>", ""]
            for a in pngs:
                rel = a.relative_to(REPO).as_posix()
                cuerpo += [f"**{_titulo(a)}**", "", f"![{_titulo(a)}]({LFS}{rel})", ""]
            cuerpo.append("</details>")
        cuerpo.append("")

        if pendientes:
            lista = " \\\n    ".join(pendientes)
            if assets is None:
                comandos.append(f'gh release create {tag} --repo {GH_REPO} --target {RAMA} \\\n'
                                f'    --title "{titulo} — Tesis 2026-2" \\\n'
                                f'    --notes "{desc} Corrida VFTModel 2026-10-04." \\\n    {lista}')
            else:
                comandos.append(f"gh release upload {tag} --repo {GH_REPO} --clobber \\\n    {lista}")

    lineas += ["## Resumen", ""] + resumen + [""] + cuerpo
    lineas += ["## Releases anteriores", "",
               "Se conservan como histórico; sus archivos son versiones previas a las correcciones de datos del 2026-10-05.",
               "", "| Release | Contenido |", "|---|---|",
               f"| [`v1.0.0-red-actual`](https://github.com/{GH_REPO}/releases/tag/v1.0.0-red-actual) | Red actual, 2026-09-14 (21 PDF) |",
               f"| [`v2026-2-col-mapas-*`](https://github.com/{GH_REPO}/releases) | Mapas del Coloquio 2026-2, 2026-06-01 |",
               "", f"*Generada el {date.today().isoformat()}.*", ""]
    return "\n".join(lineas), comandos


def main() -> int:
    ap = argparse.ArgumentParser(description="Genera la página Descargables de la wiki.")
    ap.add_argument("--releases", action="store_true", help="Consultar los Releases con gh (solo lectura)")
    ap.add_argument("--out", type=Path, help="Escribir la página en este archivo")
    ap.add_argument("--comandos", action="store_true", help="Imprimir los comandos gh para publicar lo pendiente")
    args = ap.parse_args()

    pagina, comandos = generar(args.releases or args.comandos)
    if args.comandos:
        print("\n\n".join(comandos) if comandos else "# Todo publicado y vigente.")
        return 0
    if args.out:
        args.out.write_text(pagina, encoding="utf-8")
        print(f"→ {args.out}")
    else:
        sys.stdout.write(pagina)
    return 0


if __name__ == "__main__":
    sys.exit(main())
