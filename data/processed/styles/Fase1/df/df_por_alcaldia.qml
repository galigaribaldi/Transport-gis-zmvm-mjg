<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.34.0" styleCategories="Symbology|Labels">
  <!--
    Factor de Desviación por alcaldía — coroplético de 4 clases.
    DF < 1.3  : eficiencia alta  → verde
    DF 1.3-1.6: eficiencia media → amarillo
    DF 1.6-2.0: eficiencia baja  → naranja
    DF > 2.0  : eficiencia muy baja → rojo
  -->
  <renderer-v2 type="graduatedSymbol" attr="DF_promedio" graduatedMethod="GraduatedColor"
               enableorderby="0" forceraster="0" symbollevels="0">
    <ranges>
      <range lower="0.0"  upper="1.3"  symbol="0" label="0 – 1.3   (eficiencia alta)"     render="true" uuid="{df-1}"/>
      <range lower="1.3"  upper="1.6"  symbol="1" label="1.3 – 1.6 (eficiencia media)"    render="true" uuid="{df-2}"/>
      <range lower="1.6"  upper="2.0"  symbol="2" label="1.6 – 2.0 (eficiencia baja)"     render="true" uuid="{df-3}"/>
      <range lower="2.0"  upper="4.5"  symbol="3" label="2.0 – 4.5 (eficiencia muy baja)" render="true" uuid="{df-4}"/>
    </ranges>
    <symbols>
      <!-- Verde — eficiencia alta -->
      <symbol name="0" type="fill" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="26,122,80,255"   type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Amarillo — eficiencia media -->
      <symbol name="1" type="fill" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="244,208,63,255"  type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Naranja — eficiencia baja -->
      <symbol name="2" type="fill" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="230,126,34,255"  type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Rojo — eficiencia muy baja -->
      <symbol name="3" type="fill" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="192,57,43,255"   type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style fontFamily="Sans Serif" fontSize="7" textColor="30,30,30,255"
                  fontWeight="75" fontItalic="0" namedStyle="Bold">
        <text-buffer bufferDraw="1" bufferSize="1" bufferColor="0,0,0,255"
                     bufferOpacity="0.6"/>
      </text-style>
      <text-format/>
      <placement placement="1" dist="0" distUnits="Point" offsetType="0"/>
      <rendering drawLabels="1" minFeatureSize="0" obstacle="1"/>
      <dd_properties>
        <Option type="Map">
          <Option name="name" value="" type="QString"/>
          <Option name="properties"/>
          <Option name="type" value="collection" type="QString"/>
        </Option>
      </dd_properties>
      <!-- Etiqueta: DF redondeado + número de rutas de muestra -->
      <fieldName>round("DF_promedio", 2) || '\n(' || "n_rutas" || ' rutas)'</fieldName>
      <isExpression>1</isExpression>
    </settings>
  </labeling>
</qgis>
