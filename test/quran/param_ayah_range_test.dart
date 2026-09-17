import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_range.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

void main() {
  const range = ParamAyahRange(
    start: ParamAyahRef(surah: 2, ayah: 142),
    end: ParamAyahRef(surah: 2, ayah: 252),
  );

  group('ParamAyahRange.tryParse', () {
    test('reads the from/to pair a reader route carries', () {
      expect(ParamAyahRange.tryParse('2:142', '2:252'), range);
    });

    test('is null when either end is missing or malformed', () {
      expect(ParamAyahRange.tryParse(null, '2:252'), isNull);
      expect(ParamAyahRange.tryParse('2:142', null), isNull);
      expect(ParamAyahRange.tryParse('2-142', '2:252'), isNull);
      expect(ParamAyahRange.tryParse('2:142', 'x:y'), isNull);
      expect(ParamAyahRange.tryParse('2:142:1', '2:252'), isNull);
    });
  });

  test('isBound is true for exactly the two ends', () {
    expect(range.isBound(const ParamAyahRef(surah: 2, ayah: 142)), isTrue);
    expect(range.isBound(const ParamAyahRef(surah: 2, ayah: 252)), isTrue);
    expect(range.isBound(const ParamAyahRef(surah: 2, ayah: 200)), isFalse);
    expect(range.isBound(const ParamAyahRef(surah: 3, ayah: 142)), isFalse);
  });

  group('QuranRoutes.readerForRange', () {
    test('lands on the start of the range by default', () {
      final route = QuranRoutes.readerForRange(range);
      final params = Uri.parse(route).queryParameters;
      expect(Uri.parse(route).path, '/quran/reader');
      expect(params['surah'], '2');
      expect(params['ayah'], '142');
      expect(ParamAyahRange.tryParse(params['from'], params['to']), range);
    });

    test('can land on any ayah while keeping the whole range', () {
      final route = QuranRoutes.readerForRange(
        range,
        focus: const ParamAyahRef(surah: 2, ayah: 252),
      );
      final params = Uri.parse(route).queryParameters;
      expect(params['surah'], '2');
      expect(params['ayah'], '252');
      expect(ParamAyahRange.tryParse(params['from'], params['to']), range);
    });
  });
}
