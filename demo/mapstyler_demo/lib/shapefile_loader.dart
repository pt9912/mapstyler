import 'dart:typed_data';

import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Liest ein Shapefile (.shp + .dbf) aus Bytes und liefert
/// [StyledFeatureCollection].
///
/// Unterstuetzte Shape-Typen: Point (1), PolyLine (3), Polygon (5).
/// Null-Shapes (0) werden uebersprungen.
StyledFeatureCollection shapefileToFeatures({
  required Uint8List shpBytes,
  required Uint8List dbfBytes,
}) {
  final geometries = _readShp(shpBytes);
  final records = _readDbf(dbfBytes);
  final features = <StyledFeature>[];

  for (var i = 0; i < geometries.length; i++) {
    final geom = geometries[i];
    if (geom == null) continue;
    features.add(StyledFeature(
      id: 'shp-${i + 1}',
      geometry: geom,
      properties: i < records.length ? records[i] : const {},
    ));
  }

  return StyledFeatureCollection(features);
}

// ---------------------------------------------------------------------------
// SHP-Reader
// ---------------------------------------------------------------------------

List<Geometry?> _readShp(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);

  // Header: 100 Bytes
  final fileCode = data.getInt32(0, Endian.big);
  if (fileCode != 9994) {
    throw const FormatException('Kein gueltiges SHP (File-Code != 9994)');
  }
  final fileLength = data.getInt32(24, Endian.big) * 2; // in Bytes

  final geometries = <Geometry?>[];
  var offset = 100; // nach Header

  while (offset < fileLength && offset + 8 <= bytes.length) {
    // Record-Header: 8 Bytes (Big-Endian)
    final contentLength = data.getInt32(offset + 4, Endian.big) * 2;
    offset += 8;

    if (offset + contentLength > bytes.length) break;

    final shapeType = data.getInt32(offset, Endian.little);
    final geom = switch (shapeType) {
      0 => null, // Null-Shape
      1 => _readPoint(data, offset),
      3 => _readPolyLine(data, offset),
      5 => _readPolygon(data, offset),
      _ => null,
    };
    geometries.add(geom);

    offset += contentLength;
  }

  return geometries;
}

PointGeometry _readPoint(ByteData data, int offset) {
  final x = data.getFloat64(offset + 4, Endian.little);
  final y = data.getFloat64(offset + 12, Endian.little);
  return PointGeometry(x, y);
}

List<(double, double)> _readPoints(ByteData data, int offset, int count) {
  final points = <(double, double)>[];
  for (var i = 0; i < count; i++) {
    final x = data.getFloat64(offset + i * 16, Endian.little);
    final y = data.getFloat64(offset + i * 16 + 8, Endian.little);
    points.add((x, y));
  }
  return points;
}

LineStringGeometry _readPolyLine(ByteData data, int offset) {
  // Shape-Type (4) + BBox (32) + NumParts (4) + NumPoints (4)
  final numParts = data.getInt32(offset + 36, Endian.little);
  final numPoints = data.getInt32(offset + 40, Endian.little);

  // Parts-Array beginnt bei offset + 44
  final partsOffset = offset + 44;
  final pointsOffset = partsOffset + numParts * 4;

  final allPoints = _readPoints(data, pointsOffset, numPoints);

  if (numParts <= 1) {
    return LineStringGeometry(allPoints);
  }
  // Nur erster Part (Multi-Parts werden reduziert)
  final end = numParts > 1
      ? data.getInt32(partsOffset + 4, Endian.little)
      : numPoints;
  return LineStringGeometry(allPoints.sublist(0, end));
}

PolygonGeometry _readPolygon(ByteData data, int offset) {
  final numParts = data.getInt32(offset + 36, Endian.little);
  final numPoints = data.getInt32(offset + 40, Endian.little);

  final partsOffset = offset + 44;
  final pointsOffset = partsOffset + numParts * 4;

  final allPoints = _readPoints(data, pointsOffset, numPoints);

  final rings = <List<(double, double)>>[];
  for (var p = 0; p < numParts; p++) {
    final start = data.getInt32(partsOffset + p * 4, Endian.little);
    final end = p + 1 < numParts
        ? data.getInt32(partsOffset + (p + 1) * 4, Endian.little)
        : numPoints;
    rings.add(allPoints.sublist(start, end));
  }
  return PolygonGeometry(rings);
}

// ---------------------------------------------------------------------------
// DBF-Reader
// ---------------------------------------------------------------------------

List<Map<String, Object?>> _readDbf(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);

  final numRecords = data.getInt32(4, Endian.little);
  final headerSize = data.getInt16(8, Endian.little);
  final recordSize = data.getInt16(10, Endian.little);

  // Felder lesen (je 32 Bytes, bis 0x0D Terminator)
  final fields = <_DbfField>[];
  var fieldOffset = 32;
  while (fieldOffset < headerSize - 1 && bytes[fieldOffset] != 0x0D) {
    final nameBytes = bytes.sublist(fieldOffset, fieldOffset + 11);
    final name = String.fromCharCodes(
      nameBytes.takeWhile((b) => b != 0),
    ).trim();
    final type = String.fromCharCode(bytes[fieldOffset + 11]);
    final length = bytes[fieldOffset + 16];
    fields.add(_DbfField(name: name, type: type, length: length));
    fieldOffset += 32;
  }

  // Records lesen
  final records = <Map<String, Object?>>[];
  var recOffset = headerSize;
  for (var i = 0; i < numRecords; i++) {
    if (recOffset + recordSize > bytes.length) break;
    // Erstes Byte: Deletion-Flag (0x20 = gueltig, 0x2A = geloescht)
    if (bytes[recOffset] == 0x2A) {
      recOffset += recordSize;
      continue;
    }

    final props = <String, Object?>{};
    var fOffset = recOffset + 1; // nach Deletion-Flag
    for (final field in fields) {
      final raw = String.fromCharCodes(
        bytes.sublist(fOffset, fOffset + field.length),
      ).trim();
      props[field.name] = switch (field.type) {
        'N' || 'F' => num.tryParse(raw),
        'L' => raw == 'T' || raw == 'Y',
        _ => raw,
      };
      fOffset += field.length;
    }
    records.add(props);
    recOffset += recordSize;
  }

  return records;
}

class _DbfField {
  const _DbfField({
    required this.name,
    required this.type,
    required this.length,
  });

  final String name;
  final String type;
  final int length;
}

// ---------------------------------------------------------------------------
// SHP/DBF-Writer (zum Erzeugen von Testdaten)
// ---------------------------------------------------------------------------

/// Baut minimale SHP-Bytes aus einer Liste von Geometrien.
Uint8List buildShpBytes(List<Geometry> geometries) {
  final records = BytesBuilder();
  for (var i = 0; i < geometries.length; i++) {
    final content = _shapeContent(geometries[i]);
    final recHeader = ByteData(8);
    recHeader.setInt32(0, i + 1, Endian.big); // Record-Nr.
    recHeader.setInt32(4, content.length ~/ 2, Endian.big); // 16-bit Words
    records.add(recHeader.buffer.asUint8List());
    records.add(content);
  }

  final recordBytes = records.toBytes();
  final fileLength = (100 + recordBytes.length) ~/ 2; // 16-bit Words

  final header = ByteData(100);
  header.setInt32(0, 9994, Endian.big); // File-Code
  header.setInt32(24, fileLength, Endian.big); // File-Length
  header.setInt32(28, 1000, Endian.little); // Version
  header.setInt32(32, _shapeType(geometries.first), Endian.little);

  final result = BytesBuilder();
  result.add(header.buffer.asUint8List());
  result.add(recordBytes);
  return result.toBytes();
}

/// Baut minimale DBF-Bytes aus Feld-Definitionen und Records.
Uint8List buildDbfBytes(
  List<({String name, int length})> fields,
  List<Map<String, Object?>> records,
) {
  final fieldCount = fields.length;
  final headerSize = 32 + fieldCount * 32 + 1; // +1 fuer 0x0D
  final recordSize = 1 + fields.fold<int>(0, (s, f) => s + f.length);

  final header = ByteData(headerSize);
  header.setUint8(0, 3); // Version
  header.setInt32(4, records.length, Endian.little);
  header.setInt16(8, headerSize, Endian.little);
  header.setInt16(10, recordSize, Endian.little);

  // Feld-Deskriptoren
  for (var i = 0; i < fieldCount; i++) {
    final off = 32 + i * 32;
    final nameBytes = fields[i].name.codeUnits;
    for (var j = 0; j < nameBytes.length && j < 11; j++) {
      header.setUint8(off + j, nameBytes[j]);
    }
    header.setUint8(off + 11, 0x43); // 'C' = Character
    header.setUint8(off + 16, fields[i].length);
  }
  header.setUint8(headerSize - 1, 0x0D); // Terminator

  final result = BytesBuilder();
  result.add(header.buffer.asUint8List());

  // Records
  for (final rec in records) {
    final recBytes = ByteData(recordSize);
    recBytes.setUint8(0, 0x20); // valid
    var off = 1;
    for (final field in fields) {
      final value = (rec[field.name] ?? '').toString();
      final padded = value.padRight(field.length).substring(0, field.length);
      for (var j = 0; j < padded.length; j++) {
        recBytes.setUint8(off + j, padded.codeUnitAt(j));
      }
      off += field.length;
    }
    result.add(recBytes.buffer.asUint8List());
  }

  return result.toBytes();
}

Uint8List _shapeContent(Geometry geom) {
  return switch (geom) {
    PointGeometry(:final x, :final y) => _pointContent(x, y),
    LineStringGeometry(:final coordinates) => _polyContent(3, [coordinates]),
    PolygonGeometry(:final rings) => _polyContent(5, rings),
    _ => throw UnsupportedError('Shape-Typ nicht unterstuetzt: $geom'),
  };
}

Uint8List _pointContent(double x, double y) {
  final data = ByteData(20);
  data.setInt32(0, 1, Endian.little); // Shape-Type: Point
  data.setFloat64(4, x, Endian.little);
  data.setFloat64(12, y, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _polyContent(int shapeType, List<List<(double, double)>> parts) {
  final numParts = parts.length;
  final numPoints = parts.fold<int>(0, (s, p) => s + p.length);
  final size = 44 + numParts * 4 + numPoints * 16;

  final data = ByteData(size);
  data.setInt32(0, shapeType, Endian.little);
  // BBox (vereinfacht: 0-Werte)
  data.setInt32(36, numParts, Endian.little);
  data.setInt32(40, numPoints, Endian.little);

  // Parts-Array
  var pointIdx = 0;
  for (var p = 0; p < numParts; p++) {
    data.setInt32(44 + p * 4, pointIdx, Endian.little);
    pointIdx += parts[p].length;
  }

  // Points
  var off = 44 + numParts * 4;
  for (final part in parts) {
    for (final (x, y) in part) {
      data.setFloat64(off, x, Endian.little);
      data.setFloat64(off + 8, y, Endian.little);
      off += 16;
    }
  }

  return data.buffer.asUint8List();
}

int _shapeType(Geometry geom) => switch (geom) {
      PointGeometry() => 1,
      LineStringGeometry() => 3,
      PolygonGeometry() => 5,
      _ => 0,
    };
