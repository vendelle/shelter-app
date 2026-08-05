import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../domain/dog_relationship.dart';
import '../relationship_colors.dart';

/// Shows a bottom sheet explaining what each relationship level means —
/// the color-coded legend volunteers already know from the shared sheet.
Future<void> showRelationshipLegend(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _RelationshipLegendSheet(),
  );
}

class _RelationshipLegendSheet extends StatelessWidget {
  const _RelationshipLegendSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Text(
                    l10n.relationshipLegendTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final level in DogRelationshipLevel.values)
                    _LegendRow(level: level),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    l10n.relationshipLegendContactNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.level});

  final DogRelationshipLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = relationshipColor(level);
    final textColor = relationshipTextColor(level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 76),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              relationshipLevelDisplayName(level, l10n),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              relationshipLevelDescription(level, l10n),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
