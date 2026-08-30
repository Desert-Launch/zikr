import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:share_plus/share_plus.dart';

/// Turns a painted [RepaintBoundary] into a PNG and hands it to the system
/// share sheet.
///
/// The boundary has to be a *painted* part of the tree — an `Offstage` or
/// zero-height subtree is laid out but never painted, and capturing it yields
/// nothing. Whatever is being captured should therefore be on screen, which is
/// no hardship: a share preview the reader can see is the honest way to show
/// them what they are about to send.
class ShareImageHelper {
  ShareImageHelper._();

  /// Captures [boundaryKey] and shares it as `<fileName>.png`.
  ///
  /// [origin] is the rect the iPad popover points at — pass the sender's
  /// bounds, or the share sheet appears in the corner of the screen.
  ///
  /// Returns false when there was nothing to capture; the caller decides what
  /// to tell the reader.
  static Future<bool> shareBoundary({
    required GlobalKey boundaryKey,
    required String fileName,
    String? text,
    Rect? origin,
    double pixelRatio = 3,
  }) async {
    final bytes = await capture(boundaryKey, pixelRatio: pixelRatio);
    if (bytes == null) return false;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: origin,
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'sharing the rendered card failed',
        error: e,
        stackTrace: st,
        tag: 'ShareImageHelper',
      );
      return false;
    }
  }

  /// Longest edge a captured card is allowed to reach. Well inside the texture
  /// limit of any device the app runs on, with room to spare for the encode.
  static const double _maxEdge = 4096;

  /// [preferred], reduced far enough that a card of [size] stays within
  /// [_maxEdge].
  ///
  /// Nothing stops a reader sharing a whole surah, and thirty verses with two
  /// commentaries under them is a very tall picture — tall enough, at three
  /// times scale, to be a texture no GPU will allocate. Rather than refuse the
  /// share, the card comes out at whatever resolution it fits in.
  static double _fittedRatio(Size size, double preferred) {
    final longest = size.longestSide;
    if (longest <= 0) return preferred;
    final ceiling = _maxEdge / longest;
    return ceiling < preferred ? ceiling : preferred;
  }

  /// PNG bytes for the boundary behind [boundaryKey], or null if it is not
  /// mounted or has not been painted.
  static Future<Uint8List?> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    try {
      // A boundary built this frame has no layer to read yet, and there is no
      // way to ask whether it has one: `debugNeedsPaint` is debug-only and
      // throws a LateInitializationError anywhere else. So wait a frame
      // unconditionally — next to opening a share sheet it costs nothing, and
      // it is what makes a format the reader just switched to capturable.
      await WidgetsBinding.instance.endOfFrame;
      final object = boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return null;
      final image = await object.toImage(
        pixelRatio: _fittedRatio(object.size, pixelRatio),
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (e, st) {
      AppLogger.error(
        'capturing the rendered card failed',
        error: e,
        stackTrace: st,
        tag: 'ShareImageHelper',
      );
      return null;
    }
  }
}
