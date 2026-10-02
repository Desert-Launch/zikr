import 'package:just_audio/just_audio.dart';

/// How one domain player is exposed on the app's media session — the
/// notification, lock screen, headset buttons and Android Auto.
///
/// The session mirrors [player]'s state, and a transport command from any of
/// those surfaces reaches [player] directly unless the owner overrides it here.
/// An override exists for a command that carries domain meaning: stopping must
/// reset the owner's state, and the Qur'an player skips by ayah rather than by
/// playlist entry (a repeated ayah is several entries).
///
/// Registered with [AudioFocus.register]; the session follows whichever owner
/// holds focus.
class MediaSessionBinding {
  const MediaSessionBinding({
    required this.player,
    required this.onStop,
    this.onSkipToNext,
    this.onSkipToPrevious,
    this.onSkipToQueueItem,
  });

  final AudioPlayer player;

  /// The owner's own stop, so a stop from the notification or the car clears
  /// the owner's state exactly like its in-app stop button does.
  final Future<void> Function() onStop;

  /// Null → the player's next playlist entry.
  final Future<void> Function()? onSkipToNext;

  /// Null → the player's previous playlist entry.
  final Future<void> Function()? onSkipToPrevious;

  /// Null → seek the player straight to that playlist entry.
  final Future<void> Function(int index)? onSkipToQueueItem;
}
