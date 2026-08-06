import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../overview/presentation/widgets/stat_card.dart';
import '../../domain/volunteer_profile.dart';
import 'section_header.dart';

/// The two top-level activity stats: average visits per month and average
/// walks per visit, both over the past 6 months.
class VolunteerStatsSection extends StatelessWidget {
  const VolunteerStatsSection({super.key, required this.profile});

  final VolunteerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VolunteerSectionHeader(
          title: l10n.statsSectionTitle,
          caption: l10n.last6Months,
        ),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.avgVisitsPerMonthLabel,
                value: profile.avgVisitsPerMonth.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: l10n.avgWalksPerVisitLabel,
                value: profile.avgWalksPerVisit.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
