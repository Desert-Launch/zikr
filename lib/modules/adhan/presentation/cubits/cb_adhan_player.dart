import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_download.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_player.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';

/// App-wide adhan playback singleton. Owns a single [AudioPlayer] for both
/// preview-in-settings and prayer-time playback. Handles locale-aware default
/// selection and a Fajr-specific override.
///
/// Asset bundle expectation: each adhan's `asset` field points to a real
/// MP3 in `assets/audio/adhan/`. If the bundle is missing the file, preview
/// quietly errors and the regular adhan plays — never crashes.
class CBAdhanPlayer extends Cubit<SAdhanPlayer> {
  CBAdhanPlayer({
    required DSLocalAdhan local,
    required BoxAdhanPreference prefs,
    required BoxPrayerSettings prayerSettings,
    required BoxAdhanDownload downloads,
    required String localeTag,
  }) : _local = local,
       _prefs = prefs,
       _prayerSettings = prayerSettings,
       _downloads = downloads,
       _localeTag = localeTag,
       _player = AudioPlayer(),
       super(const SAdhanPlayer()) {
    _hydrate();
    _wireStateStream();
  }

  final DSLocalAdhan _local;
  final BoxAdhanPreference _prefs;
  final BoxPrayerSettings _prayerSettings;
  final BoxAdhanDownload _downloads;
  final String _localeTag;
  final AudioPlayer _player;

  StreamSubscription<PlayerState>? _stateSub;

  Future<void> _hydrate() async {
    try {
      final all = await _local.all();
      final pref = _prefs.current();
      final regular = pref.defaultAdhanId != null
          ? (await _local.byId(pref.defaultAdhanId!)) ??
                await _local.defaultForLocale(_localeTag)
          : await _local.defaultForLocale(_localeTag);
      final fajr = pref.fajrAdhanId != null
          ? (await _local.byId(pref.fajrAdhanId!)) ?? await _local.fajrDefault()
          : await _local.fajrDefault();
      emit(
        state.copyWith(
          allAdhans: all,
          defaultAdhan: regular,
          fajrAdhan: fajr,
          useFajrSpecific: pref.useFajrSpecific,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Adhan hydrate',
        error: e,
        stackTrace: st,
        tag: 'CBAdhanPlayer',
      );
      emit(
        state.copyWith(status: AdhanPlayerStatus.error, error: e.toString()),
      );
    }
  }

  void _wireStateStream() {
    _stateSub = _player.playerStateStream.listen((ps) {
      AdhanPlayerStatus next;
      switch (ps.processingState) {
        case ProcessingState.idle:
          next = AdhanPlayerStatus.idle;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          next = AdhanPlayerStatus.loading;
        case ProcessingState.ready:
          next = ps.playing
              ? AdhanPlayerStatus.playing
              : AdhanPlayerStatus.paused;
        case ProcessingState.completed:
          next = AdhanPlayerStatus.completed;
      }
      emit(
        state.copyWith(
          status: next,
          clearPreview: next == AdhanPlayerStatus.completed,
        ),
      );
    });
  }

  /// Plays the full adhan for [adhan]. Used both for the preview button in the
  /// picker and the actual prayer-time playback handler. The source is resolved
  /// in order: a downloaded full file on disk → the bundled asset → streaming
  /// the remote [MAdhan.fullUrl] (preview before download). This lets remote
  /// voices preview/play even when they ship no bundled asset.
  Future<void> play(MAdhan adhan) async {
    try {
      emit(
        state.copyWith(
          status: AdhanPlayerStatus.loading,
          currentPreview: adhan,
          clearError: true,
        ),
      );
      final localPath = _downloads.localPath(adhan.id);
      if (localPath != null) {
        await _player.setFilePath(localPath);
      } else if (adhan.asset.isNotEmpty) {
        await _player.setAsset(adhan.asset);
      } else if (adhan.fullUrl?.isNotEmpty ?? false) {
        await _player.setUrl(adhan.fullUrl ?? '');
      } else {
        throw StateError('No playable source for adhan ${adhan.id}');
      }
      await _player.play();
    } catch (e, st) {
      AppLogger.warning(
        'Adhan play failed for ${adhan.id}: $e',
        tag: 'CBAdhanPlayer',
      );
      AppLogger.error(
        'Adhan play',
        error: e,
        stackTrace: st,
        tag: 'CBAdhanPlayer',
      );
      emit(
        state.copyWith(
          status: AdhanPlayerStatus.error,
          error: e.toString(),
          clearPreview: true,
        ),
      );
    }
  }

  /// Plays the right adhan for a given prayer key (`fajr`/`dhuhr`/etc.).
  /// Honors the user's Fajr override + the `useFajrSpecific` flag.
  Future<void> playForPrayer(String prayerKey) async {
    final overrideId = _prayerSettings.current().adhanIdPerPrayer?[prayerKey];
    final override = overrideId == null ? null : await _local.byId(overrideId);
    final adhan = override ?? adhanForPrayer(prayerKey);
    if (adhan == null) return;
    await play(adhan);
  }

  MAdhan? adhanForPrayer(String prayerKey) {
    if (prayerKey == 'fajr' &&
        state.useFajrSpecific &&
        state.fajrAdhan != null) {
      return state.fajrAdhan;
    }
    return state.defaultAdhan;
  }

  Future<void> stop() async {
    await _player.stop();
    emit(state.copyWith(status: AdhanPlayerStatus.idle, clearPreview: true));
  }

  Future<void> selectDefault(String adhanId) async {
    await _prefs.setDefault(adhanId);
    final adhan = await _local.byId(adhanId);
    if (adhan != null) emit(state.copyWith(defaultAdhan: adhan));
  }

  Future<void> selectFajr(
    String? adhanId, {
    required bool useFajrSpecific,
  }) async {
    await _prefs.setFajr(adhanId, useFajrSpecific: useFajrSpecific);
    if (adhanId != null) {
      final adhan = await _local.byId(adhanId);
      if (adhan != null) {
        emit(
          state.copyWith(fajrAdhan: adhan, useFajrSpecific: useFajrSpecific),
        );
        return;
      }
    }
    emit(state.copyWith(useFajrSpecific: useFajrSpecific));
  }

  @override
  Future<void> close() async {
    await _stateSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
