import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

void main() {
  runApp(const FlutterMapStylerExampleApp());
}

class FlutterMapStylerExampleApp extends StatelessWidget {
  const FlutterMapStylerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_mapstyler example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
      ),
      home: const ExampleMapPage(),
    );
  }
}

class ExampleMapPage extends StatelessWidget {
  const ExampleMapPage({super.key});

  static final Style _style = Style(
    name: 'Example style',
    rules: [
      Rule(
        name: 'park polygon',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('kind'),
          value: LiteralExpression('park'),
        ),
        symbolizers: const [
          FillSymbolizer(
            color: LiteralExpression('#7FB069'),
            fillOpacity: LiteralExpression(0.45),
            outlineColor: LiteralExpression('#3F6F38'),
            outlineWidth: LiteralExpression(2.0),
          ),
        ],
      ),
      Rule(
        name: 'route line',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('kind'),
          value: LiteralExpression('route'),
        ),
        symbolizers: const [
          LineSymbolizer(
            color: LiteralExpression('#D94841'),
            width: LiteralExpression(4.0),
            dasharray: [8, 4],
            cap: 'round',
            join: 'round',
          ),
        ],
      ),
      Rule(
        name: 'landmark marker',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('kind'),
          value: LiteralExpression('landmark'),
        ),
        symbolizers: const [
          MarkSymbolizer(
            wellKnownName: 'diamond',
            radius: LiteralExpression(9.0),
            color: LiteralExpression('#1D4ED8'),
            strokeColor: LiteralExpression('#FFFFFF'),
            strokeWidth: LiteralExpression(2.0),
          ),
          TextSymbolizer(
            label: FunctionExpression(PropertyGet('name')),
            color: LiteralExpression('#111827'),
            size: LiteralExpression(13.0),
            haloColor: LiteralExpression('#FFFFFF'),
            haloWidth: LiteralExpression(3.0),
          ),
        ],
      ),
    ],
  );

  static const StyledFeatureCollection _features = StyledFeatureCollection([
    StyledFeature(
      id: 'park-1',
      geometry: PolygonGeometry([
        [
          (13.3950, 52.5180),
          (13.4080, 52.5180),
          (13.4080, 52.5255),
          (13.3950, 52.5255),
          (13.3950, 52.5180),
        ],
      ]),
      properties: {
        'kind': 'park',
        'name': 'Sample Park',
      },
    ),
    StyledFeature(
      id: 'route-1',
      geometry: LineStringGeometry([
        (13.3890, 52.5160),
        (13.3990, 52.5200),
        (13.4095, 52.5235),
        (13.4190, 52.5270),
      ]),
      properties: {
        'kind': 'route',
        'name': 'Sample Route',
      },
    ),
    StyledFeature(
      id: 'landmark-1',
      geometry: PointGeometry(13.4045, 52.5215),
      properties: {
        'kind': 'landmark',
        'name': 'Center Point',
      },
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final renderer = const StyleRenderer();

    return Scaffold(
      appBar: AppBar(title: const Text('flutter_mapstyler example')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(52.5208, 13.4049),
          initialZoom: 15,
          onTap: (_, __) => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.example.flutter_mapstyler_example',
          ),
          ...renderer.renderStyle(
            style: _style,
            features: _features,
            onFeatureTap: (feature) {
              final name = feature.properties['name'] ?? feature.id ?? 'unknown';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped $name')),
              );
            },
          ),
        ],
      ),
    );
  }
}
