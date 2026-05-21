/// URL builders for the audio CDNs.
///
/// Primary: EveryAyah.com — `https://everyayah.com/data/{folder}/{SSSAAA}.mp3`
/// Fallback: AlQuran.cloud — `https://cdn.islamic.network/quran/audio/{br}/{edition}/{ayahNumber}.mp3`
class DSRemoteAudio {
  DSRemoteAudio();

  static const String everyayahBase = 'https://everyayah.com/data';
  static const String alquranCloudBase = 'https://cdn.islamic.network/quran/audio';

  /// Default AlQuran.cloud editions per reciter id. (Used as fallback only.)
  static const Map<String, String> _fallbackEdition = {
    'alafasy': 'ar.alafasy',
    'husary': 'ar.husary',
    'minshawi_murattal': 'ar.minshawi',
    'sudais': 'ar.abdulbasitmurattal', // closest available
    'abdulbasit_murattal': 'ar.abdulbasitmurattal',
    'maher': 'ar.mahermuaiqly',
    'shuraim': 'ar.saoodshuraym',
  };

  String primaryUrl({
    required String folder,
    required int surah,
    required int ayah,
  }) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '$everyayahBase/$folder/$s$a.mp3';
  }

  /// Returns null if no AlQuran.cloud fallback exists for this reciter.
  String? fallbackUrl({
    required String reciterId,
    required int ayahNumber,
    int bitrate = 128,
  }) {
    final edition = _fallbackEdition[reciterId];
    if (edition == null) return null;
    return '$alquranCloudBase/$bitrate/$edition/$ayahNumber.mp3';
  }
}
