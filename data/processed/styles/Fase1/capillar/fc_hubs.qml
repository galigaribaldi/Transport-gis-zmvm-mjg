<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.34.0" styleCategories="Symbology|Labels">
  <!-- Top-20 macro-hubs — anillo hueco prominente con etiqueta de nombre -->
  <renderer-v2 type="singleSymbol" enableorderby="0" forceraster="0" symbollevels="0">
    <symbols>
      <symbol name="0" type="marker" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="0,0,0,0"         type="QString"/>
            <Option name="name"          value="circle"          type="QString"/>
            <Option name="outline_color" value="26,26,46,255"    type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_width" value="1.2"             type="QString"/>
            <Option name="size"          value="12"              type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
    <rotation/>
    <sizescale/>
  </renderer-v2>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style fontFamily="Sans Serif" fontSize="7" textColor="26,26,46,255"
                  fontWeight="75" fontItalic="0" namedStyle="Bold">
        <text-buffer bufferDraw="1" bufferSize="1" bufferColor="255,255,255,255"
                     bufferOpacity="0.7"/>
      </text-style>
      <text-format/>
      <placement placement="1" dist="2" distUnits="Point" offsetType="0"/>
      <rendering drawLabels="1" minFeatureSize="0" obstacle="1"/>
      <!-- Expresión: recorta el nombre al primer guion para no saturar -->
      <dd_properties>
        <Option type="Map">
          <Option name="name" value="" type="QString"/>
          <Option name="properties">
            <Option type="Map">
              <Option name="LabelRotation">
                <Option type="Map">
                  <Option name="active" value="false" type="bool"/>
                </Option>
              </Option>
            </Option>
          </Option>
          <Option name="type" value="collection" type="QString"/>
        </Option>
      </dd_properties>
      <fieldName>regexp_replace("hub_nombre", ' - .*', '')</fieldName>
      <isExpression>1</isExpression>
    </settings>
  </labeling>
</qgis>
