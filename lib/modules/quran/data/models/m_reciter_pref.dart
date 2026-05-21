import 'package:hive_ce/hive.dart';

part 'm_reciter_pref.g.dart';

/// Active reciter id + per-reciter overrides (e.g., chosen bitrate, repeat speed).
@HiveType(typeId: 13)
class MReciterPref extends HiveObject {
  MReciterPref({required this.activeReciterId, this.lastChangedAt});

  @HiveField(0)
  String activeReciterId;

  @HiveField(1)
  DateTime? lastChangedAt;
}
