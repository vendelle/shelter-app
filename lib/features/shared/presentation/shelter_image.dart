import 'package:flutter/material.dart';

/// A photo hosted on the shelter's website.
class ShelterImage extends StatelessWidget {
  const ShelterImage(this.url, {super.key, required this.fit, this.error});

  final String url;
  final BoxFit fit;

  /// Shown when the photo doesn't load; nothing by default.
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      // The shelter's image server sends no CORS headers, which Flutter web
      // needs to draw fetched bytes — an <img> element doesn't.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => error ?? const SizedBox.shrink(),
    );
  }
}
