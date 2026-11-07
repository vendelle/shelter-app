import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dog_detail/presentation/providers/dog_detail_providers.dart';
import '../../../shared/domain/dog.dart';
import '../../../shared/presentation/shelter_image.dart';
import '../../../shared/domain/volunteer.dart';
import '../../../planner/domain/planner_dog.dart';
import '../familiarity_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../providers/manage_providers.dart';

class FamiliarityDialog extends ConsumerStatefulWidget {
  const FamiliarityDialog({
    super.key,
    required this.volunteer,
    this.intro,
    this.onRemindLater,
  });

  final Volunteer volunteer;

  /// Shown above the legend, e.g. to ask for the missing ratings.
  final String? intro;

  /// When set, the dialog offers "remind me later" next to Close and calls
  /// this when it's picked.
  final VoidCallback? onRemindLater;

  @override
  ConsumerState<FamiliarityDialog> createState() => _FamiliarityDialogState();
}

class _FamiliarityDialogState extends ConsumerState<FamiliarityDialog> {
  // Local cache of changes so UI updates instantly
  final Map<int, DogFamiliarityLevel> _localChanges = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final dogsAsync = ref.watch(managedDogsProvider);
    final familiarityAsync =
        ref.watch(familiarityProvider(widget.volunteer.id));
    final photos = ref.watch(dogPhotoUrlsProvider).valueOrNull ?? const {};
    // Everyone can look; only the volunteer themself or an admin can change.
    final canEdit = ref
        .watch(permissionsProvider)
        .canEditFamiliarityOf(widget.volunteer.id);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.dogFamiliarity(widget.volunteer.fullName)),
      content: SizedBox(
        width: double.maxFinite,
        height: 460,
        child: Column(
          children: [
            if (widget.intro != null) ...[
              Text(widget.intro!),
              const SizedBox(height: 12),
            ],
            const _FamiliarityLegend(),
            const SizedBox(height: 8),
            Expanded(
              child: dogsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (dogs) {
                  final activeDogs = dogs.where((d) => !d.archived).toList();
                  return familiarityAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (familiarityMap) {
                      return ListView.builder(
                        itemCount: activeDogs.length,
                        itemBuilder: (context, index) {
                          final dog = activeDogs[index];
                          final level = _localChanges[dog.id] ??
                              familiarityMap[dog.id] ??
                              DogFamiliarityLevel.unknown;
                          return _DogFamiliarityRow(
                            dog: dog,
                            photoUrl: photos[dog.id],
                            level: level,
                            onChanged: canEdit
                                ? (newLevel) =>
                                    _onLevelChanged(dog.id, newLevel)
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onRemindLater != null)
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    widget.onRemindLater!();
                    Navigator.pop(context);
                  },
            child: Text(AppLocalizations.of(context)!.familiarityRemindLater),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  Future<void> _onLevelChanged(
      int dogId, DogFamiliarityLevel newLevel) async {
    setState(() {
      _localChanges[dogId] = newLevel;
      _saving = true;
    });

    try {
      final repo = ref.read(manageRepositoryProvider);
      if (newLevel == DogFamiliarityLevel.unknown) {
        await repo.removeFamiliarity(
          volunteerId: widget.volunteer.id,
          dogId: dogId,
        );
      } else {
        await repo.setFamiliarity(
          volunteerId: widget.volunteer.id,
          dogId: dogId,
          level: newLevel,
        );
      }
      // Invalidate the cached familiarity data
      ref.invalidate(familiarityProvider(widget.volunteer.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSave(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Same icons as the level buttons, so the legend doesn't rely on colour alone.
const _levelIcons = {
  DogFamiliarityLevel.good: Icons.sentiment_very_satisfied,
  DogFamiliarityLevel.difficult: Icons.sentiment_neutral,
  DogFamiliarityLevel.never: Icons.sentiment_very_dissatisfied,
};

class _FamiliarityLegend extends StatelessWidget {
  const _FamiliarityLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(
          level: DogFamiliarityLevel.good,
          label: l10n.familiarityLegendGood,
        ),
        _LegendItem(
          level: DogFamiliarityLevel.difficult,
          label: l10n.familiarityLegendDifficult,
        ),
        _LegendItem(
          level: DogFamiliarityLevel.never,
          label: l10n.familiarityLegendNever,
        ),
        _LegendItem(
          level: DogFamiliarityLevel.unknown,
          label: l10n.familiarityLegendUnknown,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.level, required this.label});

  final DogFamiliarityLevel level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final icon = _levelIcons[level];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: level == DogFamiliarityLevel.unknown
                ? Colors.grey.shade300
                : familiarityColor(level),
          ),
          child: icon == null
              ? null
              : Icon(icon, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _DogAvatar extends StatelessWidget {
  const _DogAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        Center(child: Icon(Icons.pets, size: 20, color: Colors.grey.shade400));
    final url = photoUrl;
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? placeholder
          : ShelterImage(url, fit: BoxFit.cover, error: placeholder),
    );
  }
}

class _DogFamiliarityRow extends StatelessWidget {
  const _DogFamiliarityRow({
    required this.dog,
    required this.photoUrl,
    required this.level,
    required this.onChanged,
  });

  final Dog dog;
  final String? photoUrl;
  final DogFamiliarityLevel level;
  /// Null makes the row read-only.
  final ValueChanged<DogFamiliarityLevel>? onChanged;

  /// Tapping the selected level clears it.
  VoidCallback? _toggle(DogFamiliarityLevel tapped) {
    final onChanged = this.onChanged;
    if (onChanged == null) return null;
    return () => onChanged(
          level == tapped ? DogFamiliarityLevel.unknown : tapped,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _DogAvatar(photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Text(dog.name,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
          _LevelButton(
            level: DogFamiliarityLevel.good,
            currentLevel: level,
            color: familiarityColor(DogFamiliarityLevel.good),
            icon: Icons.sentiment_very_satisfied,
            tooltip: AppLocalizations.of(context)!.allGood,
            onTap: _toggle(DogFamiliarityLevel.good),
          ),
          const SizedBox(width: 4),
          _LevelButton(
            level: DogFamiliarityLevel.difficult,
            currentLevel: level,
            color: familiarityColor(DogFamiliarityLevel.difficult),
            icon: Icons.sentiment_neutral,
            tooltip: AppLocalizations.of(context)!.difficultButPossible,
            onTap: _toggle(DogFamiliarityLevel.difficult),
          ),
          const SizedBox(width: 4),
          _LevelButton(
            level: DogFamiliarityLevel.never,
            currentLevel: level,
            color: familiarityColor(DogFamiliarityLevel.never),
            icon: Icons.sentiment_very_dissatisfied,
            tooltip: AppLocalizations.of(context)!.noChance,
            onTap: _toggle(DogFamiliarityLevel.never),
          ),
        ],
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.level,
    required this.currentLevel,
    required this.color,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final DogFamiliarityLevel level;
  final DogFamiliarityLevel currentLevel;
  final Color color;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = level == currentLevel;
    return Semantics(
      button: true,
      selected: isSelected,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
