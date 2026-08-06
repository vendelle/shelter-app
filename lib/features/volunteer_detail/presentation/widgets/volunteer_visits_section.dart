import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../domain/volunteer_profile.dart';
import 'section_header.dart';

/// Visit history for the past 6 months, grouped by calendar month with a
/// per-month walk-count summary (e.g. "January 4, February 2").
class VolunteerVisitsSection extends StatelessWidget {
  const VolunteerVisitsSection({super.key, required this.profile});

  final VolunteerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VolunteerSectionHeader(
          title: l10n.visitsSectionTitle,
          caption: l10n.last6Months,
        ),
        if (profile.visits.isEmpty)
          Text(
            l10n.noVisitsInPast6Months,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.totalVisitsLabel(profile.totalVisits),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          for (final month in profile.visitsByMonth) _MonthGroup(month: month),
        ],
      ],
    );
  }
}

class _MonthGroup extends StatelessWidget {
  const _MonthGroup({required this.month});

  final MonthlyVisits month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${monthNames[month.month - 1]} ${month.year}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.walksCount(month.totalWalks),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (var i = 0; i < month.visits.length; i++)
                  _VisitRow(
                    visit: month.visits[i],
                    showDivider: i < month.visits.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, this.showDivider = true});

  final VolunteerVisit visit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Format date as dd.MM — year is already established by the month
    // group header above, so it's redundant here.
    final parts = visit.walkDate.split('-');
    final displayDate =
        parts.length == 3 ? '${parts[2]}.${parts[1]}' : visit.walkDate;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayDate, style: theme.textTheme.bodyMedium),
              Text(
                l10n.walksCount(visit.walkCount),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
