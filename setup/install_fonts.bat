@echo off
REM ============================================================
REM  Transport-gis-zmvm-mjg — setup de dependencias (Windows)
REM  Ejecutar como Administrador para instalar fuentes al sistema
REM ============================================================

setlocal EnableDelayedExpansion

echo.
echo =^> Transport-gis-zmvm-mjg -- setup de dependencias (Windows)

REM Directorio del repo (sube un nivel desde setup\)
set "REPO_DIR=%~dp0.."
set "FONTS_SRC=%REPO_DIR%\maps\fonts"
set "FONTS_DEST=%WINDIR%\Fonts"

echo    Repositorio: %REPO_DIR%

REM ── Verificar Git LFS ────────────────────────────────────────────────────
echo.
echo -- Verificando Git LFS -------------------------------------------------
git lfs version >nul 2>&1
if %errorlevel% neq 0 (
    echo   [!] Git LFS no encontrado.
    echo       Descargalo desde: https://git-lfs.com
    echo       O con winget:  winget install Git.LFS
    pause
    exit /b 1
)
echo   OK Git LFS disponible

REM ── Instalar fuentes ─────────────────────────────────────────────────────
echo.
echo -- Instalando fuentes --------------------------------------------------

REM Verificar si se ejecuta como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo   [!] No tienes permisos de administrador.
    echo       Haz clic derecho en este .bat y elige "Ejecutar como administrador".
    pause
    exit /b 1
)

REM Instalar los TTFs estáticos desde maps/fonts/
for %%F in ("%FONTS_SRC%\*.ttf") do (
    echo   Instalando: %%~nxF
    copy /Y "%%F" "%FONTS_DEST%\" >nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" ^
        /v "%%~nF (TrueType)" /t REG_SZ /d "%%~nxF" /f >nul 2>&1
)
echo   OK Fuentes instaladas en %FONTS_DEST%

REM ── Descargar capas GIS (Git LFS) ────────────────────────────────────────
echo.
echo -- Descargando capas GIS (.gpkg) ---------------------------------------
cd /d "%REPO_DIR%"
git lfs install --local
git lfs pull
echo   OK Capas en data\processed\ actualizadas

REM ── Fin ──────────────────────────────────────────────────────────────────
echo.
echo ================================================================
echo   Setup completo. Abre QGIS y carga:
echo   maps\projects\coloquio-2026-2.qgz
echo ================================================================
echo.
pause
