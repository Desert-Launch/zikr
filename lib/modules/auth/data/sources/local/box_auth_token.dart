import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/auth/data/models/m_auth_token.dart';

class BoxAuthToken extends HiveBoxBase<MAuthToken> {
  BoxAuthToken() : super('app_auth_token');

  MAuthToken? current() => box.get(0);

  Future<void> save(MAuthToken token) async {
    final existing = current();
    if (existing != null) {
      existing
        ..accessToken = token.accessToken
        ..refreshToken = token.refreshToken
        ..issuedAt = token.issuedAt;
      await existing.save();
    } else {
      await box.put(0, token);
    }
  }

  Future<void> clear() async => box.clear();
}
