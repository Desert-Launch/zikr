import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Resolves the bundled app icon to a real `file://` [Uri] for use as the media
/// notification / lock-screen `artUri` on audio players.
///
/// `just_audio_background` loads artwork through `flutter_cache_manager`, which
/// only understands http(s)/file URIs. Passing an `asset:///…` URI throws
/// `Invalid argument(s): No host specified in URI` (it tries to HTTP-download
/// it). We copy the asset to the temp dir once at startup and hand out that
/// `file://` URI instead — shared by the radio, adhan, and Quran audio players.
class MediaArtwork {
  MediaArtwork._();

  static const String _asset = 'assets/images/app_icon.png';
  static Uri? _uri;

  /// The resolved artwork URI, or `null` if [prepare] hasn't finished yet or
  /// failed. Safe to pass straight to `MediaItem.artUri` (which is nullable).
  static Uri? get uri => _uri;

  /// Materializes the bundled icon to a temp file. Idempotent; call once during
  /// app startup. Silently degrades to no artwork on failure.
  static Future<void> prepare() async {
    if (_uri != null) return;
    try {
      final data = await rootBundle.load(_asset);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/media_art_app_icon.png');
      if (!await file.exists()) {
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      _uri = file.uri;
    } catch (e) {
      AppLogger.warning('MediaArtwork.prepare failed: $e', tag: 'MediaArtwork');
    }
  }
}
