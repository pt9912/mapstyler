import 'dart:io';

import 'package:flutter/material.dart';

import 'caching_tile_provider.dart';
import 'demo_data.dart';
import 'sample_geodata.dart';
import 'style_editor.dart';
import 'widgets.dart';

void main() {
  runApp(const MapstylerDemoApp());
}

class MapstylerDemoApp extends StatelessWidget {
  const MapstylerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapstyler Workspace Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B7285),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  late final CachingTileProvider _tileProvider = CachingTileProvider(
    cacheDir: Directory('${Directory.systemTemp.path}/mapstyler_tiles'),
  );
  Future<DemoData>? _demoFuture;
  FeatureSource _featureSource = FeatureSource.hardcoded;
  DemoStyleKind _selectedKind = DemoStyleKind.manual;
  bool _showEditor = false;
  final _editedStyles = <DemoStyleKind, StyleSummary>{};

  Future<DemoData> _loadData() =>
      _demoFuture ??= loadDemoData(featureSource: _featureSource);

  void _switchFeatureSource(FeatureSource source) {
    setState(() {
      _featureSource = source;
      _demoFuture = null; // neu laden
    });
  }

  @override
  void dispose() {
    _tileProvider.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF7F8),
              Color(0xFFF8F2E7),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DemoData>(
            future: _loadData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Demo konnte nicht geladen werden:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final data = snapshot.requireData;
              final currentSummary =
                  _editedStyles[_selectedKind] ?? data.styles[_selectedKind]!;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1180;
                  final compactPreviewHeight =
                      (constraints.maxHeight * 0.72).clamp(420.0, 760.0);
                  final overview = OverviewPanel(
                    data: data,
                    selectedKind: _selectedKind,
                    onStyleSelected: (value) {
                      setState(() => _selectedKind = value);
                    },
                    featureSource: _featureSource,
                    onFeatureSourceChanged: _switchFeatureSource,
                    showEditor: _showEditor,
                    onToggleEditor: () {
                      setState(() => _showEditor = !_showEditor);
                    },
                    editor: _showEditor
                        ? StyleEditor(
                            style: currentSummary.style,
                            onChanged: (newStyle) {
                              setState(() {
                                _editedStyles[_selectedKind] = StyleSummary(
                                  title: currentSummary.title,
                                  style: newStyle,
                                  notes: currentSummary.notes,
                                );
                              });
                            },
                          )
                        : null,
                  );
                  final preview = PreviewPanel(
                    styleSummary: currentSummary,
                    features: data.features,
                    tileProvider: _tileProvider,
                  );

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 430, child: overview),
                              const SizedBox(width: 20),
                              Expanded(child: preview),
                            ],
                          )
                        : ListView(
                            children: [
                              overview,
                              const SizedBox(height: 20),
                              SizedBox(
                                height: compactPreviewHeight,
                                child: preview,
                              ),
                            ],
                          ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
