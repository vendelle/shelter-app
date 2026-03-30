import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/overview_providers.dart';
import 'widgets/dog_walk_tile.dart';
import 'widgets/stat_card.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(dogWalkSummariesProvider);
    final statsAsync = ref.watch(overviewStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(dogWalkSummariesProvider),
          ),
        ],
      ),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dogWalkSummariesProvider),
        ),
        data: (summaries) {
          // Sort: most urgent first (fewest walks this week)
          final sorted = [...summaries]
            ..sort((a, b) => a.thisWeekWalks.compareTo(b.thisWeekWalks));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dogWalkSummariesProvider);
              // Wait for the refresh to complete
              await ref.read(dogWalkSummariesProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                // Week header
                SliverToBoxAdapter(
                  child: _WeekHeader(),
                ),
                // Summary stat cards
                SliverToBoxAdapter(
                  child: statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (stats) => _StatsRow(stats: stats),
                  ),
                ),
                // Section title
                SliverToBoxAdapter(
                  child: _SectionHeader(count: sorted.length),
                ),
                // Dog walk list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return DogWalkTile(summary: sorted[index]);
                    },
                  ),
                ),
                // Bottom padding so last card isn't cut off by nav bar
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        '${_formatShortDate(monday)} – ${_formatShortDate(sunday)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final OverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Dogs',
              value: '${stats.totalDogs}',
              icon: Icons.pets_rounded,
            ),
          ),
          Expanded(
            child: StatCard(
              label: 'Walks this week',
              value: '${stats.totalWalksThisWeek}',
              icon: Icons.directions_walk_rounded,
            ),
          ),
          Expanded(
            child: StatCard(
              label: 'Need walks',
              value: '${stats.dogsNeedingWalks}',
              icon: Icons.warning_amber_rounded,
              valueColor: stats.dogsNeedingWalks > 0 ? colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            'All dogs',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Most urgent first',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
