import 'package:url_launcher/url_launcher.dart';

/// Download CSV on non-web platforms (mobile) — opens in external browser.
Future<void> downloadCsv(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
