import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_item.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';

/// Per-screen cubit that drives the azkar player: which category we're in,
/// which item is on screen, how many taps each item has gotten today, and the
/// recitation of the zekr on screen.
class CBAzkarSession extends Cubit<SAzkarSession> {
  CBAzkarSession({
    required DSLocalAzkar local,
    required BoxAzkarProgress progress,
  }) : _local = local,
       _progress = progress,
       super(const SAzkarSession());

  final DSLocalAzkar _local;
  final BoxAzkarProgress _progress;

  /// Built on the first play — most sessions only count.
  AudioPlayer? _player;
  StreamSubscription<ProcessingState>? _playerSub;

  /// The zekr whose clip is loaded, so play after a pause resumes it rather
  /// than starting over.
  String? _loadedItemId;

  /// Bumped by every load and stop, so a load that a newer one (a quick swipe)
  /// or a pause overtook never starts playing.
  int _audioRequest = 0;

  /// Loads [categoryId] with today's counts, on the zekr at [itemIndex].
  Future<void> open(String categoryId, {int itemIndex = 0}) async {
    final cat = await _local.category(categoryId);
    // The screen closes this cubit on dispose — it may be gone by now.
    if (cat == null || cat.items.isEmpty || isClosed) return;
    final stored = _progress.today(categoryId);
    final index = itemIndex.clamp(0, cat.items.length - 1);
    emit(
      state.copyWith(
        category: cat,
        itemIndex: index,
        completed: Map<String, int>.from(stored.completedCounts),
      ),
    );
    unawaited(_progress.setLastItem(cat.id, cat.items[index].id));
  }

  /// One repetition of the zekr on screen. The closing card has no counter,
  /// so a tap there does nothing.
  Future<void> tap() async {
    final item = state.currentItem;
    final cat = state.category;
    if (item == null || cat == null || item.isClosing) return;
    if (state.isComplete(item)) {
      next();
      return;
    }
    await _count(cat, item);

    // Reached the last count → pause briefly, then auto-advance to the next zekr.
    if (state.isComplete(item)) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (isClosed) return;
      // Only advance if we're still sitting on the zekr that just completed.
      if (state.currentItem?.id == item.id) next();
    }
  }

  /// Adds one repetition to [item] and saves it to today's progress.
  Future<void> _count(MAzkarCategory cat, MAzkarItem item) async {
    final updated = Map<String, int>.from(state.completed);
    updated[item.id] = (updated[item.id] ?? 0) + 1;
    emit(state.copyWith(completed: updated));
    await _progress.increment(cat.id, item.id);
  }

  void next() => jumpTo(state.itemIndex + 1);

  void previous() => jumpTo(state.itemIndex - 1);

  /// Moves to [index] and remembers it for reopening later today — saved on
  /// every move, since a killed app never gets to save on close. While the
  /// recitation runs it follows the zekr on screen, stopping on one that has
  /// no clip.
  void jumpTo(int index) {
    final cat = state.category;
    if (cat == null || cat.items.isEmpty) return;
    final target = index.clamp(0, cat.items.length - 1);
    if (target == state.itemIndex) return;
    emit(state.copyWith(itemIndex: target));
    unawaited(_progress.setLastItem(cat.id, cat.items[target].id));
    if (state.audioPlaying) unawaited(_playCurrent());
  }

  Future<void> resetCurrent() async {
    final cat = state.category;
    final item = state.currentItem;
    if (cat == null || item == null) return;
    await _progress.resetItem(cat.id, item.id);
    final updated = Map<String, int>.from(state.completed)..remove(item.id);
    emit(state.copyWith(completed: updated));
  }

  /// Play / pause for the zekr on screen. Each playthrough counts as one
  /// repetition, so the clip plays until the zekr reaches its count, then the
  /// next zekr plays — until the list ends or reaches a zekr without a clip.
  Future<void> toggleAudio() async {
    if (state.audioPlaying) {
      await _pauseAudio();
    } else {
      await _playCurrent();
    }
  }

  Future<void> _playCurrent() async {
    final cat = state.category;
    final item = state.currentItem;
    final asset = item?.audioAsset;
    if (cat == null || item == null || asset == null) {
      await stopAudio();
      return;
    }
    final request = ++_audioRequest;
    emit(state.copyWith(audioPlaying: true));
    try {
      final player = _player ?? _createPlayer();
      final resumable = _loadedItemId == item.id &&
          player.processingState != ProcessingState.idle &&
          player.processingState != ProcessingState.completed;
      if (!resumable) {
        // `just_audio_background` allows one platform-active player app-wide,
        // so free the slot before loading. Every source needs a MediaItem tag.
        await AudioFocus.instance.take(this);
        await player.setAudioSource(
          AudioSource.asset(
            asset,
            tag: MediaItem(
              id: item.id,
              album: 'azkar_title'.tr(),
              title: LocalizeAndTranslate.getLanguageCode() == 'ar' ? cat.nameAr : cat.nameEn,
              artUri: MediaArtwork.uri,
            ),
          ),
        );
        _loadedItemId = item.id;
      }
      if (isClosed || request != _audioRequest) return;
      // Completes only when playback pauses or stops — the processing-state
      // listener is what reacts to the clip ending.
      unawaited(player.play());
    } on PlayerInterruptedException {
      // A newer load replaced this one and owns playback now.
    } catch (e, st) {
      AppLogger.error('Azkar audio play (${item.id})', error: e, stackTrace: st, tag: 'CBAzkarSession');
      if (!isClosed && request == _audioRequest) await stopAudio();
    }
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _player = player;
    // Registered on first use so the Qur'an/radio/adhan players can stop this
    // one when they claim the shared background slot.
    AudioFocus.instance.register(this, stopAudio);
    _playerSub = player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed && state.audioPlaying) {
        unawaited(_onClipFinished());
      }
    });
    return player;
  }

  /// A playthrough ended: it counts as one repetition, like a tap. Replays
  /// until the zekr reaches its count, then moves to the next zekr. A zekr
  /// that was already complete plays once, uncounted.
  Future<void> _onClipFinished() async {
    final cat = state.category;
    final item = state.currentItem;
    // Ignore a clip that ended just as the user moved to another zekr.
    if (cat == null || item == null || _loadedItemId != item.id) return;
    final request = _audioRequest;
    final counting = !state.isComplete(item);
    if (counting) await _count(cat, item);
    // A pause, stop, or move during the save owns playback now.
    if (isClosed || request != _audioRequest || state.currentItem?.id != item.id) return;
    if (counting && !state.isComplete(item)) {
      // `playing` stays true past the end, so rewinding replays the clip.
      try {
        await _player?.seek(Duration.zero);
      } catch (e) {
        AppLogger.warning('Azkar audio replay failed: $e', tag: 'CBAzkarSession');
        await stopAudio();
      }
      return;
    }
    if (state.itemIndex >= cat.items.length - 1) {
      await stopAudio();
      return;
    }
    jumpTo(state.itemIndex + 1);
  }

  Future<void> _pauseAudio() async {
    _audioRequest++;
    emit(state.copyWith(audioPlaying: false));
    try {
      await _player?.pause();
    } catch (e) {
      AppLogger.warning('Azkar audio pause failed: $e', tag: 'CBAzkarSession');
    }
  }

  /// Stops the recitation and hands the shared media slot back. Safe to call
  /// when nothing is playing.
  Future<void> stopAudio() async {
    _audioRequest++;
    if (!isClosed && state.audioPlaying) emit(state.copyWith(audioPlaying: false));
    try {
      await _player?.stop();
    } catch (e) {
      AppLogger.warning('Azkar audio stop failed: $e', tag: 'CBAzkarSession');
    }
    AudioFocus.instance.release(this);
  }

  @override
  Future<void> close() async {
    _audioRequest++;
    AudioFocus.instance.unregister(this);
    await _playerSub?.cancel();
    await _player?.dispose();
    return super.close();
  }
}
