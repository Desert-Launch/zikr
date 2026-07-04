import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/live/domain/entities/e_live_channel.dart';
import 'package:quran/modules/live/domain/usecases/uc_resolve_live_video.dart';
import 'package:quran/modules/live/presentation/cubits/s_live.dart';

/// Owns which Haramain channel is selected and resolves its CURRENT live video
/// id (see [UCResolveLiveVideo]). On resolution failure it falls back to the
/// channel's last-known-good [ELiveChannel.videoId] so the surface always has
/// something to play. The screen watches [SLive.videoId] and loads the embed.
class CBLive extends Cubit<SLive> {
  CBLive(this._resolve) : super(const SLive());
  final UCResolveLiveVideo _resolve;

  /// Selects [channel] and resolves its live id.
  Future<void> open(ELiveChannel channel) async {
    emit(state.copyWith(
      channel: channel,
      status: LiveResolveStatus.resolving,
      usedFallback: false,
      clearVideoId: true,
    ));

    final result = await _resolve(channel.channelId);

    // A quick toggle may have moved on while we awaited — ignore stale results.
    if (channel.id != state.channel.id) return;

    result.fold(
      (_) => emit(state.copyWith(
        status: LiveResolveStatus.ready,
        videoId: channel.videoId,
        usedFallback: true,
      )),
      (id) => emit(state.copyWith(
        status: LiveResolveStatus.ready,
        videoId: id,
        usedFallback: false,
      )),
    );
  }
}
