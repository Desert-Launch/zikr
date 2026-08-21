import 'dart:convert';
import 'dart:io';

/// Minimal HTTP helpers for the import/validate scripts.
///
/// `dart:io`'s `HttpClient` only — these run under `dart run`, outside the
/// Flutter engine, and pulling a package in just for GETs is not worth it.
/// A browser-ish User-Agent is required: several of the sources sit behind
/// Cloudflare, which 403s the default Dart agent.
class HttpUtil {
  HttpUtil._();

  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  static final HttpClient _client = HttpClient()
    ..userAgent = userAgent
    ..connectionTimeout = const Duration(seconds: 30);

  static Future<String> getString(String url, {int retries = 2}) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final request = await _client.getUrl(Uri.parse(url));
        request.followRedirects = true;
        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
        }
        // The sources emit a UTF-8 BOM; `utf8.decode` keeps it as U+FEFF and
        // then `jsonDecode` chokes, so strip it here once.
        final body = await response.transform(utf8.decoder).join();
        return body.startsWith('﻿') ? body.substring(1) : body;
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw Exception('GET $url failed: $lastError');
  }

  static Future<Map<String, dynamic>> getJsonMap(String url) async =>
      Map<String, dynamic>.from(jsonDecode(await getString(url)) as Map);

  /// Result of probing a single media URL.
  static Future<UrlProbe> probe(String url) async {
    try {
      final request = await _client.headUrl(Uri.parse(url));
      request.followRedirects = true;
      final response = await request.close();
      await response.drain<void>();
      return UrlProbe(
        url: url,
        statusCode: response.statusCode,
        contentType: response.headers.contentType?.mimeType ?? '',
        contentLength: response.contentLength,
        finalUrl: '${response.redirects.isEmpty ? url : response.redirects.last.location}',
        acceptsRanges:
            (response.headers.value('accept-ranges') ?? '').contains('bytes'),
      );
    } catch (e) {
      return UrlProbe(
        url: url,
        statusCode: -1,
        contentType: '',
        contentLength: -1,
        finalUrl: url,
        acceptsRanges: false,
        error: e.toString(),
      );
    }
  }

  static void close() => _client.close(force: true);
}

class UrlProbe {
  const UrlProbe({
    required this.url,
    required this.statusCode,
    required this.contentType,
    required this.contentLength,
    required this.finalUrl,
    required this.acceptsRanges,
    this.error,
  });

  final String url;
  final int statusCode;
  final String contentType;
  final int contentLength;
  final String finalUrl;
  final bool acceptsRanges;
  final String? error;

  bool get isAudio =>
      statusCode == 200 &&
      (contentType.startsWith('audio/') ||
          contentType == 'application/octet-stream');

  bool get isRedirected => finalUrl != url;
}
