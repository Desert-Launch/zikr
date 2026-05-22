import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';

class BoxUser extends HiveBoxBase<MUser> {
  BoxUser() : super('app_user');

  MUser? current() => box.get(0);

  Future<void> save(MUser user) async {
    final existing = current();
    if (existing != null) {
      existing
        ..id = user.id
        ..name = user.name
        ..nameEn = user.nameEn
        ..email = user.email
        ..phone = user.phone
        ..avatar = user.avatar
        ..isVerified = user.isVerified
        ..createdAt = user.createdAt;
      await existing.save();
    } else {
      await box.put(0, user);
    }
  }

  Future<void> clear() async => box.clear();
}
