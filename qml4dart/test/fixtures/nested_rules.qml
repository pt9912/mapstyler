<qgis version="3.28.0-Firenze">
  <renderer-v2 type="RuleRenderer" forceraster="0" symbollevels="0" enableorderby="0">
    <rules key="renderer_rules">
      <rule key="parent_1" label="Category A" filter="type = 'A'">
        <rule key="child_1a" symbol="0" label="Subtype 1" filter="subtype = 1"/>
        <rule key="child_1b" symbol="1" label="Subtype 2" filter="subtype = 2"/>
      </rule>
      <rule key="parent_2" symbol="2" label="Category B" filter="type = 'B'"/>
    </rules>
    <symbols>
      <symbol type="marker" name="0" alpha="1" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="255,0,0,255" type="QString"/>
            <Option name="name" value="circle" type="QString"/>
            <Option name="size" value="6" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="marker" name="1" alpha="1" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="0,255,0,255" type="QString"/>
            <Option name="name" value="circle" type="QString"/>
            <Option name="size" value="6" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="marker" name="2" alpha="1" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="0,0,255,255" type="QString"/>
            <Option name="name" value="circle" type="QString"/>
            <Option name="size" value="6" type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
</qgis>
