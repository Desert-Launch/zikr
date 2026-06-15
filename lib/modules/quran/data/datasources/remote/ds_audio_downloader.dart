import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Thin wrapper around Dio's download with a cancel token registry.
class DSAudioDownloader {
  DSAudioDownloader() : _dio = Dio(BaseOptions(receiveTimeout: const Duration(minutes: 5)));

  final Dio _dio;
  final Map<String, CancelToken> _tokens = {};

  /// Downloads [url] to [savePath]. The bytes land in a sibling `.tmp` file
  /// first and are renamed into place only on success, so a partially written
  /// file is never mistaken for a complete download by the disk-truth scanner.
  Future<int> downloadFile({
    required String taskId,
    required String url,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    final token = _tokens.putIfAbsent(taskId, () => CancelToken());
    final tmpPath = '$savePath.tmp';
    try {
      await _dio.download(
        url,
        tmpPath,
        cancelToken: token,
        onReceiveProgress: onProgress,
        options: Options(responseType: ResponseType.bytes, followRedirects: true),
      );
      await File(tmpPath).rename(savePath);
      return 0;
    } catch (e) {
      // Best-effort cleanup so a failed/cancelled attempt leaves no junk.
      final tmp = File(tmpPath);
      if (await tmp.exists()) {
        try {
          await tmp.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      _tokens.remove(taskId);
    }
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
