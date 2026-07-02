import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';

abstract class RLive {
  /// Resolves the id of the video a YouTube [channelId] is broadcasting right
  /// now. Network-dependent; returns a [Failure] when offline, the host is
  /// unreachable, or the channel is not currently live. Callers fall back to the
  /// channel's last-known-good id on [Left].
  Future<Either<Failure, String>> resolveLiveVideoId(String channelId);
}
