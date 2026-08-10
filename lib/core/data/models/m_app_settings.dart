import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_app_settings.g.dart';

/// App-wide settings persisted as a single Hive record (key = 0).
/// Holds first-run flags and other boot-relevant state that doesn't fit a
/// feature module's box.
@HiveType(typeId: HiveTypeIds.appSettings)
class MAppSettings extends HiveObject {
  MAppSettings({
    this.hasSeenOnboarding = false,
    this.lastLanguageCode,
    this.hasGrantedLocation = false,
    this.initNotificationsScheduled = false,
    this.hourlyTasbihSeeded = false,
  });

  @HiveField(0)
  bool hasSeenOnboarding;

  @HiveField(1)
  String? lastLanguageCode;

  @HiveField(2)
  bool hasGrantedLocation;

  /// First-run guard: true once the init_notifications.json feed (azkar +
  /// quran reminders) has been scheduled, so it isn't re-seeded on every boot.
  /// Reset by `InitNotificationsService.resetAndReschedule`.
  @HiveField(3)
  bool initNotificationsScheduled;

  /// One-time guard for the hourly tasbih default-on seed. The feature shipped
  /// off by default, so installs from before that change carry an explicit
  /// `false` on disk that the new model default can't reach — see
  /// `DSHourlyTasbih.seedDefaultIfNeeded`. Set once, so a user who later
  /// switches the reminder off is never flipped back on.
  @HiveField(4)
  bool hourlyTasbihSeeded;
}
