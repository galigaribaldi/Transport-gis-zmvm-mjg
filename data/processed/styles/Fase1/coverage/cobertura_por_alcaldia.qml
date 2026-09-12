<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.34.0" styleCategories="Symbology">
  <renderer-v2 type="graduatedSymbol" attr="cobertura_pct" graduatedMethod="GraduatedColor"
               enableorderby="0" forceraster="0" symbollevels="0">
    <ranges>
      <range lower="0.000000"  upper="51.120000" symbol="0" label="0 – 51%  (cobertura baja)"   render="true" uuid="{cpa-1}"/>
      <range lower="51.120000" upper="72.030000" symbol="1" label="51 – 72%  (cobertura media)"  render="true" uuid="{cpa-2}"/>
      <range lower="72.030000" upper="93.660000" symbol="2" label="72 – 94%  (cobertura alta)"   render="true" uuid="{cpa-3}"/>
      <range lower="93.660000" upper="99.620000" symbol="3" label="94 – 100% (cobertura muy alta)" render="true" uuid="{cpa-4}"/>
      <range lower="99.620000" upper="100.00000" symbol="4" label="100%       (cobertura total)"  render="true" uuid="{cpa-5}"/>
    </ranges>
    <symbols>
      <!-- Clase 1 — verde muy claro -->
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
            <Option name="color"         value="237,248,233,255" type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Clase 2 — verde claro -->
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
            <Option name="color"         value="186,228,179,255" type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Clase 3 — verde medio -->
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
            <Option name="color"         value="116,196,118,255" type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Clase 4 — verde oscuro -->
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
            <Option name="color"         value="49,163,84,255"   type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Clase 5 — verde muy oscuro -->
      <symbol name="4" type="fill" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="0,109,44,255"    type="QString"/>
            <Option name="style"         value="solid"           type="QString"/>
            <Option name="outline_style" value="solid"           type="QString"/>
            <Option name="outline_color" value="80,80,80,255"    type="QString"/>
            <Option name="outline_width" value="0.26"            type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
</qgis>
