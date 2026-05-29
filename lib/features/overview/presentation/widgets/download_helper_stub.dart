import 'package:url_launcher/url_launcher.dart';

/// Download CSV on non-web platforms (mobile) — opens in external browser.
Future<void> downloadCsv(String url) async {
  final uri = Uri.parse(url);
  final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('Could not launch CSV download URL: $url');
  }
}
