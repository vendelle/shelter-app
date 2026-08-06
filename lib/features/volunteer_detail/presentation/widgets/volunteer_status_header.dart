import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../manage/presentation/widgets/volunteers_tab.dart'
    show roleColor, roleTextColor;
import '../../../shared/domain/volunteer.dart';

/// Avatar + name + role status pill, with a separate "Archived" badge when
/// the volunteer is archived (additional info, not a replacement for the
/// role color).
class VolunteerStatusHeader extends StatelessWidget {
  const VolunteerStatusHeader({super.key, required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bgColor = roleColor(volunteer.role);
    final fgColor = roleTextColor(volunteer.role);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: bgColor,
          child: Text(
            '${volunteer.firstName[0]}${volunteer.lastName[0]}',
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                volunteer.fullName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Pill(
                    label: volunteer.role.localizedLabel(l10n),
                    background: bgColor,
                    foreground: fgColor,
                  ),
                  if (volunteer.archived)
                    _Pill(
                      label: l10n.archivedBadge,
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
