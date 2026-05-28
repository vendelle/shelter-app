// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:http/http.dart' as http;

/// Download CSV on web — fetches data and triggers browser download via blob URL.
Future<void> downloadCsv(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final blob = html.Blob([response.bodyBytes], 'text/csv');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: blobUrl)
      ..setAttribute('download', 'walks_export.csv')
      ..click();
    html.Url.revokeObjectUrl(blobUrl);
  } else {
    throw Exception('Failed to download CSV: ${response.statusCode}');
  }
}
