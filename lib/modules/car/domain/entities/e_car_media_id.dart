import 'package:equatable/equatable.dart';

/// Id of a node in the car library. A head unit hands an id back verbatim when
/// the driver opens or plays an item, so every id spells out what it points at.
///
/// The browse root and the "recent" slot are not here: their ids are fixed by
/// the media session (`AudioService.browsableRootId` / `recentRootId`).
sealed class ECarMediaId extends Equatable {
  const ECarMediaId();

  static const String _quran = 'quran';
  static const String _downloads = 'downloads';
  static const String _radio = 'radio';
  static const String _liveRadio = 'radio_live';
  static const String _station = 'station';

  /// The string handed to the head unit.
  String get value;

  /// The id [raw] stands for, or null when this library never handed it out.
  static ECarMediaId? parse(String raw) {
    // Station ids come from a remote catalogue: take everything after the
    // prefix rather than trusting it to be free of separators.
    const stationPrefix = '$_station/';
    if (raw.startsWith(stationPrefix)) {
      final id = raw.substring(stationPrefix.length);
      return id.isEmpty ? null : ECarStation(id);
    }
    switch (raw.split('/')) {
      case [_quran]:
        return const ECarReciters();
      case [_quran, final reciterId] when reciterId.isNotEmpty:
        return ECarReciterSurahs(reciterId);
      case [_quran, final reciterId, final number] when reciterId.isNotEmpty:
        final surah = int.tryParse(number);
        if (surah == null || surah < 1 || surah > 114) return null;
        return ECarSurah(reciterId: reciterId, surah: surah);
      case [_downloads]:
        return const ECarDownloads();
      case [_radio]:
        return const ECarRadio();
      case [_liveRadio]:
        return const ECarLiveRadio();
    }
    return null;
  }

  @override
  List<Object?> get props => [value];
}

/// Folder: every reciter.
final class ECarReciters extends ECarMediaId {
  const ECarReciters();

  @override
  String get value => ECarMediaId._quran;
}

/// Folder: the 114 surahs in one reciter's voice.
final class ECarReciterSurahs extends ECarMediaId {
  const ECarReciterSurahs(this.reciterId);

  final String reciterId;

  @override
  String get value => '${ECarMediaId._quran}/$reciterId';
}

/// Playable: one surah, start to end, in one reciter's voice.
final class ECarSurah extends ECarMediaId {
  const ECarSurah({required this.reciterId, required this.surah});

  final String reciterId;
  final int surah;

  @override
  String get value => '${ECarMediaId._quran}/$reciterId/$surah';
}

/// Folder: surahs fully on disk, playable with no signal.
final class ECarDownloads extends ECarMediaId {
  const ECarDownloads();

  @override
  String get value => ECarMediaId._downloads;
}

/// Folder: the national Qur'an radios, plus the live-station folder.
final class ECarRadio extends ECarMediaId {
  const ECarRadio();

  @override
  String get value => ECarMediaId._radio;
}

/// Folder: the live station catalogue (network).
final class ECarLiveRadio extends ECarMediaId {
  const ECarLiveRadio();

  @override
  String get value => ECarMediaId._liveRadio;
}

/// Playable: one radio station.
final class ECarStation extends ECarMediaId {
  const ECarStation(this.stationId);

  final String stationId;

  @override
  String get value => '${ECarMediaId._station}/$stationId';
}
