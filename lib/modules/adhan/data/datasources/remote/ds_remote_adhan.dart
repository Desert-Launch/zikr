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

  /// Downloads [url] to [savePath], reporting progress. Resumable downloads
  /// are out of scope for v1; a failed download leaves a partial file the repo
  /// is responsible for deleting.
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
