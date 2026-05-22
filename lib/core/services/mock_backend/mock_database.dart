import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/modules/auth/data/models/m_user.dart';

/// In-memory mock store hydrated from `assets/mock/users.json`. Registers
/// new users (from /auth/register) so the rest of the flow can find them.
///
/// Stores plain-text "password_hash" because we're a self-contained fake.
/// In production this would be on a real backend with real hashing.
class MockDatabase {
  MockDatabase();

  final List<_MockUserRow> _users = [];
  final Map<String, String> _resetTokens = {}; // email → OTP
  bool _hydrated = false;

  Future<void> hydrate() async {
    if (_hydrated) return;
    final raw = await rootBundle.loadString('assets/mock/users.json');
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    _users.addAll(list.map(_MockUserRow.fromJson));
    _hydrated = true;
  }

  List<MUser> get users => _users.map((r) => r.toUser()).toList();

  MUser? findById(String id) {
    final hit = _users.where((u) => u.id == id);
    return hit.isEmpty ? null : hit.first.toUser();
  }

  ({MUser user, String password})? findByEmailOrPhone(String identifier) {
    final lower = identifier.toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == lower || u.phone == identifier) {
        return (user: u.toUser(), password: u.passwordHash);
      }
    }
    return null;
  }

  /// Returns the newly-created user, or null if the email is already taken.
  MUser? createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return null;
    }
    final id = 'u_${(_users.length + 1).toString().padLeft(3, '0')}';
    final row = _MockUserRow(
      id: id,
      name: name,
      nameEn: null,
      email: email,
      phone: phone,
      passwordHash: password,
      avatar: 'https://i.pravatar.cc/300?img=${30 + _users.length}',
      createdAt: DateTime.now(),
      isVerified: false,
    );
    _users.add(row);
    return row.toUser();
  }

  /// Stores an OTP for the given email and returns it. In a real backend
  /// this would be sent via email; for the mock we accept the canned value
  /// `123456` for any email so testers don't need DB inspection.
  String issueResetOtp(String email) {
    const otp = '123456';
    _resetTokens[email.toLowerCase()] = otp;
    return otp;
  }

  bool verifyResetOtp(String email, String otp) {
    return _resetTokens[email.toLowerCase()] == otp || otp == '123456';
  }

  bool resetPassword(String email, String newPassword) {
    final lower = email.toLowerCase();
    for (final u in _users) {
      if (u.email.toLowerCase() == lower) {
        u.passwordHash = newPassword;
        _resetTokens.remove(lower);
        return true;
      }
    }
    return false;
  }

  MUser? updateProfile(String id, {String? name, String? avatar}) {
    for (final u in _users) {
      if (u.id == id) {
        if (name != null) u.name = name;
        if (avatar != null) u.avatar = avatar;
        return u.toUser();
      }
    }
    return null;
  }
}

class _MockUserRow {
  _MockUserRow({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.avatar,
    required this.createdAt,
    required this.isVerified,
  });

  factory _MockUserRow.fromJson(Map<String, dynamic> j) => _MockUserRow(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        nameEn: j['name_en'] as String?,
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        passwordHash: j['password_hash'] as String? ?? '',
        avatar: j['avatar'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        isVerified: j['is_verified'] as bool? ?? false,
      );

  String id;
  String name;
  String? nameEn;
  String email;
  String phone;
  String passwordHash;
  String? avatar;
  DateTime createdAt;
  bool isVerified;

  MUser toUser() => MUser(
        id: id,
        name: name,
        nameEn: nameEn,
        email: email,
        phone: phone,
        avatar: avatar,
        isVerified: isVerified,
        createdAt: createdAt,
      );
}
