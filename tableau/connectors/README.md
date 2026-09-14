# tableau/connectors/

Archivos **Web Data Connector (WDC)** para conectar Tableau Desktop a las APIs tabulares
del proyecto. Formato HTML + JavaScript — git-tracked, sin datos.

Los datos **espaciales** (MultiLineString, MultiPolygon) no pasan por WDC sino por el
GeoProxy en `../geo_proxy/`. Ver su README para esos endpoints.

---

## Archivos

### `apimetro_wdc.html` — Apimetro (localhost:8080) ✓ operativo

Conecta a los endpoints analíticos y de estaciones de Apimetro.

| Tabla Tableau | Endpoint | Registros |
|---------------|----------|-----------|
| `afluencia_linea` | `GET /movilidad/analitico/afluencia-linea` | 1,197 |
| `afluencia_estacion` | `GET /movilidad/analitico/afluencia-estacion` | 38,219 |
| `estaciones` | `GET /movilidad/mapas/geojsonEstacion` (solo properties + lat/lon) | todos los sistemas |

Apimetro tiene CORS habilitado (`AllowOrigins: ["*"]`) — funciona sin configuración extra.

### `vftmodel_wdc.html` — VFTModel (localhost:8000) — pendiente

Conectará a los endpoints GeoLayer de VFTModel.
**Blocker**: VFTModel necesita `CORSMiddleware` antes de implementarlo.

Fix en `VFTModel/src/api/main.py`:
```python
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["GET"], allow_headers=["*"])
```

---

## Relaciones entre tablas (para el modelo de datos de Tableau)

```
afluencia_estacion ──[ linea_id ]──────────► afluencia_linea
afluencia_estacion ──[ nombre_estacion ]───► estaciones
afluencia_linea    ──[ linea_id ]──────────► estaciones
```

---

## Cómo conectar en Tableau Desktop

```
Tableau Desktop
  → Conectar → Más... → Conector de datos web
  → URL: file:///ruta/absoluta/al/repo/tableau/connectors/apimetro_wdc.html
  → [Formulario] Confirmar URL base y seleccionar tablas
  → Obtener datos
```

En macOS la ruta típica es:
```
file:///Users/hcabrera/Documents/Personal_Documents/Transport-gis-zmvm-mjg/tableau/connectors/apimetro_wdc.html
```

---

## Resumen de tipos de conexión por dato

| Dato | Geometría | Conector | Estado |
|------|-----------|----------|--------|
| Afluencia por línea | — | WDC `apimetro_wdc.html` | ✓ |
| Afluencia por estación | — | WDC `apimetro_wdc.html` | ✓ |
| Estaciones (lat/lon) | Point | WDC `apimetro_wdc.html` | ✓ |
| Líneas de transporte | MultiLineString | GeoProxy `:5050/apimetro/lineas.geojson` | ✓ |
| Polígonos territoriales | MultiPolygon | GeoProxy `:5050/apimetro/poligonos.geojson` | ✓ |
| Indicadores VFTModel | — | WDC `vftmodel_wdc.html` | pendiente |
| Capas GeoLayer VFTModel | Point/Polygon | GeoProxy `:5050/vftmodel/…` | pendiente CORS |
