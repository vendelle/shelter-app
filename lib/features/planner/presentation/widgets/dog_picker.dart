import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/planner_dog.dart';
import '../../domain/volunteer_assignment.dart';
import '../providers/planner_providers.dart';

/// Shows a bottom sheet to pick dogs for a specific volunteer.
///
/// **Tap** a dog → immediately adds it and closes.
/// **Long-press** a dog → enters multi-select mode, pick several, then confirm.
Future<List<DogEntry>?> showDogPicker({
  required BuildContext context,
  required int volunteerId,
  required Set<int> alreadyAssignedDogIds,
}) async {
  return showModalBottomSheet<List<DogEntry>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _DogPickerSheet(
      volunteerId: volunteerId,
      alreadyAssignedDogIds: alreadyAssignedDogIds,
    ),
  );
}

class _DogPickerSheet extends ConsumerStatefulWidget {
  const _DogPickerSheet({
    required this.volunteerId,
    required this.alreadyAssignedDogIds,
  });

  final int volunteerId;
  final Set<int> alreadyAssignedDogIds;

  @override
  ConsumerState<_DogPickerSheet> createState() => _DogPickerSheetState();
}

class _DogPickerSheetState extends ConsumerState<_DogPickerSheet> {
  final Set<int> _selected = {};
  bool _multiSelect = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dogsAsync =
        ref.watch(dogsForVolunteerProvider(widget.volunteerId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
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
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _multiSelect ? 'Select dogs' : 'Add dog',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_multiSelect) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selected.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_multiSelect)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selected.clear();
                          _multiSelect = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Hint
            if (!_multiSelect)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                child: Text(
                  'Tap to add  •  Long press to select multiple',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            // Dog list
            Expanded(
              child: dogsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (dogs) {
                  final available = dogs
                      .where((d) =>
                          !widget.alreadyAssignedDogIds.contains(d.id))
                      .toList()
                    ..sort((a, b) => a.comparePriority(b));

                  if (available.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'All dogs are already assigned',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final dog = available[index];
                      final isSelected = _selected.contains(dog.id);

                      return _DogPickerTile(
                        dog: dog,
                        isSelected: isSelected,
                        isMultiSelect: _multiSelect,
                        onTap: () => _onTap(dog),
                        onLongPress: () => _onLongPress(dog),
                      );
                    },
                  );
                },
              ),
            ),
            // Multi-select confirm button
            if (_multiSelect)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : _confirmMulti,
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Add ${_selected.length} dogs'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onTap(PlannerDog dog) {
    if (_multiSelect) {
      setState(() {
        if (_selected.contains(dog.id)) {
          _selected.remove(dog.id);
          if (_selected.isEmpty) _multiSelect = false;
        } else {
          _selected.add(dog.id);
        }
      });
    } else {
      Navigator.pop(context, [
        DogEntry(dogId: dog.id, dogName: dog.name, kennel: dog.kennel),
      ]);
    }
  }

  void _onLongPress(PlannerDog dog) {
    if (!_multiSelect) {
      HapticFeedback.mediumImpact();
      setState(() {
        _multiSelect = true;
        _selected.add(dog.id);
      });
    }
  }

  void _confirmMulti() {
    final dogsAsync =
        ref.read(dogsForVolunteerProvider(widget.volunteerId));
    final allDogs = dogsAsync.valueOrNull ?? [];
    final entries = allDogs
        .where((d) => _selected.contains(d.id))
        .map((d) => DogEntry(dogId: d.id, dogName: d.name, kennel: d.kennel))
        .toList();
    Navigator.pop(context, entries);
  }
}

// ---------------------------------------------------------------------------
// Simplified dog tile — name + familiarity dot + subtle walk count
// ---------------------------------------------------------------------------

class _DogPickerTile extends StatelessWidget {
  const _DogPickerTile({
    required this.dog,
    required this.isSelected,
    required this.isMultiSelect,
    required this.onTap,
    required this.onLongPress,
  });

  final PlannerDog dog;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final familiarityColor = _getFamiliarityColor(dog.familiarity, colorScheme);
    final showDot = dog.familiarity != DogFamiliarityLevel.unknown;

    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
      onTap: onTap,
      onLongPress: onLongPress,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: isMultiSelect
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              dog.name,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showDot) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: familiarityColor,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${dog.thisWeekWalks} (${dog.lastWeekWalks})',
        style: theme.textTheme.bodySmall?.copyWith(
          color: dog.thisWeekWalks == 0
              ? colorScheme.error
              : colorScheme.outline,
          fontWeight:
              dog.thisWeekWalks == 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getFamiliarityColor(
      DogFamiliarityLevel familiarity, ColorScheme colorScheme) {
    return switch (familiarity) {
      DogFamiliarityLevel.good => const Color(0xFF2A9D8F),
      DogFamiliarityLevel.neutral => const Color(0xFFE8A317),
      DogFamiliarityLevel.caution => colorScheme.error,
      DogFamiliarityLevel.unknown => Colors.transparent,
    };
  }
}

