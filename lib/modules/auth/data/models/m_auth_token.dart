import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_auth_token.g.dart';

@HiveType(typeId: HiveTypeIds.authToken)
class MAuthToken extends HiveObject {
  MAuthToken({
    required this.accessToken,
    required this.refreshToken,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt ?? DateTime.now();

  factory MAuthToken.fromJson(Map<String, dynamic> json) => MAuthToken(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
      );

  @HiveField(0)
  String accessToken;
  @HiveField(1)
  String refreshToken;
  @HiveField(2)
  DateTime issuedAt;

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'issued_at': issuedAt.toIso8601String(),
      };
}
