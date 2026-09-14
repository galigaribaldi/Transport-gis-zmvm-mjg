"""
utils — capa de integración Transport-gis ↔ VFTModel / Apimetro

Uso típico:
    from utils.clients.vft_client import VFTClient
    from utils.exporters.geo_exporter import GeoExporter

    client = VFTClient()
    fc = client.fetch_detour_routes(sample_size=200)
    gdf = GeoExporter.from_geolayer(fc)
    GeoExporter.save(gdf, "df_puntos")
"""
