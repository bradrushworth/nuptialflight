import 'package:url_launcher/url_launcher.dart';

/// Small helper for opening external URLs (menu links, report-issue mailto,
/// store/app pages, map attribution links, etc.).
///
/// NOTE: `canLaunch` / `launch` are part of the older `url_launcher` surface
/// and are now deprecated in favour of `canLaunchUrl` / `launchUrl`. They still
/// work and are used here to avoid a broad package upgrade (see .clinerules);
/// if `url_launcher` is bumped, migrate this method too.
class Utils {
  /// Opens [url] in the platform browser / external handler.
  /// Throws if no handler can be found for the URL scheme.
  static void launchURL(String url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
}