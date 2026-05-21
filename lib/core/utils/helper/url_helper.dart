import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static void lunch(String url) async {
    Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
