import 'package:hive_ce/hive.dart';

part 'm_last_read.g.dart';

@HiveType(typeId: 11)
class MLastRead extends HiveObject {
  MLastRead({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.updatedAt,
  });

  @HiveField(0)
  int surah;

  @HiveField(1)
  int ayah;

  @HiveField(2)
  int page;

  @HiveField(3)
  DateTime updatedAt;
}
