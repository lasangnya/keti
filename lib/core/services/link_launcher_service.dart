import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'link_launcher_service.g.dart';

@riverpod
LinkLauncherService linkLauncherService(Ref ref) => LinkLauncherService();

/// Opens external links (the Google Forms questionnaires) in the system
/// browser. The app never embeds questionnaire content (plan §3.5).
class LinkLauncherService {
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
