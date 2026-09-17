import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/prayer/data/datasources/remote/aladhan_query_builder.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// Pins the query the app sends. Every expectation here was checked against a
/// live response first — Aladhan echoes `meta.school`,
/// `meta.latitudeAdjustmentMethod` and `meta.offset` back, so these are
/// observations, not guesses.
void main() {
  Map<String, dynamic> build(EPrayerSettings settings) =>
      AladhanQueryBuilder.build(
        latitude: 30.0444,
        longitude: 31.2357,
        settings: settings,
      );

  group('calculation method', () {
    test('automatic sends no method — that is what makes it automatic', () {
      final query = build(EPrayerSettings.defaults);

      expect(query.containsKey('method'), isFalse);
      expect(query['latitude'], '30.0444');
      expect(query['longitude'], '31.2357');
    });

    test('manual sends the pinned method id', () {
      final query = build(
        const EPrayerSettings(
          mode: ECalculationMode.manual,
          manualMethodId: 5,
        ),
      );

      expect(query['method'], '5');
    });

    test(
      'switching back to automatic stops sending the remembered manual method',
      () {
        // The id stays in storage so re-selecting manual restores the user's
        // choice — but sending it here would pin "Automatic" to wherever they
        // used to live, which is the one bug automatic mode exists to avoid.
        final query = build(
          const EPrayerSettings(
            mode: ECalculationMode.automatic,
            manualMethodId: 5,
          ),
        );

        expect(query.containsKey('method'), isFalse);
      },
    );
  });

  group('Asr school', () {
    test('standard sends school=0', () {
      expect(build(EPrayerSettings.defaults)['school'], '0');
    });

    test('hanafi sends school=1', () {
      final query = build(
        const EPrayerSettings(asrSchool: EAsrSchool.hanafi),
      );

      expect(query['school'], '1');
    });

    test('school is independent of the calculation method', () {
      final query = build(
        const EPrayerSettings(
          mode: ECalculationMode.manual,
          manualMethodId: 5,
          asrSchool: EAsrSchool.hanafi,
        ),
      );

      expect(query['method'], '5');
      expect(query['school'], '1');
    });
  });

  group('high latitude', () {
    test('automatic omits the parameter, leaving the API default', () {
      expect(
        build(EPrayerSettings.defaults).containsKey(
          'latitudeAdjustmentMethod',
        ),
        isFalse,
      );
    });

    test('each explicit rule maps to its API value', () {
      const expected = {
        EHighLatitudeRule.middleOfTheNight: '1',
        EHighLatitudeRule.oneSeventh: '2',
        EHighLatitudeRule.angleBased: '3',
      };

      expected.forEach((rule, value) {
        final query = build(EPrayerSettings(highLatitudeRule: rule));
        expect(query['latitudeAdjustmentMethod'], value, reason: rule.name);
      });
    });
  });

  group('tune', () {
    test('all-zero adjustments send no tune parameter at all', () {
      expect(build(EPrayerSettings.defaults).containsKey('tune'), isFalse);
    });

    test('tune is ordered Imsak,Fajr,Sunrise,Dhuhr,Asr,Maghrib,Sunset,Isha,'
        'Midnight', () {
      // Maghrib sits BEFORE Sunset in this list, which is not clock order —
      // getting the two the wrong way round shifts the sunset marker instead
      // of the prayer.
      final query = build(
        const EPrayerSettings(
          adjustments: EPrayerAdjustments(fajr: 2, maghrib: 1),
        ),
      );

      expect(query['tune'], '0,2,0,0,0,1,0,0,0');
    });

    test('every slot lands in its own position', () {
      final query = build(
        const EPrayerSettings(
          adjustments: EPrayerAdjustments(
            imsak: 1,
            fajr: 2,
            sunrise: 3,
            dhuhr: 4,
            asr: 5,
            maghrib: 6,
            sunset: 7,
            isha: 8,
            midnight: 9,
          ),
        ),
      );

      expect(query['tune'], '1,2,3,4,5,6,7,8,9');
    });

    test('negative adjustments survive the round trip', () {
      final query = build(
        const EPrayerSettings(adjustments: EPrayerAdjustments(isha: -3)),
      );

      expect(query['tune'], '0,0,0,0,0,0,0,-3,0');
    });
  });

  group('cache signature', () {
    test('every setting that changes the times changes the signature', () {
      const base = EPrayerSettings.defaults;
      final signatures = {
        base.cacheSignature,
        base
            .copyWith(mode: ECalculationMode.manual, manualMethodId: 5)
            .cacheSignature,
        base.copyWith(asrSchool: EAsrSchool.hanafi).cacheSignature,
        base
            .copyWith(highLatitudeRule: EHighLatitudeRule.oneSeventh)
            .cacheSignature,
        base
            .copyWith(adjustments: const EPrayerAdjustments(fajr: 1))
            .cacheSignature,
      };

      // Five distinct settings must not collide onto one cache entry, or a
      // changed setting would read back times computed under the old one.
      expect(signatures, hasLength(5));
    });

    test('the same settings always produce the same signature', () {
      expect(
        const EPrayerSettings(asrSchool: EAsrSchool.hanafi).cacheSignature,
        const EPrayerSettings(asrSchool: EAsrSchool.hanafi).cacheSignature,
      );
    });

    test('a manual method the mode is not using does not change it', () {
      // Automatic sends no method, so an unused remembered id must not split
      // the cache.
      expect(
        const EPrayerSettings(manualMethodId: 5).cacheSignature,
        EPrayerSettings.defaults.cacheSignature,
      );
    });
  });
}
