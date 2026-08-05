import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../domain/dog_relationship.dart';
import '../../domain/walk_partner.dart';
import '../providers/dog_detail_providers.dart';
import '../relationship_colors.dart';
import 'detail_tab_scaffold.dart';
import 'relationship_legend_sheet.dart';

enum _PartnerSort { level, date }

class RelationshipsTab extends ConsumerStatefulWidget {
  const RelationshipsTab({super.key, required this.dogId});

  final int dogId;

  @override
  ConsumerState<RelationshipsTab> createState() => _RelationshipsTabState();
}

class _RelationshipsTabState extends ConsumerState<RelationshipsTab> {
  _PartnerSort _sort = _PartnerSort.level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final partnersAsync = ref.watch(walkPartnersProvider(widget.dogId));

    return DetailTabScaffold(
      onRefresh: () async {
        ref.invalidate(walkPartnersProvider(widget.dogId));
        await ref.read(walkPartnersProvider(widget.dogId).future);
      },
      children: [
        // Legend + sort toggle
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              tooltip: l10n.relationshipLegendTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () => showRelationshipLegend(context),
            ),
            const Spacer(),
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
          ],
        ),
        const SizedBox(height: 4),
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
              sorted.sort(
                  (a, b) => b.lastSharedWalk.compareTo(a.lastSharedWalk));
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
          Row(
            children: [
              Text(
                widget.otherDogName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, size: 20),
                tooltip: l10n.relationshipLegendTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () => showRelationshipLegend(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
