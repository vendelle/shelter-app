import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/domain/shelter_link.dart';
import 'detail_tab_scaffold.dart';

/// General profile info for a dog: name, shelter ID, kennel, region.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.dogName,
    this.shelterId,
    this.kennel,
    this.region,
  });

  final String dogName;
  final String? shelterId;
  final String? kennel;
  final String? region;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chips = <String>[
      if (kennel != null && kennel!.isNotEmpty) 'K: $kennel',
      if (region != null && region!.isNotEmpty) region!,
    ];
    final shelterUrl = buildShelterUrl(shelterId);

    return DetailTabScaffold(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              dogName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (shelterId != null && shelterId!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                shelterId!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: chips
                .map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
        if (shelterUrl != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            // TEMPORARY diagnostic: report what actually happens on tap
            // (tap registers? launchUrl throws? returns false?) since the
            // real failure mode isn't visible from the deployed preview.
            // Remove once we know the root cause.
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('tapped — launching…')),
              );
              try {
                final launched = await launchUrl(
                  Uri.parse(shelterUrl),
                  mode: LaunchMode.externalApplication,
                );
                messenger.showSnackBar(
                  SnackBar(content: Text('launchUrl returned: $launched')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('launchUrl threw: $e')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l10n.shelterWebsiteLink),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}
