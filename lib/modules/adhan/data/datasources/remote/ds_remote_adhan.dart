import 'dart:io';

import 'package:dio/dio.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/network/end_points.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';

/// Fetches the adhan voice catalog and downloads full-adhan files. Uses its
/// OWN [Dio] (not the shared [BaseDio]) so the app's Authorization header and
/// mock interceptor never touch the CDN. Lets exceptions bubble — the repo
/// converts them to [Failure].
class DSRemoteAdhan {
  DSRemoteAdhan()
      : _dio = Dio(BaseOptions(
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        ));

  final Dio _dio;

  /// GETs the catalog JSON and returns its `voices` array as [MAdhan]s.
  Future<List<MAdhan>> fetchCatalog() async {
    final res = await _dio.get<Map<String, dynamic>>(EndPoints.adhanCatalog);
    final body = res.data ?? const {};
    final voices = (body['voices'] as List?) ?? const [];
    return voices
        .map((e) => MAdhan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  /// Downloads [url] to [savePath], reporting progress, and resumes an
  /// interrupted transfer when possible.
  ///
  /// Bytes stream into a sibling `<savePath>.part` file; a previous partial is
  /// continued via a `Range: bytes=<offset>-` request. If the server honours it
  /// (HTTP 206) we append, otherwise (200) we restart from zero. The `.part`
  /// is promoted to [savePath] only after the stream completes, so a crash mid-
  /// download never leaves a truncated file at the final path.
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final partFile = File('$savePath.part');
    var existing = await partFile.exists() ? await partFile.length() : 0;

    final response = await _dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        headers: existing > 0 ? {'range': 'bytes=$existing-'} : null,
        // 206 = partial (resume accepted), 200 = full body (range ignored).
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    final resumed = response.statusCode == 206;
    if (!resumed) existing = 0; // server ignored the range → start over.

    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty download response',
      );
    }

    final contentLength =
        int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
    final total = contentLength <= 0 ? 0 : existing + contentLength;

    final sink = partFile.openWrite(
      mode: resumed ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
    var received = existing;
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null && total > 0) onProgress(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final target = File(savePath);
    if (await target.exists()) await target.delete();
    await partFile.rename(savePath);
  }
}
