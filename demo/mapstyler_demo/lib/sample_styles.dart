const manualStyleJson = <String, Object?>{
  'name': 'Workspace demo core style',
  'rules': [
    {
      'name': 'landuse areas',
      'filter': [
        '||',
        ['==', 'landuse', 'residential'],
        ['==', 'landuse', 'commercial'],
      ],
      'symbolizers': [
        {
          'kind': 'Fill',
          'color': {
            'name': 'case',
            'args': [
              {
                'case': {
                  'name': 'equalTo',
                  'args': [
                    {'name': 'property', 'args': ['landuse']},
                    'residential',
                  ],
                },
                'value': '#F4A261',
              },
              {
                'case': {
                  'name': 'equalTo',
                  'args': [
                    {'name': 'property', 'args': ['landuse']},
                    'commercial',
                  ],
                },
                'value': '#E76F51',
              },
              '#94D2BD',
            ],
          },
          'fillOpacity': 0.62,
          'outlineColor': '#264653',
          'outlineWidth': 1.2,
        },
      ],
    },
    {
      'name': 'park area',
      'filter': ['==', 'kind', 'park'],
      'symbolizers': [
        {
          'kind': 'Fill',
          'color': '#6BAA75',
          'fillOpacity': 0.45,
          'outlineColor': '#2F5233',
          'outlineWidth': 1.5,
        },
      ],
    },
    {
      'name': 'routes',
      'filter': ['==', 'class', 'motorway'],
      'symbolizers': [
        {
          'kind': 'Line',
          'color': '#0A9396',
          'width': 5.0,
          'dasharray': [10.0, 4.0],
          'cap': 'round',
          'join': 'round',
        },
      ],
    },
    {
      'name': 'poi labels',
      'filter': ['==', 'kind', 'poi'],
      'symbolizers': [
        {
          'kind': 'Mark',
          'wellKnownName': 'diamond',
          'radius': 9.0,
          'color': '#005F73',
          'strokeColor': '#FFFFFF',
          'strokeWidth': 2.0,
        },
        {
          'kind': 'Text',
          'label': {'name': 'property', 'args': ['name']},
          'color': '#102A43',
          'size': 13.0,
          'haloColor': '#FFFFFF',
          'haloWidth': 3.0,
        },
      ],
    },
  ],
};

const sampleMapbox = <String, Object?>{
  'version': 8,
  'name': 'Workspace demo Mapbox style',
  'sources': {
    'workspace': {
      'type': 'vector',
      'url': 'https://example.com/workspace.json',
    },
  },
  'layers': [
    {
      'id': 'water',
      'type': 'fill',
      'source': 'workspace',
      'source-layer': 'surface',
      'filter': ['==', 'class', 'ocean'],
      'paint': {
        'fill-color': '#8ECAE6',
        'fill-opacity': 0.85,
      },
    },
    {
      'id': 'roads',
      'type': 'line',
      'source': 'workspace',
      'source-layer': 'transport',
      'filter': ['==', 'class', 'motorway'],
      'layout': {
        'line-cap': 'round',
        'line-join': 'round',
      },
      'paint': {
        'line-color': '#FB8500',
        'line-width': 3.5,
      },
    },
    {
      'id': 'pois',
      'type': 'circle',
      'source': 'workspace',
      'source-layer': 'poi',
      'paint': {
        'circle-color': '#D62828',
        'circle-radius': 6,
      },
    },
    {
      'id': 'labels',
      'type': 'symbol',
      'source': 'workspace',
      'source-layer': 'poi',
      'layout': {
        'text-field': ['get', 'name'],
        'text-size': 12,
      },
      'paint': {
        'text-color': '#1D3557',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1.5,
      },
    },
  ],
};

const sampleQml = '''
<qgis version="3.28.0" hasScaleBasedVisibilityFlag="1"
      maxScale="1000" minScale="100000">
  <renderer-v2 type="categorizedSymbol" attr="landuse">
    <categories>
      <category value="residential" symbol="0" label="Residential" render="true"/>
      <category value="commercial" symbol="1" label="Commercial" render="true"/>
    </categories>
    <symbols>
      <symbol type="fill" name="0" alpha="1">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="248,196,113,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="86,101,115,255" type="QString"/>
            <Option name="outline_width" value="0.7" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="fill" name="1" alpha="0.9">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="214,48,49,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="45,52,54,255" type="QString"/>
            <Option name="outline_width" value="0.7" type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
</qgis>
''';

const sampleSld = '''
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>Workspace layer</Name>
    <UserStyle>
      <Name>Workspace demo</Name>
      <FeatureTypeStyle>
        <Rule>
          <Name>Residential</Name>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>landuse</ogc:PropertyName>
              <ogc:Literal>residential</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#F6BD60</CssParameter>
              <CssParameter name="fill-opacity">0.6</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#6D597A</CssParameter>
              <CssParameter name="stroke-width">1.2</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
        <Rule>
          <Name>Roads</Name>
          <LineSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#355070</CssParameter>
              <CssParameter name="stroke-width">2.5</CssParameter>
            </Stroke>
          </LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';
