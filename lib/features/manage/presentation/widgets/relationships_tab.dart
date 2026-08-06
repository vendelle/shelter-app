import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../dog_detail/domain/dog_relationship.dart';
import '../../../dog_detail/presentation/providers/dog_detail_providers.dart';
import '../../../dog_detail/presentation/relationship_colors.dart';
import '../../../shared/domain/dog.dart';
import '../providers/manage_providers.dart';

class RelationshipsTab extends ConsumerWidget {
  const RelationshipsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(managedDogsProvider);
    final relsAsync = ref.watch(allRelationshipsProvider);

    return dogsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (dogs) => relsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rels) {
          if (dogs.isEmpty) {
            return const Center(child: Text('No dogs found'));
          }
          return _RelationshipMatrix(dogs: dogs, relationships: rels);
        },
      ),
    );
  }
}

class _RelationshipMatrix extends StatelessWidget {
  const _RelationshipMatrix({
    required this.dogs,
    required this.relationships,
  });

  final List<Dog> dogs;
  final List<DogRelationship> relationships;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Build lookup map
    final lookup = <(int, int), DogRelationship>{};
    for (final r in relationships) {
      final key = r.dogId1 < r.dogId2
          ? (r.dogId1, r.dogId2)
          : (r.dogId2, r.dogId1);
      lookup[key] = r;
    }

    const cellSize = 40.0;
    const headerWidth = 90.0;

    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: DogRelationshipLevel.values.map((level) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: relationshipColor(level),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  relationshipLevelDisplayName(level, l10n),
                  style: TextStyle(
                    color: relationshipTextColor(level),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Matrix
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column header row
                  Row(
                    children: [
                      SizedBox(width: headerWidth, height: cellSize),
                      ...dogs.map((dog) => SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  dog.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  // Data rows
                  ...dogs.asMap().entries.map((rowEntry) {
                    final rowIdx = rowEntry.key;
                    final rowDog = rowEntry.value;
                    return Row(
                      children: [
                        // Row header
                        SizedBox(
                          width: headerWidth,
                          height: cellSize,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rowDog.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        // Cells
                        ...dogs.asMap().entries.map((colEntry) {
                          final colIdx = colEntry.key;
                          final colDog = colEntry.value;

                          if (rowIdx == colIdx) {
                            // Diagonal — same dog
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 0.5,
                                ),
                              ),
                            );
                          }

                          final key = rowDog.id < colDog.id
                              ? (rowDog.id, colDog.id)
                              : (colDog.id, rowDog.id);
                          final rel = lookup[key];

                          return _MatrixCell(
                            cellSize: cellSize,
                            relationship: rel,
                            dog1: rowDog,
                            dog2: colDog,
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixCell extends ConsumerWidget {
  const _MatrixCell({
    required this.cellSize,
    required this.relationship,
    required this.dog1,
    required this.dog2,
  });

  final double cellSize;
  final DogRelationship? relationship;
  final Dog dog1;
  final Dog dog2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = relationship != null
        ? relationshipColor(relationship!.level)
        : null;

    return GestureDetector(
      onTap: () => _showLevelPicker(context, ref),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: bgColor ?? colorScheme.surface,
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: relationship != null
            ? Center(
                child: Text(
                  _shortLabel(relationship!.level),
                  style: TextStyle(
                    color: relationshipTextColor(relationship!.level),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _shortLabel(DogRelationshipLevel level) {
    return switch (level) {
      DogRelationshipLevel.yard => 'Y',
      DogRelationshipLevel.contactGood => 'C+',
      DogRelationshipLevel.contactCaution => 'C-',
      DogRelationshipLevel.parallelGood => 'P+',
      DogRelationshipLevel.parallelCaution => 'P-',
      DogRelationshipLevel.incompatible => 'X',
    };
  }

  void _showLevelPicker(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dog1.name} ↔ ${dog2.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...DogRelationshipLevel.values.map((level) {
                      final isSelected = relationship?.level == level;
                      return ActionChip(
                        avatar: isSelected
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        label: Text(relationshipLevelDisplayName(level, l10n)),
                        backgroundColor: relationshipColor(level),
                        labelStyle: TextStyle(
                          color: relationshipTextColor(level),
                          fontWeight: FontWeight.w600,
                        ),
                        side: isSelected
                            ? BorderSide(
                                color: relationshipTextColor(level), width: 2)
                            : BorderSide.none,
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final repo = ref.read(dogDetailRepositoryProvider);
                          await repo.upsertRelationship(
                            dogId1: dog1.id,
                            dogId2: dog2.id,
                            level: level,
                          );
                          ref.invalidate(allRelationshipsProvider);
                          ref.invalidate(relationshipLookupProvider);
                        },
                      );
                    }),
                    if (relationship != null)
                      ActionChip(
                        avatar: Icon(Icons.delete_outline,
                            size: 16, color: theme.colorScheme.error),
                        label: Text('Remove',
                            style: TextStyle(color: theme.colorScheme.error)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final repo = ref.read(dogDetailRepositoryProvider);
                          await repo.deleteRelationship(dog1.id, dog2.id);
                          ref.invalidate(allRelationshipsProvider);
                          ref.invalidate(relationshipLookupProvider);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
