import 'dart:convert';

import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:mapbox4dart/mapbox4dart.dart';
import 'package:mapstyler_mapbox_adapter/mapstyler_mapbox_adapter.dart';
import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:qml4dart/qml4dart.dart';

import 'sample_geodata.dart';
import 'sample_styles.dart';

enum DemoStyleKind {
  manual('mapstyler_style'),
  mapbox('mapstyler_mapbox_adapter'),
  qml('mapstyler_qml_adapter'),
  sld('mapstyler_sld_adapter');

  const DemoStyleKind(this.label);
  final String label;
}

class DemoData {
  const DemoData({
    required this.features,
    required this.packages,
    required this.styles,
  });

  final StyledFeatureCollection features;
  final List<PackageCardData> packages;
  final Map<DemoStyleKind, StyleSummary> styles;
}

class PackageCardData {
  const PackageCardData({
    required this.name,
    required this.caption,
    required this.lines,
  });

  final String name;
  final String caption;
  final List<String> lines;
}

class StyleSummary {
  const StyleSummary({
    required this.title,
    required this.style,
    required this.notes,
  });

  final String title;
  final Style style;
  final List<String> notes;
}

Future<DemoData> loadDemoData({
  FeatureSource featureSource = FeatureSource.hardcoded,
}) async {
  final manualStyle = Style.fromJson(manualStyleJson);
  final manualJson = manualStyle.toJsonString();

  const mapboxCodec = MapboxStyleCodec();
  final mapboxRead = mapboxCodec.readString(jsonEncode(sampleMapbox));
  final mapboxDocument = switch (mapboxRead) {
    ReadMapboxSuccess(:final output) => output,
    ReadMapboxFailure(:final errors) =>
      throw StateError('mapbox4dart fehlgeschlagen: ${errors.join(', ')}'),
  };
  final mapboxWrite = mapboxCodec.writeString(mapboxDocument);
  final mapboxWriteLength = switch (mapboxWrite) {
    WriteMapboxSuccess(:final output) => output.length,
    WriteMapboxFailure(:final errors) =>
      throw StateError('Mapbox-Write fehlgeschlagen: ${errors.join(', ')}'),
  };
  final normalizedColor = normalizeColor('steelblue');

  const mapboxAdapter = MapboxStyleAdapter();
  final mapboxAdapterRead =
      await mapboxAdapter.readStyle(jsonEncode(sampleMapbox));
  final mapboxStyle = switch (mapboxAdapterRead) {
    ReadStyleSuccess(:final output) => output,
    ReadStyleFailure(:final errors) =>
      throw StateError('Mapbox-Adapter fehlgeschlagen: ${errors.join(', ')}'),
  };

  const qmlCodec = Qml4DartCodec();
  final qmlRead = qmlCodec.parseString(sampleQml);
  final qmlDocument = switch (qmlRead) {
    ReadQmlSuccess(:final document) => document,
    ReadQmlFailure(:final message) =>
      throw StateError('qml4dart fehlgeschlagen: $message'),
  };
  final qmlWrite = qmlCodec.encodeString(qmlDocument);
  final qmlWriteLength = switch (qmlWrite) {
    WriteQmlSuccess(:final xml) => xml.length,
    WriteQmlFailure(:final message) =>
      throw StateError('QML-Write fehlgeschlagen: $message'),
  };

  const qmlAdapter = QmlStyleParser();
  final qmlAdapterRead = await qmlAdapter.readStyle(sampleQml);
  final qmlStyle = switch (qmlAdapterRead) {
    ReadStyleSuccess(:final output) => output,
    ReadStyleFailure(:final errors) =>
      throw StateError('QML-Adapter fehlgeschlagen: ${errors.join(', ')}'),
  };
  final qmlAdapterWrite = await qmlAdapter.writeStyle(manualStyle);
  final qmlAdapterWriteLength = switch (qmlAdapterWrite) {
    WriteStyleSuccess<String>(:final output) => output.length,
    WriteStyleFailure<String>(:final errors) =>
      throw StateError(
          'QML-Adapter-Write fehlgeschlagen: ${errors.join(', ')}'),
  };

  const sldAdapter = SldStyleParser();
  final sldRead = await sldAdapter.readStyle(sampleSld);
  final sldStyle = switch (sldRead) {
    ReadStyleSuccess(:final output) => output,
    ReadStyleFailure(:final errors) =>
      throw StateError('SLD-Adapter fehlgeschlagen: ${errors.join(', ')}'),
  };

  final features = loadFeatures(featureSource);

  return DemoData(
    features: features,
    packages: [
      PackageCardData(
        name: 'mapstyler_style',
        caption: 'Core-Style-Modell aus GeoStyler-kompatiblem JSON.',
        lines: [
          'Style.fromJson(...) erzeugt ${manualStyle.rules.length} Regeln.',
          'Roundtrip via toJsonString(): ${manualJson.length} Zeichen.',
        ],
      ),
      PackageCardData(
        name: 'mapbox4dart',
        caption: 'Typisierter Mapbox-GL-Style-Codec.',
        lines: [
          'Layers: ${mapboxDocument.layers.length}, Sources: ${mapboxDocument.sources.length}.',
          'normalizeColor("steelblue") -> ${normalizedColor?.hex} @ ${normalizedColor?.opacity}.',
          'Re-encoded JSON: $mapboxWriteLength Zeichen.',
        ],
      ),
      PackageCardData(
        name: 'mapstyler_mapbox_adapter',
        caption: 'Mapbox-JSON-zu-Style-Konvertierung.',
        lines: [
          'Konvertierter Style: ${mapboxStyle.rules.length} Regeln.',
          'Nutzt denselben Feature-Bestand in der Vorschau wie die anderen Formate.',
        ],
      ),
      PackageCardData(
        name: 'qml4dart',
        caption: 'Typisierter QGIS-QML-Codec.',
        lines: [
          'Renderer: ${qmlDocument.renderer.type.toQmlString()}.',
          'Symbole: ${qmlDocument.renderer.symbols.length}, encoded XML: $qmlWriteLength Zeichen.',
        ],
      ),
      PackageCardData(
        name: 'mapstyler_qml_adapter',
        caption: 'Bidirektionale QML/Style-Konvertierung.',
        lines: [
          'Gelesener Style: ${qmlStyle.rules.length} Regeln.',
          'Schreibprobe aus Core-Style: $qmlAdapterWriteLength Zeichen QML.',
        ],
      ),
      PackageCardData(
        name: 'mapstyler_sld_adapter',
        caption: 'SLD-XML-zu-Style-Konvertierung.',
        lines: [
          'Gelesener Style: ${sldStyle.rules.length} Regeln.',
          'Deckt Polygon- und Linien-Symbolizer aus dem SLD-Beispiel ab.',
        ],
      ),
      PackageCardData(
        name: 'flutter_mapstyler',
        caption: 'Renderer von Style + Features zu flutter_map-Layern.',
        lines: [
          'Rendert ${features.features.length} Features auf der rechten Seite.',
          'Tap auf eine Geometrie zeigt die ausgewerteten Feature-Daten an.',
        ],
      ),
    ],
    styles: {
      DemoStyleKind.manual: StyleSummary(
        title: 'Core Style',
        style: manualStyle,
        notes: [
          'Direkt aus mapstyler_style aufgebaut.',
          'Nutzt Filter, Property-Expressions und ein kleines JSON-Roundtrip.',
        ],
      ),
      DemoStyleKind.mapbox: StyleSummary(
        title: 'Mapbox Style',
        style: mapboxStyle,
        notes: [
          'Aus Mapbox GL JSON gelesen und zu mapstyler_style konvertiert.',
          'Zeigt Fill-, Line-, Circle/Mark- und Text-Layer aus einem einzigen Dokument.',
        ],
      ),
      DemoStyleKind.qml: StyleSummary(
        title: 'QML Style',
        style: qmlStyle,
        notes: [
          'Aus einem categorized QGIS-QML gelesen.',
          'Die beiden Landuse-Polygone werden darüber unterschiedlich eingefärbt.',
        ],
      ),
      DemoStyleKind.sld: StyleSummary(
        title: 'SLD Style',
        style: sldStyle,
        notes: [
          'Aus SLD XML gelesen.',
          'Das Beispiel kombiniert einen gefilterten Polygon-Rule mit einer Straßenlinie.',
        ],
      ),
    },
  );
}

StyledFeatureCollection buildDemoFeatures() {
  return const StyledFeatureCollection([
    StyledFeature(
      id: 'water-1',
      geometry: PolygonGeometry([
        [
          (13.3930, 52.5198),
          (13.3994, 52.5198),
          (13.3994, 52.5248),
          (13.3930, 52.5248),
          (13.3930, 52.5198),
        ],
      ]),
      properties: {
        'class': 'ocean',
        'name': 'Canal Basin',
      },
    ),
    StyledFeature(
      id: 'residential-1',
      geometry: PolygonGeometry([
        [
          (13.3998, 52.5177),
          (13.4062, 52.5177),
          (13.4062, 52.5225),
          (13.3998, 52.5225),
          (13.3998, 52.5177),
        ],
      ]),
      properties: {
        'landuse': 'residential',
        'name': 'Residential Quarter',
      },
    ),
    StyledFeature(
      id: 'commercial-1',
      geometry: PolygonGeometry([
        [
          (13.4070, 52.5195),
          (13.4138, 52.5195),
          (13.4138, 52.5246),
          (13.4070, 52.5246),
          (13.4070, 52.5195),
        ],
      ]),
      properties: {
        'landuse': 'commercial',
        'name': 'Market Blocks',
      },
    ),
    StyledFeature(
      id: 'park-1',
      geometry: PolygonGeometry([
        [
          (13.3945, 52.5252),
          (13.4018, 52.5252),
          (13.4018, 52.5294),
          (13.3945, 52.5294),
          (13.3945, 52.5252),
        ],
      ]),
      properties: {
        'kind': 'park',
        'name': 'Pocket Park',
      },
    ),
    StyledFeature(
      id: 'road-1',
      geometry: LineStringGeometry([
        (13.3920, 52.5165),
        (13.3985, 52.5190),
        (13.4058, 52.5215),
        (13.4128, 52.5258),
        (13.4180, 52.5290),
      ]),
      properties: {
        'class': 'motorway',
        'kind': 'route',
        'name': 'Ring Route',
      },
    ),
    StyledFeature(
      id: 'poi-1',
      geometry: PointGeometry(13.4046, 52.5231),
      properties: {
        'class': 'cafe',
        'kind': 'poi',
        'name': 'Central Cafe',
      },
    ),
  ]);
}
