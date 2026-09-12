<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.34.0" styleCategories="Symbology">
  <!--
    Fuerza Capilar — nodos de la red clasificados por fc_total.
    Reglas por umbral descendente para que los hubs más fuertes
    dominen visualmente.
  -->
  <renderer-v2 type="RuleRenderer" enableorderby="0" forceraster="0" symbollevels="0">
    <rules key="{fcp-root}">
      <rule symbol="0" label="FC &gt; 20  (hubs principales)"
            filter="&quot;fc_total&quot; &gt; 20"
            key="{fcp-1}"/>
      <rule symbol="1" label="FC 10 – 20  (nodos secundarios)"
            filter="&quot;fc_total&quot; &gt;= 10 AND &quot;fc_total&quot; &lt;= 20"
            key="{fcp-2}"/>
      <rule symbol="2" label="FC 6 – 10  (nodos intermedios)"
            filter="&quot;fc_total&quot; &gt;= 6 AND &quot;fc_total&quot; &lt; 10"
            key="{fcp-3}"/>
      <rule symbol="3" label="FC 3 – 6   (nodos menores)"
            filter="&quot;fc_total&quot; &gt;= 3 AND &quot;fc_total&quot; &lt; 6"
            key="{fcp-4}"/>
    </rules>
    <symbols>
      <!-- Hubs principales — rojo, 10 pt -->
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
            <Option name="color"         value="192,57,43,255"   type="QString"/>
            <Option name="name"          value="circle"          type="QString"/>
            <Option name="outline_style" value="no"              type="QString"/>
            <Option name="size"          value="10"              type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Nodos secundarios — naranja, 6 pt -->
      <symbol name="1" type="marker" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="230,126,34,255"  type="QString"/>
            <Option name="name"          value="circle"          type="QString"/>
            <Option name="outline_style" value="no"              type="QString"/>
            <Option name="size"          value="6"               type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Nodos intermedios — gris, 2.5 pt -->
      <symbol name="2" type="marker" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="127,140,141,255" type="QString"/>
            <Option name="name"          value="circle"          type="QString"/>
            <Option name="outline_style" value="no"              type="QString"/>
            <Option name="size"          value="2.5"             type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
      <!-- Nodos menores — gris claro, 1 pt -->
      <symbol name="3" type="marker" alpha="1" clip_to_extent="1" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" pass="0" locked="0">
          <Option type="Map">
            <Option name="color"         value="189,195,199,255" type="QString"/>
            <Option name="name"          value="circle"          type="QString"/>
            <Option name="outline_style" value="no"              type="QString"/>
            <Option name="size"          value="1"               type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
</qgis>
