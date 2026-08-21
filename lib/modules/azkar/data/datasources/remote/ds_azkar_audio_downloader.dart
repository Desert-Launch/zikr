import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:quran/core/services/logging/app_logger.dart';

/// Outcome of one file transfer.
class AzkarDownloadResult {
  const AzkarDownloadResult({
    required this.bytes,
    required this.resumed,
    required this.cancelled,
  });

  final int bytes;

  /// True when the transfer continued an earlier partial file.
  final bool resumed;
  final bool cancelled;
}

/// Single-file downloader with resume, cancellation and atomic completion.
///
/// Both sources (hisnmuslim.com and archive.org) advertise `Accept-Ranges:
/// bytes`, so an interrupted transfer is continued with a `Range` request
/// rather than restarted — the difference between costing a user 40 MB twice
/// and costing them the remainder. If the server ignores the range and answers
/// `200` instead of `206`, the partial file is discarded and the write starts
/// from zero, which is correct but not cheap; that path is logged.
class DSAzkarAudioDownloader {
  DSAzkarAudioDownloader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
            ),
          );

  final Dio _dio;
  final Map<String, CancelToken> _tokens = <String, CancelToken>{};

  bool isActive(String taskId) => _tokens.containsKey(taskId);

  /// Streams [url] into [savePath], via `$savePath$partSuffix`.
  ///
  /// [existingBytes] is how much of the part file is already on disk; pass 0 to
  /// force a fresh transfer.
  Future<AzkarDownloadResult> download({
    required String taskId,
    required String url,
    required String savePath,
    required String partPath,
    int existingBytes = 0,
    void Function(int received, int total)? onProgress,
  }) async {
    if (_tokens.containsKey(taskId)) {
      // Never run the same file twice concurrently — a second writer would
      // interleave bytes into the same part file.
      throw StateError('Download already in flight: $taskId');
    }
    final token = CancelToken();
    _tokens[taskId] = token;
    final partFile = File(partPath);

    try {
      final resuming = existingBytes > 0;
      final response = await _dio.get<ResponseBody>(
        url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: resuming
              ? <String, String>{'Range': 'bytes=$existingBytes-'}
              : null,
          // A range request answered with 200 is still a usable response — it
          // just means the whole file is coming, so accept both.
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      final honoured = resuming && response.statusCode == 206;
      if (resuming && !honoured) {
        AppLogger.info(
          'Range ignored for $taskId (HTTP ${response.statusCode}) — '
          'restarting the file',
          tag: 'DSAzkarAudioDownloader',
        );
      }

      final headerTotal =
          int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;
      final total = honoured ? headerTotal + existingBytes : headerTotal;

      final sink = partFile.openWrite(
        mode: honoured ? FileMode.append : FileMode.write,
      );
      var received = honoured ? existingBytes : 0;
      try {
        final stream = response.data?.stream;
        if (stream == null) throw const SocketException('Empty response body');
        await for (final chunk in stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // Rename only once the body is fully written, so the canonical path is
      // never a truncated file.
      await partFile.rename(savePath);
      return AzkarDownloadResult(
        bytes: received,
        resumed: honoured,
        cancelled: false,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Leave the part file: the next run resumes from it.
        return const AzkarDownloadResult(
          bytes: 0,
          resumed: false,
          cancelled: true,
        );
      }
      rethrow;
    } finally {
      _tokens.remove(taskId);
    }
  }

  void cancel(String taskId, [String? reason]) {
    _tokens.remove(taskId)?.cancel(reason ?? 'cancelled');
  }

  void cancelAll([String? reason]) {
    for (final token in _tokens.values.toList(growable: false)) {
      token.cancel(reason ?? 'cancelled');
    }
    _tokens.clear();
  }
}
