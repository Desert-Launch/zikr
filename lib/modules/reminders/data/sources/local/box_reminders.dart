import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/reminders/data/models/m_reminder.dart';

class BoxReminders extends HiveBoxBase<MReminder> {
  BoxReminders() : super('reminders');

  List<MReminder> all() => box.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  int get count => box.length;

  Future<void> upsert(MReminder reminder) async {
    await box.put(reminder.id, reminder);
  }

  Future<void> delete(String id) async => box.delete(id);

  MReminder? byId(String id) => box.get(id);
}
