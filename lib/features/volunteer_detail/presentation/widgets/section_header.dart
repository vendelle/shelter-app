import 'package:flutter/material.dart';

/// "Title · caption" header used above each section of the volunteer
/// profile (e.g. "Dogs walked most often · last 90 days").
class VolunteerSectionHeader extends StatelessWidget {
  const VolunteerSectionHeader({super.key, required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          children: [
            TextSpan(text: title),
            if (caption != null)
              TextSpan(
                text: '  ·  $caption',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
