import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/mapstyler_gdal_adapter_example.dart <path>');
    return;
  }

  final result = await loadVectorFile(args.first, simplifyToleranceMeters: 5);

  print('Loaded ${result.features.features.length} features.');
  for (final warning in result.warnings) {
    print('Warning: $warning');
  }
}
