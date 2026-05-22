/// A canned response the mock backend hands to Dio. The interceptor wraps
/// this in a real [Response] before resolving the request handler.
class MockResponse {
  const MockResponse({
    required this.statusCode,
    required this.body,
    this.delayMs = 0,
    this.headers = const {},
  });

  factory MockResponse.ok(Object body, {int delayMs = 0}) =>
      MockResponse(statusCode: 200, body: body, delayMs: delayMs);

  factory MockResponse.created(Object body, {int delayMs = 0}) =>
      MockResponse(statusCode: 201, body: body, delayMs: delayMs);

  factory MockResponse.noContent({int delayMs = 0}) =>
      MockResponse(statusCode: 204, body: const <String, dynamic>{}, delayMs: delayMs);

  factory MockResponse.badRequest(String message, {int delayMs = 0}) =>
      MockResponse(statusCode: 400, body: {'error': message}, delayMs: delayMs);

  factory MockResponse.unauthorized(String message, {int delayMs = 0}) =>
      MockResponse(statusCode: 401, body: {'error': message}, delayMs: delayMs);

  factory MockResponse.notFound(String message, {int delayMs = 0}) =>
      MockResponse(statusCode: 404, body: {'error': message}, delayMs: delayMs);

  factory MockResponse.conflict(String message, {int delayMs = 0}) =>
      MockResponse(statusCode: 409, body: {'error': message}, delayMs: delayMs);

  final int statusCode;
  final Object body;
  final int delayMs;
  final Map<String, dynamic> headers;
}
