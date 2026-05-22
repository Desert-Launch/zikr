import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_user.g.dart';

/// Authenticated user record. Persisted in `BoxUser` (single record, key=0).
@HiveType(typeId: HiveTypeIds.user)
class MUser extends HiveObject {
  MUser({
    required this.id,
    required this.name,
    required this.email,
    this.nameEn,
    this.phone,
    this.avatar,
    this.isVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MUser.fromJson(Map<String, dynamic> json) => MUser(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String?,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        avatar: json['avatar'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? nameEn;
  @HiveField(3)
  String email;
  @HiveField(4)
  String? phone;
  @HiveField(5)
  String? avatar;
  @HiveField(6)
  bool isVerified;
  @HiveField(7)
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameEn != null) 'name_en': nameEn,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}
