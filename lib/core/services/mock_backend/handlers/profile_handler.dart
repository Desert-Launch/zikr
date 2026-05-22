import 'package:dio/dio.dart';
import 'package:quran/core/services/mock_backend/mock_database.dart';
import 'package:quran/core/services/mock_backend/models/m_mock_response.dart';

/// Handles `/users/profile` (GET, PATCH) against [MockDatabase]. PATCH accepts
/// `{ "name": ..., "avatar": ... }`.
class ProfileHandler {
  ProfileHandler(this._db);

  final MockDatabase _db;

  MockResponse? handle(RequestOptions options) {
    final userId = _userIdFromHeaders(options.headers);
    if (userId == null) return MockResponse.unauthorized('Not signed in');

    switch (options.method.toUpperCase()) {
      case 'GET':
        final user = _db.findById(userId);
        if (user == null) return MockResponse.notFound('User not found');
        return MockResponse.ok({'user': user.toJson()});
      case 'PATCH':
        final data = _toMap(options.data);
        final updated = _db.updateProfile(
          userId,
          name: data['name'] as String?,
          avatar: data['avatar'] as String?,
        );
        if (updated == null) return MockResponse.notFound('User not found');
        return MockResponse.ok({'user': updated.toJson()});
      default:
        return MockResponse(statusCode: 405, body: const {'error': 'Method not allowed'});
    }
  }

  String? _userIdFromHeaders(Map<String, dynamic> headers) {
    final auth = headers['Authorization']?.toString() ??
        headers['authorization']?.toString() ?? '';
    if (!auth.startsWith('Bearer ')) return null;
    final token = auth.substring(7);
    final body = token.startsWith('mockr_')
        ? token.substring(6)
        : token.startsWith('mock_')
            ? token.substring(5)
            : null;
    if (body == null) return null;
    final under = body.lastIndexOf('_');
    return under <= 0 ? null : body.substring(0, under);
  }

  Map<String, dynamic> _toMap(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }
}
