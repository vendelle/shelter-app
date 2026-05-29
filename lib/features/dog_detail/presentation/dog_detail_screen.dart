import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../manage/presentation/providers/manage_providers.dart';
import '../domain/dog_relationship.dart';
import '../domain/dog_walk_history.dart';
import 'providers/dog_detail_providers.dart';
import 'relationship_colors.dart';

class DogDetailScreen extends ConsumerWidget {
  const DogDetailScreen({
    super.key,
    required this.dogId,
    required this.dogName,
    this.shelterId,
    this.kennel,
    this.region,
  });

  final int dogId;
  final String dogName;
  final String? shelterId;
  final String? kennel;
  final String? region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dogName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(dogRelationshipsProvider(dogId));
              ref.invalidate(dogWalkHistoryProvider(dogId));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dogRelationshipsProvider(dogId));
          ref.invalidate(dogWalkHistoryProvider(dogId));
          await Future.wait([
            ref.read(dogRelationshipsProvider(dogId).future),
            ref.read(dogWalkHistoryProvider(dogId).future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DogInfoHeader(
              dogName: dogName,
              shelterId: shelterId,
              kennel: kennel,
              region: region,
            ),
            const SizedBox(height: 24),
            _RelationshipsSection(dogId: dogId),
            const SizedBox(height: 24),
            _WalkHistorySection(dogId: dogId),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dog Info Header
// ---------------------------------------------------------------------------

class _DogInfoHeader extends StatelessWidget {
  const _DogInfoHeader({
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
      if (shelterId != null && shelterId!.isNotEmpty) shelterId!,
      if (kennel != null && kennel!.isNotEmpty) 'K: $kennel',
      if (region != null && region!.isNotEmpty) region!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dogName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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

// ---------------------------------------------------------------------------
// Relationships Section
// ---------------------------------------------------------------------------

class _RelationshipsSection extends ConsumerWidget {
  const _RelationshipsSection({required this.dogId});

  final int dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final relAsync = ref.watch(dogRelationshipsProvider(dogId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Relationships',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'Add relationship',
              onPressed: () => _showAddRelationship(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        relAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (relationships) {
            if (relationships.isEmpty) {
              return Text(
                'No relationships recorded',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            return Column(
              children: relationships.map((r) {
                return _RelationshipTile(
                  relationship: r,
                  myDogId: dogId,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showAddRelationship(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddRelationshipSheet(dogId: dogId, parentRef: ref),
    );
  }
}

class _AddRelationshipSheet extends ConsumerStatefulWidget {
  const _AddRelationshipSheet({required this.dogId, required this.parentRef});

  final int dogId;
  final WidgetRef parentRef;

  @override
  ConsumerState<_AddRelationshipSheet> createState() =>
      _AddRelationshipSheetState();
}

class _AddRelationshipSheetState extends ConsumerState<_AddRelationshipSheet> {
  int? _selectedDogId;
  String? _selectedDogName;
  DogRelationshipLevel? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dogsAsync = ref.watch(managedDogsProvider);
    final existingRelsAsync =
        ref.watch(dogRelationshipsProvider(widget.dogId));
    final existingDogIds = existingRelsAsync.valueOrNull
            ?.map((r) => r.otherDogId(widget.dogId))
            .toSet() ??
        {};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Add relationship',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_selectedDogId == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Select a dog',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            Expanded(
              child: dogsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (dogs) {
                  final available = dogs
                      .where((d) =>
                          d.id != widget.dogId &&
                          !existingDogIds.contains(d.id))
                      .toList();
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final dog = available[index];
                      return ListTile(
                        dense: true,
                        title: Text(dog.name),
                        subtitle: Text(
                            [dog.shelterId, dog.kennel, dog.region]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(' · ')),
                        onTap: () => setState(() {
                          _selectedDogId = dog.id;
                          _selectedDogName = dog.name;
                        }),
                      );
                    },
                  );
                },
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Dog: $_selectedDogName',
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedDogId = null;
                          _selectedDogName = null;
                          _selectedLevel = null;
                        }),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Select level',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DogRelationshipLevel.values.map((level) {
                      final isSelected = _selectedLevel == level;
                      return ActionChip(
                        avatar: isSelected
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        label: Text(relationshipLevelDisplayName(level)),
                        backgroundColor: relationshipColor(level),
                        labelStyle: TextStyle(
                          color: relationshipTextColor(level),
                          fontWeight: FontWeight.w600,
                        ),
                        side: isSelected
                            ? BorderSide(
                                color: relationshipTextColor(level), width: 2)
                            : BorderSide.none,
                        onPressed: () =>
                            setState(() => _selectedLevel = level),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedLevel == null
                          ? null
                          : () async {
                              final repo =
                                  ref.read(dogDetailRepositoryProvider);
                              await repo.upsertRelationship(
                                dogId1: widget.dogId,
                                dogId2: _selectedDogId!,
                                level: _selectedLevel!,
                              );
                              widget.parentRef.invalidate(
                                  dogRelationshipsProvider(widget.dogId));
                              widget.parentRef
                                  .invalidate(allRelationshipsProvider);
                              widget.parentRef
                                  .invalidate(relationshipLookupProvider);
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  const _RelationshipTile({
    required this.relationship,
    required this.myDogId,
  });

  final DogRelationship relationship;
  final int myDogId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherName = relationship.otherDogName(myDogId);
    final color = relationshipColor(relationship.level);
    final textColor = relationshipTextColor(relationship.level);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Text(otherName),
        subtitle: relationship.notes != null
            ? Text(
                relationship.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            relationshipLevelDisplayName(relationship.level),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _showRelationshipDetail(context),
      ),
    );
  }

  void _showRelationshipDetail(BuildContext context) {
    final otherId = relationship.otherDogId(myDogId);
    final otherName = relationship.otherDogName(myDogId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RelationshipDetailSheet(
        dogId: myDogId,
        otherDogId: otherId,
        otherDogName: otherName,
        level: relationship.level,
        notes: relationship.notes,
      ),
    );
  }
}

class _RelationshipDetailSheet extends ConsumerWidget {
  const _RelationshipDetailSheet({
    required this.dogId,
    required this.otherDogId,
    required this.otherDogName,
    required this.level,
    this.notes,
  });

  final int dogId;
  final int otherDogId;
  final String otherDogName;
  final DogRelationshipLevel level;
  final String? notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = relationshipColor(level);
    final textColor = relationshipTextColor(level);

    // Get walk history for both dogs to find shared walks
    final myHistoryAsync = ref.watch(dogWalkHistoryProvider(dogId));
    final otherHistoryAsync = ref.watch(dogWalkHistoryProvider(otherDogId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      otherDogName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      relationshipLevelDisplayName(level),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Walks together',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildSharedWalks(
                  context,
                  myHistoryAsync,
                  otherHistoryAsync,
                  scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedWalks(
    BuildContext context,
    AsyncValue<List<DogWalkHistory>> myAsync,
    AsyncValue<List<DogWalkHistory>> otherAsync,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);

    if (myAsync is AsyncLoading || otherAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (myAsync is AsyncError) return Text('Error: ${myAsync.error}');
    if (otherAsync is AsyncError) return Text('Error: ${otherAsync.error}');

    final myWalks = myAsync.valueOrNull ?? [];

    // Find walks where the other dog was in the same group
    final sharedWalks = myWalks.where((w) {
      return w.groupDogs.any((g) => g.dogId == otherDogId);
    }).toList();

    if (sharedWalks.isEmpty) {
      return Text(
        'No shared walks recorded',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: sharedWalks.length,
      itemBuilder: (context, index) {
        final walk = sharedWalks[index];
        final allGroupNames =
            walk.groupDogs.map((g) => g.dogName).join(', ');
        final dateParts = walk.walkDate.split('-');
        final displayDate = dateParts.length == 3
            ? '${dateParts[2]}.${dateParts[1]}.${dateParts[0]}'
            : walk.walkDate;

        return ListTile(
          dense: true,
          title: Text(displayDate),
          subtitle: Text(
            [
              if (walk.volunteerName != null) walk.volunteerName!,
              if (allGroupNames.isNotEmpty) 'Group: $allGroupNames',
            ].join(' · '),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Walk History Section
// ---------------------------------------------------------------------------

class _WalkHistorySection extends ConsumerWidget {
  const _WalkHistorySection({required this.dogId});

  final int dogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(dogWalkHistoryProvider(dogId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Walk history (3 months)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (walks) {
            if (walks.isEmpty) {
              return Text(
                'No walks in the past 3 months',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            return Column(
              children: walks
                  .map((w) => _WalkHistoryTile(walk: w))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _WalkHistoryTile extends StatelessWidget {
  const _WalkHistoryTile({required this.walk});

  final DogWalkHistory walk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupNames =
        walk.groupDogs.map((g) => g.dogName).join(', ');
    // Format date as dd.MM.yyyy
    final parts = walk.walkDate.split('-');
    final displayDate = parts.length == 3
        ? '${parts[2]}.${parts[1]}.${parts[0]}'
        : walk.walkDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Text(displayDate),
        subtitle: Text(
          [
            if (walk.volunteerName != null) walk.volunteerName!,
            if (groupNames.isNotEmpty) 'with $groupNames',
            if (walk.notes != null && walk.notes!.isNotEmpty) walk.notes!,
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: walk.groupIndex != null && walk.groupIndex! > 0
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'G${walk.groupIndex}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
