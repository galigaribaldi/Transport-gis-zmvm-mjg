#!/usr/bin/env bash
# Instala fuentes y dependencias del sistema para Transport-gis-zmvm-mjg
# Compatible con Linux (Debian/Ubuntu/Mint) y macOS

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FONTS_DIR="$REPO_DIR/maps/fonts"

echo "==> Transport-gis-zmvm-mjg — setup de dependencias"
echo "    Repositorio: $REPO_DIR"

# ── Detectar OS ────────────────────────────────────────────────────────────────
OS="$(uname -s)"

install_fonts_linux() {
    echo ""
    echo "── Instalando fuentes (Linux) ──────────────────────────────────────"

    # Open Sans y Roboto desde repositorio del sistema
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y fonts-open-sans fonts-roboto
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y open-sans-fonts google-roboto-fonts
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm ttf-opensans ttf-roboto
    else
        echo "  [!] Gestor de paquetes no reconocido. Instala manualmente:"
        echo "      fonts-open-sans  fonts-roboto"
    fi

    # Fuentes estáticas legacy (Open Sans Extrabold / Condensed) — estas son las
    # que QGIS necesita por nombre de familia exacto
    USER_FONT_DIR="$HOME/.local/share/fonts/transport-gis"
    mkdir -p "$USER_FONT_DIR"
    cp "$FONTS_DIR"/*.ttf "$USER_FONT_DIR/"
    fc-cache -f "$USER_FONT_DIR"
    echo "  ✓ Fuentes legacy copiadas a $USER_FONT_DIR y caché actualizada"
}

install_fonts_macos() {
    echo ""
    echo "── Instalando fuentes (macOS) ──────────────────────────────────────"

    if ! command -v brew &>/dev/null; then
        echo "  [!] Homebrew no encontrado. Instálalo desde https://brew.sh y vuelve a ejecutar."
        exit 1
    fi

    # Open Sans y Roboto via Homebrew (font variable moderno — para el sistema)
    brew install --cask font-open-sans font-roboto 2>/dev/null || true

    # Fuentes estáticas legacy al directorio de usuario (QGIS las necesita por nombre)
    USER_FONT_DIR="$HOME/Library/Fonts"
    cp "$FONTS_DIR"/*.ttf "$USER_FONT_DIR/"
    echo "  ✓ Fuentes legacy copiadas a $USER_FONT_DIR"
    echo "  ✓ Reinicia QGIS para que las reconozca"
}

install_git_lfs() {
    echo ""
    echo "── Verificando Git LFS ─────────────────────────────────────────────"
    if ! command -v git-lfs &>/dev/null; then
        echo "  [!] Git LFS no está instalado."
        if [ "$OS" = "Darwin" ]; then
            brew install git-lfs
        else
            sudo apt-get install -y git-lfs 2>/dev/null || \
            sudo dnf install -y git-lfs 2>/dev/null || \
            echo "  Instala git-lfs manualmente: https://git-lfs.com"
        fi
    fi
    git lfs install --local 2>/dev/null || true
    echo "  ✓ Git LFS activo"
}

pull_lfs_data() {
    echo ""
    echo "── Descargando capas GIS (.gpkg) ───────────────────────────────────"
    cd "$REPO_DIR"
    git lfs pull
    echo "  ✓ Capas en data/processed/ actualizadas"
}

# ── Ejecución ──────────────────────────────────────────────────────────────────
case "$OS" in
    Linux*)  install_fonts_linux  ;;
    Darwin*) install_fonts_macos  ;;
    *)
        echo "  [!] Sistema operativo no reconocido: $OS"
        echo "      Instala manualmente las fuentes de maps/fonts/ y Git LFS."
        exit 1
        ;;
esac

install_git_lfs
pull_lfs_data

echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  Setup completo. Abre QGIS y carga:"
echo "  maps/projects/coloquio-2026-2.qgz"
echo "══════════════════════════════════════════════════════════════════════"
