import 'package:url_launcher/url_launcher.dart';

/// Small helper for opening external URLs (menu links, report-issue mailto,
/// store/app pages, map attribution links, etc.).
class Utils {
  /// Opens [url] in the platform browser / external handler.
  /// Throws if no handler can be found for the URL scheme.
  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
