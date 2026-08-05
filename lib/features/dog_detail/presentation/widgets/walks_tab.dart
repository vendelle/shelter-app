import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../domain/dog_walk_history.dart';
import '../providers/dog_detail_providers.dart';
import 'detail_tab_scaffold.dart';

const _maxWalksShown = 20;

/// The most recent walks for a dog, capped to the last [_maxWalksShown].
/// Least-important tab of the dog detail view, so kept short by design.
class WalksTab extends ConsumerWidget {
  const WalksTab({super.key, required this.dogId});

  final int dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(dogWalkHistoryProvider(dogId));

    return DetailTabScaffold(
      onRefresh: () async {
        ref.invalidate(dogWalkHistoryProvider(dogId));
        await ref.read(dogWalkHistoryProvider(dogId).future);
      },
      children: [
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${l10n.saveFailed}: $e'),
          data: (walks) {
            if (walks.isEmpty) {
              return Text(
                l10n.noWalksInPast3Months,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            final shown = walks.take(_maxWalksShown).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    l10n.last20Walks,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                for (var i = 0; i < shown.length; i++)
                  _WalkHistoryTile(
                    walk: shown[i],
                    showDivider: i < shown.length - 1,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WalkHistoryTile extends StatelessWidget {
  const _WalkHistoryTile({required this.walk, this.showDivider = true});

  final DogWalkHistory walk;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Format date as dd.MM (year unnecessary for recent walks)
    final parts = walk.walkDate.split('-');
    final displayDate = parts.length == 3
        ? '${parts[2]}.${parts[1]}'
        : walk.walkDate;

    // Truncate group dogs: show up to 3 names, then "+N more"
    final dogs = walk.groupDogs;
    String? groupLine;
    if (dogs.isNotEmpty) {
      if (dogs.length <= 3) {
        groupLine = l10n.withDogs(dogs.map((g) => g.dogName).join(', '));
      } else {
        final shown = dogs.take(3).map((g) => g.dogName).join(', ');
        groupLine = l10n.withDogsAndMore(shown, dogs.length - 3);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date · Volunteer on one line
              Row(
                children: [
                  Text(
                    displayDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (walk.volunteerName != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·',
                          style: TextStyle(color: theme.colorScheme.outline)),
                    ),
                    Expanded(
                      child: Text(
                        walk.volunteerName!,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              // Group dogs (if any)
              if (groupLine != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 0),
                  child: Text(
                    groupLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              // Notes (if any)
              if (walk.notes != null && walk.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    walk.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
