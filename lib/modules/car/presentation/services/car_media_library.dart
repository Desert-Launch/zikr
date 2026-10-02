import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/media_library.dart';
import 'package:quran/modules/car/domain/entities/e_car_media_id.dart';
import 'package:quran/modules/car/domain/entities/e_car_query_match.dart';
import 'package:quran/modules/car/domain/usecases/uc_match_car_query.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_all_surahs_status.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_reciters.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/radio/data/models/m_radio_station.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_live_stations.dart';
import 'package:quran/modules/radio/domain/usecases/uc_get_national_stations.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';

/// What a car head unit (Android Auto) lists, plays and searches:
///
/// ```
/// القرآن الكريم → reciter → surah        (plays the whole surah)
/// المحمّلة      → surahs fully on disk   (plays with no signal)
/// الإذاعة       → national stations, + live stations folder
/// ```
///
/// Audio only, by design: the car platforms allow no reading, video or maps
/// for an app like this one, so the Mushaf, tafsir, live broadcasts, prayer
/// times and mosques stay on the phone.
///
/// Plays through the same app-wide players as the app itself, so whatever the
/// car starts shows in the app's mini player, and the other way round.
class CarMediaLibrary implements MediaLibrary {
  CarMediaLibrary({
    required UCGetReciters reciters,
    required UCGetSurahList surahs,
    required UCGetAllSurahsStatus surahsStatus,
    required UCGetNationalStations nationalStations,
    required UCGetLiveStations liveStations,
    required UCMatchCarQuery match,
    required CBAudioPlayer quranPlayer,
    required CBReciter reciterChoice,
    required CBRadioPlayer radioPlayer,
  }) : _reciters = reciters,
       _surahs = surahs,
       _surahsStatus = surahsStatus,
       _nationalStations = nationalStations,
       _liveStations = liveStations,
       _match = match,
       _quranPlayer = quranPlayer,
       _reciterChoice = reciterChoice,
       _radioPlayer = radioPlayer;

  final UCGetReciters _reciters;
  final UCGetSurahList _surahs;
  final UCGetAllSurahsStatus _surahsStatus;
  final UCGetNationalStations _nationalStations;
  final UCGetLiveStations _liveStations;
  final UCMatchCarQuery _match;
  final CBAudioPlayer _quranPlayer;
  final CBReciter _reciterChoice;
  final CBRadioPlayer _radioPlayer;

  /// Fallback surah when the driver asks for "Qur'an" with nothing named.
  static const int _openingSurah = 1;

  /// Most results a search screen shows.
  static const int _maxSearchResults = 20;

  /// Live stations from the last successful fetch: playing one by id must not
  /// depend on the network answering a second time.
  List<MRadioStation> _liveCache = const [];

  bool get _isArabic => LocalizeAndTranslate.getLanguageCode() == 'ar';

  // ---------------------------------------------------------------------------
  // Browse
  // ---------------------------------------------------------------------------

  @override
  Future<List<MediaItem>> children(String parentId) async {
    if (parentId == AudioService.browsableRootId) return _rootItems();
    // Nothing to resume from yet; the head unit shows its own empty state.
    if (parentId == AudioService.recentRootId) return const [];
    switch (ECarMediaId.parse(parentId)) {
      case ECarReciters():
        return _reciterItems();
      case ECarReciterSurahs(:final reciterId):
        return _surahItems(reciterId);
      case ECarDownloads():
        return _downloadedItems();
      case ECarRadio():
        return _radioItems();
      case ECarLiveRadio():
        return [for (final s in await _loadLiveStations()) _stationItem(s)];
      case ECarSurah() || ECarStation() || null:
        return const [];
    }
  }

  @override
  Future<MediaItem?> item(String mediaId) async {
    if (mediaId == AudioService.browsableRootId) return null;
    switch (ECarMediaId.parse(mediaId)) {
      case ECarReciters():
        return _quranFolder();
      case ECarDownloads():
        return _downloadsFolder();
      case ECarRadio():
        return _radioFolder();
      case ECarLiveRadio():
        return _liveRadioFolder();
      case ECarReciterSurahs(:final reciterId):
        final reciter = await _reciterById(reciterId);
        return reciter == null ? null : _reciterItem(reciter, activeId: null);
      case ECarSurah(:final reciterId, :final surah):
        final s = await _surahByNumber(surah);
        final reciter = await _reciterById(reciterId);
        if (s == null || reciter == null) return null;
        return _surahItem(s, reciter, downloaded: false);
      case ECarStation(:final stationId):
        final station = await _stationById(stationId);
        return station == null ? null : _stationItem(station);
      case null:
        return null;
    }
  }

  List<MediaItem> _rootItems() => [
    _quranFolder(),
    _downloadsFolder(),
    _radioFolder(),
  ];

  MediaItem _quranFolder() => MediaItem(
    id: const ECarReciters().value,
    title: 'car_quran'.tr(),
    displaySubtitle: 'car_quran_subtitle'.tr(),
    playable: false,
  );

  MediaItem _downloadsFolder() => MediaItem(
    id: const ECarDownloads().value,
    title: 'car_downloads'.tr(),
    displaySubtitle: 'car_downloads_subtitle'.tr(),
    playable: false,
  );

  MediaItem _radioFolder() => MediaItem(
    id: const ECarRadio().value,
    title: 'radio_title'.tr(),
    displaySubtitle: 'radio_subtitle'.tr(),
    playable: false,
  );

  MediaItem _liveRadioFolder() => MediaItem(
    id: const ECarLiveRadio().value,
    title: 'radio_more_section'.tr(),
    playable: false,
  );

  Future<List<MediaItem>> _reciterItems() async {
    final list = await _loadReciters();
    final activeId = (await _reciters.active()).fold<String?>(
      (_) => null,
      (r) => r.id,
    );
    // The current voice first: it is the one most likely wanted.
    final ordered = [
      ...list.where((r) => r.id == activeId),
      ...list.where((r) => r.id != activeId),
    ];
    return [for (final r in ordered) _reciterItem(r, activeId: activeId)];
  }

  MediaItem _reciterItem(MReciter reciter, {required String? activeId}) =>
      MediaItem(
        id: ECarReciterSurahs(reciter.id).value,
        title: _reciterName(reciter),
        displaySubtitle: reciter.id == activeId
            ? 'car_active_reciter'.tr()
            : null,
        playable: false,
      );

  Future<List<MediaItem>> _surahItems(String reciterId) async {
    final reciter = await _reciterById(reciterId);
    if (reciter == null) return const [];
    final surahs = await _loadSurahs();
    final complete = await _completeSurahs(reciterId);
    return [
      for (final s in surahs)
        _surahItem(s, reciter, downloaded: complete.contains(s.number)),
    ];
  }

  /// Every complete surah of every reciter. Reciters are checked in parallel:
  /// each is a disk scan, and the head unit wants an answer within seconds.
  Future<List<MediaItem>> _downloadedItems() async {
    final reciters = await _loadReciters();
    final surahs = await _loadSurahs();
    final byNumber = {for (final s in surahs) s.number: s};
    final complete = await Future.wait([
      for (final r in reciters) _completeSurahs(r.id),
    ]);
    return [
      for (var i = 0; i < reciters.length; i++)
        for (final number in complete[i].toList()..sort())
          if (byNumber[number] case final MSurah s)
            _surahItem(s, reciters[i], downloaded: true, voiceAsSubtitle: true),
    ];
  }

  /// A surah, playable. The subtitle carries what a driver glances for: its
  /// length, whether it plays offline — or, in the downloads list where every
  /// row is offline, whose voice it is.
  MediaItem _surahItem(
    MSurah surah,
    MReciter reciter, {
    required bool downloaded,
    bool voiceAsSubtitle = false,
  }) {
    final ayat = 'surah_list_ayah_count'.translatedWithArgs({
      'count': '${surah.totalAyah}',
    });
    final subtitle = voiceAsSubtitle
        ? _reciterName(reciter)
        : [
            if (!_isArabic) surah.translation,
            ayat,
            if (downloaded) 'car_downloaded'.tr(),
          ].join(' · ');
    return MediaItem(
      id: ECarSurah(reciterId: reciter.id, surah: surah.number).value,
      title: _isArabic ? surah.arabicLong : '${surah.number}. ${surah.name}',
      artist: _reciterName(reciter),
      album: 'car_quran'.tr(),
      displaySubtitle: subtitle,
      playable: true,
    );
  }

  Future<List<MediaItem>> _radioItems() async {
    final national = (await _nationalStations()).fold<List<MRadioStation>>(
      (_) => const [],
      (list) => list,
    );
    return [
      for (final s in national) _stationItem(s),
      _liveRadioFolder(),
    ];
  }

  MediaItem _stationItem(MRadioStation station) => MediaItem(
    id: ECarStation(station.id).value,
    title: station.displayName(isArabic: _isArabic),
    displaySubtitle: station.frequency ?? station.country,
    album: 'radio_title'.tr(),
    playable: true,
  );

  // ---------------------------------------------------------------------------
  // Play
  // ---------------------------------------------------------------------------

  @override
  Future<void> play(String mediaId) async {
    switch (ECarMediaId.parse(mediaId)) {
      case ECarSurah(:final reciterId, :final surah):
        await _playSurah(surah, reciterId: reciterId);
      case ECarStation(:final stationId):
        final station = await _stationById(stationId);
        if (station == null) {
          AppLogger.warning(
            'Car asked for unknown station $stationId',
            tag: 'CarMediaLibrary',
          );
          return;
        }
        // Not awaited: the player's play() completes only when playback ends.
        unawaited(_radioPlayer.play(station));
      case ECarReciters() ||
          ECarReciterSurahs() ||
          ECarDownloads() ||
          ECarRadio() ||
          ECarLiveRadio() ||
          null:
        AppLogger.warning(
          'Car asked to play non-playable id $mediaId',
          tag: 'CarMediaLibrary',
        );
    }
  }

  /// Plays [surah] start to end, in [reciterId]'s voice when given (which then
  /// also becomes the app's chosen reciter, as picking one in the app does).
  Future<void> _playSurah(int surah, {String? reciterId}) async {
    // Not awaited: it completes only when playback ends. It hands the player
    // the new voice synchronously, so the reciter switch below finds the
    // player already on it and does not rebuild the outgoing queue.
    unawaited(_quranPlayer.playSurah(surah, reciterId: reciterId));
    if (reciterId != null) await _reciterChoice.setActiveReciter(reciterId);
  }

  @override
  Future<void> playFromSearch(String query) async {
    final matches = await _matchesFor(query);
    if (matches.isEmpty) {
      // Nothing recognisable — still play something rather than nothing.
      await _playSurah(_openingSurah);
      return;
    }
    switch (matches.first) {
      case ECarSurahMatch(:final surah, :final reciterId):
        await _playSurah(surah, reciterId: reciterId);
      case ECarReciterMatch(:final reciterId):
        await _playSurah(_openingSurah, reciterId: reciterId);
      case ECarStationMatch(:final stationId):
        await play(ECarStation(stationId).value);
    }
  }

  @override
  Future<List<MediaItem>> search(String query) async {
    final matches = await _matchesFor(query);
    final results = <MediaItem>[];
    for (final m in matches.take(_maxSearchResults)) {
      final id = switch (m) {
        ECarSurahMatch(:final surah, :final reciterId) => ECarSurah(
          reciterId: reciterId ?? await _activeReciterId(),
          surah: surah,
        ).value,
        ECarReciterMatch(:final reciterId) => ECarReciterSurahs(
          reciterId,
        ).value,
        ECarStationMatch(:final stationId) => ECarStation(stationId).value,
      };
      final item = await this.item(id);
      if (item != null) results.add(item);
    }
    return results;
  }

  Future<List<ECarQueryMatch>> _matchesFor(String query) async {
    final stations = [
      ...(await _nationalStations()).fold<List<MRadioStation>>(
        (_) => const [],
        (list) => list,
      ),
      ..._liveCache,
    ];
    return _match(
      query,
      surahs: await _loadSurahs(),
      reciters: await _loadReciters(),
      stations: stations,
    );
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<List<MReciter>> _loadReciters() async =>
      (await _reciters()).fold((_) => const [], (list) => list);

  Future<List<MSurah>> _loadSurahs() async =>
      (await _surahs()).fold((_) => const [], (list) => list);

  Future<MReciter?> _reciterById(String id) async {
    for (final r in await _loadReciters()) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<MSurah?> _surahByNumber(int number) async {
    for (final s in await _loadSurahs()) {
      if (s.number == number) return s;
    }
    return null;
  }

  Future<String> _activeReciterId() async {
    final active = await _reciters.active();
    return active.fold(
      (_) async {
        final list = await _loadReciters();
        return list.isEmpty ? 'alafasy' : list.first.id;
      },
      (r) async => r.id,
    );
  }

  /// Surah numbers fully on disk for [reciterId]; empty when unknown.
  Future<Set<int>> _completeSurahs(String reciterId) async {
    final res = await _surahsStatus(reciterId);
    return res.fold((_) => const <int>{}, (map) {
      return {
        for (final entry in map.entries)
          if (entry.value.isComplete) entry.key,
      };
    });
  }

  Future<List<MRadioStation>> _loadLiveStations() async {
    final res = await _liveStations(language: _isArabic ? 'ar' : 'eng');
    return res.fold(
      (failure) {
        AppLogger.warning(
          'Car live stations unavailable: ${failure.message}',
          tag: 'CarMediaLibrary',
        );
        return _liveCache;
      },
      (list) => _liveCache = list,
    );
  }

  Future<MRadioStation?> _stationById(String id) async {
    final national = (await _nationalStations()).fold<List<MRadioStation>>(
      (_) => const [],
      (list) => list,
    );
    for (final s in [...national, ..._liveCache]) {
      if (s.id == id) return s;
    }
    // A live station picked before the catalogue was fetched in this run.
    for (final s in await _loadLiveStations()) {
      if (s.id == id) return s;
    }
    return null;
  }

  String _reciterName(MReciter reciter) =>
      _isArabic && reciter.arabic.isNotEmpty ? reciter.arabic : reciter.name;
}
