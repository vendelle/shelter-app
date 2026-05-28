// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:http/http.dart' as http;

/// Download CSV on web — fetches data and triggers browser download via blob URL.
/// Mirrors puszek's approach: fetch → blob → anchor click.
Future<void> downloadCsv(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    // Use string body (not bodyBytes) to preserve text encoding and newlines.
    // Add UTF-8 BOM so Excel correctly detects encoding.
    final csvWithBom = '\uFEFF${response.body}';
    final blob = html.Blob([csvWithBom], 'text/csv;charset=utf-8');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute('download', 'walks_export.csv');
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(blobUrl);
  } else {
    throw Exception('Failed to download CSV: ${response.statusCode}');
  }
}
