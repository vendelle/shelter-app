import 'package:flutter/material.dart';

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
    final chips = <String>[
      if (kennel != null && kennel!.isNotEmpty) 'K: $kennel',
      if (region != null && region!.isNotEmpty) region!,
    ];

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
      ],
    );
  }
}
