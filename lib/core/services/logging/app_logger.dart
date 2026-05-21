import 'package:talker_flutter/talker_flutter.dart';

/// Central logging facade backed by a Talker instance.
class AppLogger {
  AppLogger._();

  static Talker? _talker;

  static Talker? get talker => _talker;

  static void init() {
    _talker = TalkerFlutter.init();
  }

  static void debug(String message, {String? tag}) {
    final formatted = tag != null ? '[$tag] $message' : message;
    _talker?.debug(formatted);
  }

  static void info(String message, {String? tag}) {
    final formatted = tag != null ? '[$tag] $message' : message;
    _talker?.info(formatted);
  }

  static void warning(String message, {String? tag}) {
    final formatted = tag != null ? '[$tag] $message' : message;
    _talker?.warning(formatted);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    final formatted = tag != null ? '[$tag] $message' : message;
    if (error != null) {
      _talker?.handle(error, stackTrace, formatted);
    } else {
      _talker?.error(formatted);
    }
  }
}
