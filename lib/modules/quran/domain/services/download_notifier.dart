/// Port that the download repository uses to surface progress to the OS
/// notification tray, without the data layer depending on the notification
/// implementation directly (the impl lives in the presentation layer).
abstract class DownloadNotifier {
  /// Called as a surah's ayat land on disk. [onDisk] is the count present now
  /// (already-there + freshly downloaded), out of [total].
  void notifySurahProgress({
    required int surah,
    required int onDisk,
    required int total,
  });

  /// Called when no downloads remain active — dismiss any progress notification.
  void notifyIdle();
}
