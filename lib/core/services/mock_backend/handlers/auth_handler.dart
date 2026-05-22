import 'package:quran/core/services/mock_backend/mock_database.dart';
import 'package:quran/core/services/mock_backend/models/m_mock_response.dart';

/// Handles `/auth/*` endpoints against [MockDatabase]. Each method returns a
/// [MockResponse] (status + body) that the interceptor wraps into a Dio
/// [Response] before resolving the request.
class AuthHandler {
  AuthHandler(this._db);

  final MockDatabase _db;

  MockResponse login(Object? body) {
    final data = _toMap(body);
    final identifier = (data['identifier'] ?? data['email'] ?? data['phone'])?.toString() ?? '';
    final password = data['password']?.toString() ?? '';
    if (identifier.isEmpty || password.isEmpty) {
      return MockResponse.badRequest('Missing credentials');
    }
    final match = _db.findByEmailOrPhone(identifier);
    if (match == null) {
      return MockResponse.unauthorized('Invalid credentials');
    }
    if (match.password != password) {
      return MockResponse.unauthorized('Invalid credentials');
    }
    return MockResponse.ok({
      'user': match.user.toJson(),
      'access_token': _issueToken(match.user.id),
      'refresh_token': _issueRefresh(match.user.id),
    });
  }

  MockResponse register(Object? body) {
    final data = _toMap(body);
    final name = data['name']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';
    final phone = data['phone']?.toString().trim() ?? '';
    final password = data['password']?.toString() ?? '';
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return MockResponse.badRequest('Missing required fields');
    }
    if (password.length < 8) {
      return MockResponse.badRequest('Password must be at least 8 characters');
    }
    final created = _db.createUser(
      name: name, email: email, phone: phone, password: password,
    );
    if (created == null) {
      return MockResponse.conflict('Email already registered');
    }
    return MockResponse.created({
      'user': created.toJson(),
      'access_token': _issueToken(created.id),
      'refresh_token': _issueRefresh(created.id),
    });
  }

  MockResponse forgotPassword(Object? body) {
    final email = _toMap(body)['email']?.toString() ?? '';
    if (email.isEmpty) return MockResponse.badRequest('Missing email');
    // Always 200, even when the email doesn't exist (to avoid user enumeration).
    _db.issueResetOtp(email);
    return MockResponse.ok({'message': 'Reset link sent if account exists'});
  }

  MockResponse verifyOtp(Object? body) {
    final data = _toMap(body);
    final email = data['email']?.toString() ?? '';
    final otp = data['otp']?.toString() ?? '';
    if (email.isEmpty || otp.isEmpty) return MockResponse.badRequest('Missing fields');
    if (!_db.verifyResetOtp(email, otp)) {
      return MockResponse.badRequest('Invalid OTP');
    }
    return MockResponse.ok({'verified': true});
  }

  MockResponse resetPassword(Object? body) {
    final data = _toMap(body);
    final email = data['email']?.toString() ?? '';
    final otp = data['otp']?.toString() ?? '';
    final newPassword = data['new_password']?.toString() ?? '';
    if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      return MockResponse.badRequest('Missing fields');
    }
    if (newPassword.length < 8) {
      return MockResponse.badRequest('Password must be at least 8 characters');
    }
    if (!_db.verifyResetOtp(email, otp)) {
      return MockResponse.badRequest('Invalid OTP');
    }
    if (!_db.resetPassword(email, newPassword)) {
      return MockResponse.notFound('Account not found');
    }
    return MockResponse.ok({'message': 'Password updated'});
  }

  MockResponse logout(Map<String, dynamic> headers) {
    return MockResponse.noContent();
  }

  MockResponse me(Map<String, dynamic> headers) {
    final userId = _userIdFromHeaders(headers);
    if (userId == null) return MockResponse.unauthorized('Not signed in');
    final user = _db.findById(userId);
    if (user == null) return MockResponse.unauthorized('Token invalid');
    return MockResponse.ok({'user': user.toJson()});
  }

  MockResponse refresh(Object? body) {
    final refreshToken = _toMap(body)['refresh_token']?.toString() ?? '';
    final userId = _userIdFromToken(refreshToken);
    if (userId == null) return MockResponse.unauthorized('Invalid refresh token');
    return MockResponse.ok({
      'access_token': _issueToken(userId),
      'refresh_token': _issueRefresh(userId),
    });
  }

  String _issueToken(String userId) =>
      'mock_${userId}_${DateTime.now().millisecondsSinceEpoch}';
  String _issueRefresh(String userId) =>
      'mockr_${userId}_${DateTime.now().millisecondsSinceEpoch}';

  String? _userIdFromHeaders(Map<String, dynamic> headers) {
    final auth = headers['Authorization']?.toString() ??
        headers['authorization']?.toString() ?? '';
    if (!auth.startsWith('Bearer ')) return null;
    return _userIdFromToken(auth.substring(7));
  }

  String? _userIdFromToken(String token) {
    // Tokens look like `mock_<userId>_<ts>` (or `mockr_<userId>_<ts>`).
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
