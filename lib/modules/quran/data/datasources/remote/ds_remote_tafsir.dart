import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/core/services/network/end_points.dart';

/// Downloads tafsir books from the Quranic Universal Library (QUL).
///
/// Files are base64-encoded BZip2 JSON (`.json.txt`). Uses its OWN [Dio] (not
/// the shared [BaseDio]) so the app's Authorization header and mock interceptor
/// never touch a third-party host — same pattern as [DSRemoteRadio]. Decoding
/// (base64 → BZip2 → utf8) runs off the UI thread via [compute]. Lets
/// exceptions bubble; the repo converts them to Failures.
class DSRemoteTafsir {
  DSRemoteTafsir()
      : _dio = Dio(BaseOptions(
          baseUrl: EndPoints.tafsirBase,
          responseType: ResponseType.plain,
        ));

  final Dio _dio;

  /// Downloads and decodes the book at [fullPath], returning its raw JSON
  /// string (`{ "surah:ayah": {"text": ...} }`). [onProgress] reports the
  /// download fraction 0.0–1.0.
  Future<String> download(
    String fullPath, {
    void Function(double progress)? onProgress,
  }) async {
    final res = await _dio.get<String>(
      fullPath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) onProgress(received / total);
      },
    );

    final body = res.data;
    if (body == null || body.isEmpty) {
      throw const FormatException('Empty tafsir response');
    }

    return compute(_decodeTafsir, body);
  }
}

/// Top-level so it can run in a background isolate via [compute].
/// base64 → BZip2 → utf8 JSON string.
String _decodeTafsir(String base64Body) {
  final compressed = base64.decode(base64Body);
  final bytes = BZip2Decoder().decodeBytes(compressed);
  return utf8.decode(bytes);
}
