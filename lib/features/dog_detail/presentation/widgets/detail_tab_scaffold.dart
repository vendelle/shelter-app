import 'package:flutter/material.dart';

/// Shared scroll container for dog-detail tabs.
///
/// Centers content within a reading-width column so it doesn't stretch
/// edge-to-edge on wide/desktop screens. On phones [maxWidth] simply exceeds
/// the viewport, so this is a no-op there — one layout serves both.
class DetailTabScaffold extends StatelessWidget {
  const DetailTabScaffold({
    super.key,
    required this.children,
    this.onRefresh,
    this.maxWidth = 680,
  });

  final List<Widget> children;

  /// When set, wraps the content in a [RefreshIndicator]. Omit for tabs with
  /// no async data to refresh (e.g. the profile tab).
  final Future<void> Function()? onRefresh;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );

    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
