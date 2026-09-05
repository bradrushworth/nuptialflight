import 'package:url_launcher/url_launcher.dart';

/// Query parameters that carry a secret and must never reach a log. Matched
/// case-insensitively against the parameter NAME.
const List<String> _secretQueryParams = <String>[
  'appid',
  'apikey',
  'api_key',
  'key',
  'token',
  'access_token',
  'password',
];

/// [url] with the value of every secret query parameter replaced by
/// `REDACTED`, safe to log.
///
/// AGENTS.md/CLAUDE.md forbid logging URLs containing `appid=`: the
/// OpenWeatherMap key is a live billable credential, and the app logs with
/// bare `print`, which survives release builds and lands in `adb logcat` /
/// Console.app on real user devices. ALWAYS log `redactUrl(url)`, never the
/// raw URL. Unparseable input is reported as `<unparseable url>` rather than
/// echoed, so a malformed URL can't leak a key either.
String redactUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return '<unparseable url>';
  if (uri.queryParameters.isEmpty) return url;
  final Map<String, String> safe = <String, String>{
    for (final MapEntry<String, String> e in uri.queryParameters.entries)
      e.key: _secretQueryParams.contains(e.key.toLowerCase())
          ? 'REDACTED'
          : e.value,
  };
  return uri.replace(queryParameters: safe).toString();
}

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
