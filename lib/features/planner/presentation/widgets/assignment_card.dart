import 'package:flutter/material.dart';

import '../../domain/volunteer_assignment.dart';
import 'group_colors.dart';

/// A spreadsheet-style column for one volunteer's walk assignments.
/// Modeled after the Excel layout the shelter uses.
class VolunteerColumn extends StatelessWidget {
  const VolunteerColumn({
    super.key,
    required this.assignment,
    required this.onAddDog,
    required this.onRemoveDog,
    required this.onRemoveVolunteer,
    required this.onTapDog,
    required this.onEditVolunteerNote,
  });

  final VolunteerAssignment assignment;
  final VoidCallback onAddDog;
  final ValueChanged<int> onRemoveDog;
  final VoidCallback onRemoveVolunteer;
  final ValueChanged<int> onTapDog;
  final VoidCallback onEditVolunteerNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
        color: colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row — volunteer name
          GestureDetector(
            onTap: onEditVolunteerNote,
            onLongPress: onRemoveVolunteer,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Column(
                children: [
                  Text(
                    assignment.volunteerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (assignment.note != null && assignment.note!.isNotEmpty)
                    Text(
                      assignment.note!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          // Dog rows
          ...assignment.dogs.map((entry) => _DogRow(
                entry: entry,
                onRemove: () => onRemoveDog(entry.dogId),
                onTap: () => onTapDog(entry.dogId),
              )),
          // Add dog button
          InkWell(
            onTap: onAddDog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: colorScheme.outlineVariant, width: 0.5),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DogRow extends StatelessWidget {
  const _DogRow({
    required this.entry,
    required this.onRemove,
    required this.onTap,
  });

  final DogEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = groupColor(entry.groupIndex, Theme.of(context).brightness);
    final hasGroup = entry.groupIndex != null && entry.groupIndex! > 0;
    final textColor = hasGroup
        ? groupTextColor(entry.groupIndex, Theme.of(context).brightness)
        : null;

    return Dismissible(
      key: ValueKey(entry.dogId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: colorScheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded,
            size: 18, color: colorScheme.onErrorContainer),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: hasGroup ? bgColor : null,
            border: Border(
              top: BorderSide(
                  color: colorScheme.outlineVariant, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: entry.dogName),
                    if (entry.shelterId != null && entry.shelterId!.isNotEmpty)
                      TextSpan(
                        text: '  ${entry.shelterId}',
                        style: TextStyle(
                          color: hasGroup
                              ? textColor?.withValues(alpha: 0.7)
                              : colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    if (entry.kennel != null)
                      TextSpan(
                        text: '  ${entry.kennel}',
                        style: TextStyle(
                          color: hasGroup
                              ? textColor?.withValues(alpha: 0.7)
                              : colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    if (entry.region != null)
                      TextSpan(
                        text: '  ${entry.region}',
                        style: TextStyle(
                          color: hasGroup
                              ? textColor?.withValues(alpha: 0.7)
                              : colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.note != null && entry.note!.isNotEmpty)
                Text(
                  entry.note!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasGroup
                        ? textColor?.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
