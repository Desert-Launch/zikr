import 'dart:async';

import 'package:dio/dio.dart';

/// Thin wrapper around Dio's download with a cancel token registry.
class DSAudioDownloader {
  DSAudioDownloader() : _dio = Dio(BaseOptions(receiveTimeout: const Duration(minutes: 5)));

  final Dio _dio;
  final Map<String, CancelToken> _tokens = {};

  Future<int> downloadFile({
    required String taskId,
    required String url,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    final token = _tokens.putIfAbsent(taskId, () => CancelToken());
    await _dio.download(
      url,
      savePath,
      cancelToken: token,
      onReceiveProgress: onProgress,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    return 0;
  }

  void cancel(String taskId, [String? reason]) {
    final token = _tokens.remove(taskId);
    token?.cancel(reason ?? 'cancelled');
  }

  bool isActive(String taskId) => _tokens.containsKey(taskId);

  void disposeAll() {
    for (final t in _tokens.values) {
      t.cancel('disposed');
    }
    _tokens.clear();
  }
}
