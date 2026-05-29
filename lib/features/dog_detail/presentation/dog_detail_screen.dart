import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../domain/dog_relationship.dart';
import '../domain/dog_walk_history.dart';
import '../domain/walk_partner.dart';
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
              ref.invalidate(walkPartnersProvider(dogId));
              ref.invalidate(dogWalkHistoryProvider(dogId));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walkPartnersProvider(dogId));
          ref.invalidate(dogWalkHistoryProvider(dogId));
          await Future.wait([
            ref.read(walkPartnersProvider(dogId).future),
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
      if (kennel != null && kennel!.isNotEmpty) 'K: $kennel',
      if (region != null && region!.isNotEmpty) region!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

// ---------------------------------------------------------------------------
// Relationships Section
// ---------------------------------------------------------------------------

enum _PartnerSort { level, date }

class _RelationshipsSection extends ConsumerStatefulWidget {
  const _RelationshipsSection({required this.dogId});

  final int dogId;

  @override
  ConsumerState<_RelationshipsSection> createState() =>
      _RelationshipsSectionState();
}

class _RelationshipsSectionState extends ConsumerState<_RelationshipsSection> {
  _PartnerSort _sort = _PartnerSort.level;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final partnersAsync = ref.watch(walkPartnersProvider(widget.dogId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: title + sort toggle + collapse toggle
        Row(
          children: [
            Text(
              l10n.relationships,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Compact sort toggle
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _sort = _sort == _PartnerSort.level
                  ? _PartnerSort.date
                  : _PartnerSort.level),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sort == _PartnerSort.level
                          ? Icons.sort_rounded
                          : Icons.calendar_today_rounded,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _sort == _PartnerSort.level
                          ? l10n.sortByLevel
                          : l10n.sortByDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _collapsed
                    ? Icons.expand_more_rounded
                    : Icons.expand_less_rounded,
                size: 20,
              ),
              tooltip: _collapsed ? l10n.showSection : l10n.hideSection,
              onPressed: () => setState(() => _collapsed = !_collapsed),
            ),
          ],
        ),
        if (!_collapsed) ...[
          const SizedBox(height: 8),
          partnersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('${l10n.saveFailed}: $e'),
            data: (partners) {
              if (partners.isEmpty) {
                return Text(
                  l10n.noWalkPartners,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                );
              }
              final sorted = List<WalkPartner>.from(partners);
              if (_sort == _PartnerSort.level) {
                sorted.sort((a, b) {
                  final cmp = a.levelSortPriority.compareTo(b.levelSortPriority);
                  if (cmp != 0) return cmp;
                  return b.lastSharedWalk.compareTo(a.lastSharedWalk);
                });
              } else {
                sorted.sort((a, b) =>
                    b.lastSharedWalk.compareTo(a.lastSharedWalk));
              }
              return Column(
                children: sorted
                    .map((p) => _PartnerTile(
                          partner: p,
                          myDogId: widget.dogId,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PartnerTile extends ConsumerWidget {
  const _PartnerTile({required this.partner, required this.myDogId});

  final WalkPartner partner;
  final int myDogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasLevel = partner.level != null;

    // Format last walk date as dd.MM
    final parts = partner.lastSharedWalk.split('-');
    final displayDate =
        parts.length == 3 ? '${parts[2]}.${parts[1]}' : partner.lastSharedWalk;

    return InkWell(
      onTap: () => _showEditLevel(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                partner.dogName,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasLevel
                    ? relationshipColor(partner.level!)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hasLevel
                    ? relationshipLevelDisplayName(partner.level!, l10n)
                    : '?',
                style: TextStyle(
                  color: hasLevel
                      ? relationshipTextColor(partner.level!)
                      : theme.colorScheme.outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Last walk date
            Text(
              displayDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLevel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EditLevelSheet(
        myDogId: myDogId,
        otherDogId: partner.dogId,
        otherDogName: partner.dogName,
        currentLevel: partner.level,
        parentRef: ref,
      ),
    );
  }
}

class _EditLevelSheet extends ConsumerStatefulWidget {
  const _EditLevelSheet({
    required this.myDogId,
    required this.otherDogId,
    required this.otherDogName,
    required this.currentLevel,
    required this.parentRef,
  });

  final int myDogId;
  final int otherDogId;
  final String otherDogName;
  final DogRelationshipLevel? currentLevel;
  final WidgetRef parentRef;

  @override
  ConsumerState<_EditLevelSheet> createState() => _EditLevelSheetState();
}

class _EditLevelSheetState extends ConsumerState<_EditLevelSheet> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            widget.otherDogName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DogRelationshipLevel.values.map((level) {
                final isSelected = widget.currentLevel == level;
                return ActionChip(
                  avatar:
                      isSelected ? const Icon(Icons.check, size: 16) : null,
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
                  onPressed: () => _saveAndClose(level),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _saveAndClose(DogRelationshipLevel level) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(dogDetailRepositoryProvider);
      await repo.upsertRelationship(
        dogId1: widget.myDogId,
        dogId2: widget.otherDogId,
        level: level,
      );
      widget.parentRef.invalidate(walkPartnersProvider(widget.myDogId));
      widget.parentRef.invalidate(allRelationshipsProvider);
      widget.parentRef.invalidate(relationshipLookupProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _saving = false;
          _error = '${l10n.saveFailed}: $e';
        });
      }
    }
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
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(dogWalkHistoryProvider(dogId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.walkHistory3Months,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
            return Column(
              children: [
                for (var i = 0; i < walks.length; i++)
                  _WalkHistoryTile(
                    walk: walks[i],
                    showDivider: i < walks.length - 1,
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

    // Format date as dd.MM (year unnecessary for 3-month window)
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
