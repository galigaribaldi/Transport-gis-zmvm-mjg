<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.34.0" styleCategories="Symbology">
  <!--
    Muestra de 100 rutas del Factor de Desviación — puntos de origen/destino.
    Tamaño mínimo para no competir con el coroplético de df_por_alcaldia.
  -->
  <renderer-v2 type="singleSymbol" enableorderby="0" forceraster="0" symbollevels="0">
    <symbols>
      <symbol name="0" type="marker" alpha="0.7" clip_to_extent="1" force_rhr="0">
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
            <Option name="size"          value="1"               type="QString"/>
            <Option name="size_unit"     value="Point"           type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
    <rotation/>
    <sizescale/>
  </renderer-v2>
</qgis>
