import 'package:flutter_test/flutter_test.dart';
import 'package:quran/modules/mosques/data/models/m_mosque.dart';

/// Shapes taken from real Places API (New) `searchNearby` responses (Doha).
Map<String, dynamic> _place({
  String id = 'ChIJF3mrFwDbRT4R',
  String? name = 'جامع المدينة التعليمية',
  String? address = '8C8W+QJ9، الريان',
  double? lat = 25.3170,
  double? lng = 51.4466,
}) => {
  'id': id,
  if (name != null) 'displayName': {'text': name, 'languageCode': 'ar'},
  if (address != null) 'shortFormattedAddress': address,
  if (lat != null && lng != null)
    'location': {'latitude': lat, 'longitude': lng},
};

void main() {
  group('MMosque.tryParse', () {
    test('reads id, name and coordinates', () {
      final m = MMosque.tryParse(_place());
      expect(m, isNotNull);
      expect(m?.id, 'ChIJF3mrFwDbRT4R');
      expect(m?.name, 'جامع المدينة التعليمية');
      expect(m?.latitude, 25.3170);
      expect(m?.longitude, 51.4466);
    });

    test('drops a leading plus code followed by an Arabic comma', () {
      expect(MMosque.tryParse(_place())?.address, 'الريان');
    });

    test('drops a leading plus code followed by a Latin comma', () {
      final m = MMosque.tryParse(
        _place(address: '8C7R+VX8, Education City - Gate 7, الريان'),
      );
      expect(m?.address, 'Education City - Gate 7, الريان');
    });

    test('drops a leading plus code followed by a space only', () {
      final m = MMosque.tryParse(
        _place(address: '7GPJ+5CF Al koot Fort Round About, الدوحة'),
      );
      expect(m?.address, 'Al koot Fort Round About, الدوحة');
    });

    test('leaves a street address alone', () {
      final m = MMosque.tryParse(_place(address: '640 شارع الشقب، الريان'));
      expect(m?.address, '640 شارع الشقب، الريان');
    });

    test('an address-less place gets an empty address', () {
      expect(MMosque.tryParse(_place(address: null))?.address, '');
    });

    test('rejects a place without a name or a location', () {
      expect(MMosque.tryParse(_place(name: null)), isNull);
      expect(MMosque.tryParse(_place(name: '  ')), isNull);
      expect(MMosque.tryParse(_place(lat: null)), isNull);
    });
  });
}
