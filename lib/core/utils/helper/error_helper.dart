import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/utils/enums.dart';

class ErrorHelper {
  static void printDebugError({
    String message = '',
    ErrorLevels level = ErrorLevels.debug,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    switch (level) {
      case ErrorLevels.debug:
        AppLogger.debug(message, tag: name);
      case ErrorLevels.info:
        AppLogger.info(message, tag: name);
      case ErrorLevels.error:
      case ErrorLevels.critical:
        AppLogger.error(message, error: error, stackTrace: stackTrace, tag: name);
    }
  }
}
