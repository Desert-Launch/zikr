import 'package:quran/modules/radio/data/models/m_radio_station.dart';

/// Curated, offline-safe national Quran radio broadcasts.
///
/// These are the headline stations for the radio screen. They are hard-coded
/// (not in the mp3quran API) so they always render, even with no network. The
/// stream URLs are the public broadcaster endpoints (radiojar / HLS).
class DSLocalRadio {
  const DSLocalRadio();

  List<MRadioStation> nationalStations() => const [
    MRadioStation(
      id: 'national_eg_cairo',
      name: 'إذاعة القرآن الكريم من القاهرة',
      nameEn: 'Holy Quran Radio — Cairo',
      url: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
      country: 'مصر',
      flag: '🇪🇬',
      frequency: '93.1 FM',
      isNational: true,
    ),
    MRadioStation(
      id: 'national_qa_doha',
      name: 'إذاعة القرآن الكريم - الدوحة',
      nameEn: 'Holy Quran Radio — Doha',
      url: 'https://live.kwikmotion.com/qmcquranradiolive/quranradio/playlist.m3u8',
      country: 'قطر',
      flag: '🇶🇦',
      frequency: '103.4 FM',
      isNational: true,
    ),
    MRadioStation(
      id: 'national_sa',
      name: 'إذاعة القرآن الكريم - السعودية',
      nameEn: 'Holy Quran Radio — Saudi Arabia',
      url: 'https://stream.radiojar.com/0tpy1h0kxtzuv',
      country: 'السعودية',
      flag: '🇸🇦',
      isNational: true,
    ),
  ];
}
