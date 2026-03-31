import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/dog_walk_summary.dart';
import '../../../shared/presentation/walk_theme.dart';

class DogWalkTile extends StatelessWidget {
  const DogWalkTile({super.key, required this.summary});

  final DogWalkSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = urgencyColor(summary.urgency, colorScheme);

    return GestureDetector(
      onTap: () => context.push('/dog/${summary.dogId}', extra: {
        'dogName': summary.dogName,
        'shelterId': summary.shelterId,
        'kennel': summary.kennel,
        'region': summary.region,
      }),
      child: Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored urgency bar on the left
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Dog info (left side)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  summary.dogName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (summary.shelterId.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  summary.shelterId,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              _KennelBadge(kennel: summary.kennel),
                              if (summary.region != null) ...[
                                const SizedBox(width: 4),
                                _KennelBadge(kennel: summary.region!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Walk count dots
                          _WalkDotsRow(
                            count: summary.thisWeekWalks,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                    // Stats (right side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${summary.thisWeekWalks}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _TrendIndicator(
                          trend: summary.trend,
                          lastWeekWalks: summary.lastWeekWalks,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _KennelBadge extends StatelessWidget {
  const _KennelBadge({required this.kennel});

  final String kennel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kennel.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        kennel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shows dots for walk days this week.
/// 4 dots minimum (the goal), more dots if the dog exceeded the goal.
class _WalkDotsRow extends StatelessWidget {
  const _WalkDotsRow({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goal = 4;
    final totalDots = count > goal ? count : goal;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (index) {
        final isFilled = index < count;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? color : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        );
      }),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({
    required this.trend,
    required this.lastWeekWalks,
  });

  final int trend;
  final int lastWeekWalks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trendIcon(trend),
          size: 14,
          color: trendColor(trend, colorScheme),
        ),
        const SizedBox(width: 2),
        Text(
          '$lastWeekWalks last wk',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
