<?xml version='1.0' encoding='utf-8'?>
<preferences>

  <!--
    Paleta Verde Esmeralda UNAM — Tesis Transportes Anillares ZMVM
    Homologada con PlantillaBase_VerdeEsmeralda_Vertical.qpt (QGIS)
    Uso: copiar este archivo a ~/Documents/My Tableau Repository/Preferences.tps
         o fusionar el bloque <color-palette> con el Preferences.tps existente.
  -->

  <!-- ── Paleta institucional principal ──────────────────────────────────── -->
  <color-palette name="Verde Esmeralda UNAM" type="regular">
    <!-- Primarios institucionales -->
    <color>#008250</color>  <!-- Verde Esmeralda — header, acentos principales -->
    <color>#FFBA08</color>  <!-- Dorado UNAM — franja de acento, highlights -->
    <color>#191919</color>  <!-- Casi negro — texto principal, bordes -->
    <color>#FFFFFF</color>  <!-- Blanco — texto sobre verde, fondo base -->
    <!-- Grises de sistema -->
    <color>#F0F2F5</color>  <!-- Gris claro — fondo de paneles (simbología, datos) -->
    <color>#F5F6F8</color>  <!-- Gris muy claro — footer background -->
    <color>#B4B9C3</color>  <!-- Gris medio — separadores, bordes sutiles -->
    <!-- Complementarios de tesis -->
    <color>#00613C</color>  <!-- Verde oscuro — variante profunda del esmeralda -->
    <color>#E8F5EE</color>  <!-- Verde muy claro — fondos de énfasis suave -->
    <color>#CC8800</color>  <!-- Dorado oscuro — variante del acento dorado -->
  </color-palette>

  <!-- ── Paleta secuencial (para mapas de calor y escalas continuas) ──────── -->
  <color-palette name="Esmeralda Secuencial" type="ordered-sequential">
    <color>#E8F5EE</color>  <!-- más claro -->
    <color>#B3DEC4</color>
    <color>#7EC49A</color>
    <color>#49A970</color>
    <color>#1A8F4D</color>
    <color>#008250</color>  <!-- Verde Esmeralda base -->
    <color>#00613C</color>  <!-- más oscuro -->
  </color-palette>

  <!-- ── Paleta divergente (para comparativas positivo/negativo) ──────────── -->
  <color-palette name="Esmeralda Divergente" type="ordered-diverging">
    <color>#CC8800</color>  <!-- Dorado oscuro — extremo negativo/bajo -->
    <color>#FFBA08</color>  <!-- Dorado UNAM -->
    <color>#FFF8E1</color>  <!-- Centro neutro -->
    <color>#7EC49A</color>  <!-- Verde medio -->
    <color>#008250</color>  <!-- Verde Esmeralda — extremo positivo/alto -->
  </color-palette>

</preferences>
