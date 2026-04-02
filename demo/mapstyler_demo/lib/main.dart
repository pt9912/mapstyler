import 'dart:io';

import 'package:flutter/material.dart';

import 'caching_tile_provider.dart';
import 'demo_data.dart';
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
  late final Future<DemoData> _demoFuture = loadDemoData();
  late final CachingTileProvider _tileProvider = CachingTileProvider(
    cacheDir: Directory('${Directory.systemTemp.path}/mapstyler_tiles'),
  );
  DemoStyleKind _selectedKind = DemoStyleKind.manual;

  @override
  void dispose() {
    _tileProvider.dispose();
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
            future: _demoFuture,
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
              final currentStyle = data.styles[_selectedKind]!;

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
                  );
                  final preview = PreviewPanel(
                    styleSummary: currentStyle,
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
