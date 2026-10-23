// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// An <img> element, like the one ShelterImage ends up using, so the request
// has the same referrer policy and lands in the same cache entry.
void preloadPhotos(Iterable<String> urls) {
  for (final url in urls) {
    html.ImageElement(src: url);
  }
}
