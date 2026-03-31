import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/dog.dart';
import '../../../shared/domain/volunteer.dart';
import '../../../planner/domain/planner_dog.dart';
import '../providers/manage_providers.dart';

class FamiliarityDialog extends ConsumerStatefulWidget {
  const FamiliarityDialog({super.key, required this.volunteer});

  final Volunteer volunteer;

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

    return AlertDialog(
      title: Text('${widget.volunteer.fullName} — Dog Familiarity'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: dogsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (dogs) {
            final activeDogs =
                dogs.where((d) => !d.archived).toList();
            return familiarityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                      level: level,
                      onChanged: (newLevel) =>
                          _onLevelChanged(dog.id, newLevel),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Close'),
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
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DogFamiliarityRow extends StatelessWidget {
  const _DogFamiliarityRow({
    required this.dog,
    required this.level,
    required this.onChanged,
  });

  final Dog dog;
  final DogFamiliarityLevel level;
  final ValueChanged<DogFamiliarityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dog.name,
                    style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  'Kennel: ${dog.kennel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _LevelButton(
            level: DogFamiliarityLevel.good,
            currentLevel: level,
            color: const Color(0xFF2A9D8F),
            icon: Icons.sentiment_very_satisfied,
            tooltip: 'All good',
            onTap: () => onChanged(
              level == DogFamiliarityLevel.good
                  ? DogFamiliarityLevel.unknown
                  : DogFamiliarityLevel.good,
            ),
          ),
          const SizedBox(width: 4),
          _LevelButton(
            level: DogFamiliarityLevel.difficult,
            currentLevel: level,
            color: const Color(0xFFE8A317),
            icon: Icons.sentiment_neutral,
            tooltip: 'Difficult but possible',
            onTap: () => onChanged(
              level == DogFamiliarityLevel.difficult
                  ? DogFamiliarityLevel.unknown
                  : DogFamiliarityLevel.difficult,
            ),
          ),
          const SizedBox(width: 4),
          _LevelButton(
            level: DogFamiliarityLevel.never,
            currentLevel: level,
            color: Colors.red,
            icon: Icons.sentiment_very_dissatisfied,
            tooltip: 'No chance',
            onTap: () => onChanged(
              level == DogFamiliarityLevel.never
                  ? DogFamiliarityLevel.unknown
                  : DogFamiliarityLevel.never,
            ),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = level == currentLevel;
    return Tooltip(
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
    );
  }
}
