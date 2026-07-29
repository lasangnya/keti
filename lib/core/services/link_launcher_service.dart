import 'package:url_launcher/url_launcher.dart';

/// Opens external links (the Google Forms questionnaires) in the system
/// browser. The app never embeds questionnaire content (plan §3.5).
class LinkLauncherService {
  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
