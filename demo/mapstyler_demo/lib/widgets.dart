import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

import 'demo_data.dart';

class OverviewPanel extends StatelessWidget {
  const OverviewPanel({
    super.key,
    required this.data,
    required this.selectedKind,
    required this.onStyleSelected,
  });

  final DemoData data;
  final DemoStyleKind selectedKind;
  final ValueChanged<DemoStyleKind> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    final selectedStyle = data.styles[selectedKind]!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapstyler Workspace Demo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Eine kleine Linux-Desktop-App, die alle Packages im '
                  'Repository einmal direkt verwendet und den resultierenden '
                  'Style mit flutter_mapstyler rendert.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF415A60),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<DemoStyleKind>(
                  showSelectedIcon: false,
                  segments: DemoStyleKind.values
                      .map(
                        (kind) => ButtonSegment<DemoStyleKind>(
                          value: kind,
                          label: Text(shortLabel(kind)),
                        ),
                      )
                      .toList(growable: false),
                  selected: {selectedKind},
                  onSelectionChanged: (selection) {
                    onStyleSelected(selection.single);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  selectedStyle.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                for (final note in selectedStyle.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      note,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF51676D),
                          ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < data.packages.length; index++) ...[
            PackageCard(
              card: data.packages[index],
              accent: packageAccent(index),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.styleSummary,
    required this.features,
    required this.tileProvider,
  });

  final StyleSummary styleSummary;
  final StyledFeatureCollection features;
  final TileProvider tileProvider;

  @override
  Widget build(BuildContext context) {
    const renderer = StyleRenderer();
    final fittedBounds = featureBounds(features);

    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Live-Vorschau',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              InfoPill('Regeln ${styleSummary.style.rules.length}'),
              InfoPill('Features ${features.features.length}'),
              InfoPill(styleSummary.title),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE6F2F2),
                          Color(0xFFF3EFE4),
                        ],
                      ),
                    ),
                  ),
                  const CustomPaint(
                    painter: PreviewBackdropPainter(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCameraFit: CameraFit.bounds(
                              bounds: fittedBounds,
                              padding: const EdgeInsets.all(84),
                              minZoom: 11.2,
                              maxZoom: 16.8,
                            ),
                            minZoom: 1,
                            maxZoom: 22,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              tileProvider: tileProvider,
                              maxNativeZoom: 19,
                              keepBuffer: 5,
                              panBuffer: 3,
                            ),
                            ...renderer.renderStyle(
                              style: styleSummary.style,
                              features: features,
                              onFeatureTap: (feature) {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final label = feature.properties['name'] ??
                                    feature.properties['landuse'] ??
                                    feature.properties['class'] ??
                                    feature.id ??
                                    'Feature';
                                messenger
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                        content: Text('Feature: $label')),
                                  );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.card,
    required this.accent,
  });

  final PackageCardData card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E2C34),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF203238),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.caption,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF536A70),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                for (final line in card.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 8),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF31464B),
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3EBED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2A30),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B7285),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

String shortLabel(DemoStyleKind kind) {
  return switch (kind) {
    DemoStyleKind.manual => 'Core',
    DemoStyleKind.mapbox => 'Mapbox',
    DemoStyleKind.qml => 'QML',
    DemoStyleKind.sld => 'SLD',
  };
}

Color packageAccent(int index) {
  const palette = [
    Color(0xFF0B7285),
    Color(0xFFE76F51),
    Color(0xFF5C7CFA),
    Color(0xFF6BAA75),
    Color(0xFFC77DFF),
    Color(0xFFF4A261),
    Color(0xFF1D3557),
  ];
  return palette[index % palette.length];
}

LatLngBounds featureBounds(StyledFeatureCollection collection) {
  final points = <LatLng>[];

  for (final feature in collection.features) {
    switch (feature.geometry) {
      case PointGeometry(:final x, :final y):
        points.add(LatLng(y, x));
      case LineStringGeometry(:final coordinates):
        points.addAll(
          coordinates
              .map((coordinate) => LatLng(coordinate.$2, coordinate.$1)),
        );
      case PolygonGeometry(:final rings):
        for (final ring in rings) {
          points.addAll(
            ring.map((coordinate) => LatLng(coordinate.$2, coordinate.$1)),
          );
        }
      case EnvelopeGeometry(
          :final minX,
          :final minY,
          :final maxX,
          :final maxY,
        ):
        points.addAll([
          LatLng(minY, minX),
          LatLng(minY, maxX),
          LatLng(maxY, maxX),
          LatLng(maxY, minX),
        ]);
    }
  }

  if (points.isEmpty) {
    return LatLngBounds(
      const LatLng(52.519, 13.399),
      const LatLng(52.525, 13.409),
    );
  }

  return LatLngBounds.fromPoints(points);
}

class PreviewBackdropPainter extends CustomPainter {
  const PreviewBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFF3B5B63).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = const Color(0xFF0B7285).withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    const spacing = 44.0;

    for (double x = 0; x <= size.width; x += spacing) {
      final paint = (x / spacing).round() % 4 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      final paint = (y / spacing).round() % 4 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final washPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x22FFFFFF),
          Color(0x00FFFFFF),
          Color(0x26FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, washPaint);

    final tealHaloPaint = Paint()
      ..color = const Color(0xFF0B7285).withValues(alpha: 0.08);
    final coralHaloPaint = Paint()
      ..color = const Color(0xFFE76F51).withValues(alpha: 0.07);

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.2),
      size.shortestSide * 0.14,
      tealHaloPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.74),
      size.shortestSide * 0.1,
      coralHaloPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
