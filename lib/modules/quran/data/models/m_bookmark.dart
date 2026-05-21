import 'package:hive_ce/hive.dart';

part 'm_bookmark.g.dart';

@HiveType(typeId: 10)
class MBookmark extends HiveObject {
  MBookmark({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.createdAt,
    this.note,
    this.folder,
    this.colorHex,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  int surah;

  @HiveField(2)
  int ayah;

  @HiveField(3)
  String? note;

  @HiveField(4)
  String? folder;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? colorHex;

  String get ayahKey => '$surah:$ayah';
}
