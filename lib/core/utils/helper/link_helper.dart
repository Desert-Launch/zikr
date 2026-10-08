import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/utils/helper/app_alert.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app — a website, the mail app, a store page — and
/// reports a link nothing could open the same way everywhere.
class LinkHelper {
  LinkHelper._();

  /// Opens [uri] in whichever app handles it. When none does, shows
  /// [failureMessage] (a generic "couldn't open" by default) and returns false.
  static Future<bool> open(Uri uri, {String? failureMessage}) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      AppLogger.error('opening ${uri.scheme} link failed', error: e, stackTrace: st, tag: 'LinkHelper');
    }
    if (!opened) AppAlert.error(failureMessage ?? 'common_open_link_failed'.tr());
    return opened;
  }
}
