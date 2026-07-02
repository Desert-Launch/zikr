import 'package:equatable/equatable.dart';
import 'package:quran/modules/live/domain/entities/e_live_channel.dart';

/// resolving → looking up the channel's current live id.
/// ready     → [SLive.videoId] holds a playable id (resolved, or the fallback).
enum LiveResolveStatus { resolving, ready }

class SLive extends Equatable {
  const SLive({
    this.channel = ELiveChannel.makkah,
    this.status = LiveResolveStatus.resolving,
    this.videoId,
    this.usedFallback = false,
  });

  /// The selected Haramain channel.
  final ELiveChannel channel;

  /// Resolution progress for [channel].
  final LiveResolveStatus status;

  /// The id to embed once [status] is ready. Null while resolving.
  final String? videoId;

  /// True when [videoId] is the channel's last-known-good id (live resolution
  /// failed) rather than the freshly resolved current broadcast.
  final bool usedFallback;

  SLive copyWith({
    ELiveChannel? channel,
    LiveResolveStatus? status,
    String? videoId,
    bool? usedFallback,
    bool clearVideoId = false,
  }) {
    return SLive(
      channel: channel ?? this.channel,
      status: status ?? this.status,
      videoId: clearVideoId ? null : (videoId ?? this.videoId),
      usedFallback: usedFallback ?? this.usedFallback,
    );
  }

  @override
  List<Object?> get props => [channel.id, status, videoId, usedFallback];
}
