import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('ReadStyleResult', () {
    test('ReadStyleSuccess holds output and warnings', () {
      const style = Style(name: 'test');
      const result = ReadStyleSuccess(
        output: style,
        warnings: ['unsupported property'],
      );
      expect(result.output, style);
      expect(result.warnings, ['unsupported property']);
      expect(result, isA<ReadStyleResult>());
    });

    test('ReadStyleSuccess default warnings is empty', () {
      const result = ReadStyleSuccess(output: Style(name: 'x'));
      expect(result.warnings, isEmpty);
    });

    test('ReadStyleFailure holds errors', () {
      const result = ReadStyleFailure(errors: ['parse error']);
      expect(result.errors, ['parse error']);
      expect(result, isA<ReadStyleResult>());
    });
  });

  group('WriteStyleResult', () {
    test('WriteStyleSuccess holds output and warnings', () {
      const result = WriteStyleSuccess<String>(
        output: '<sld>…</sld>',
        warnings: ['degraded feature'],
      );
      expect(result.output, '<sld>…</sld>');
      expect(result.warnings, ['degraded feature']);
      expect(result, isA<WriteStyleResult<String>>());
    });

    test('WriteStyleSuccess default warnings is empty', () {
      const result = WriteStyleSuccess<int>(output: 42);
      expect(result.warnings, isEmpty);
    });

    test('WriteStyleFailure holds errors', () {
      const result = WriteStyleFailure<String>(errors: ['write error']);
      expect(result.errors, ['write error']);
      expect(result, isA<WriteStyleResult<String>>());
    });
  });
}
