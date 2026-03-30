import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/volunteer_assignment.dart';
import 'providers/planner_providers.dart';
import 'widgets/assignment_card.dart';
import 'widgets/date_navigator.dart';
import 'widgets/dog_picker.dart';
import 'widgets/group_colors.dart';
import 'widgets/volunteer_picker.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final plannerState = ref.watch(plannerNotifierProvider);
    final notifier = ref.read(plannerNotifierProvider.notifier);
    final savedAsync = ref.watch(savedAssignmentsProvider);

    final hasModifications = savedAsync.whenOrNull(
          data: (saved) => plannerState.isModified(saved),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Planner'),
      ),
      body: Column(
        children: [
          // Date navigator
          DateNavigator(
            date: date,
            onDateChanged: (newDate) =>
                ref.read(selectedDateProvider.notifier).state = newDate,
          ),

          // Main content — horizontal scrolling columns
          Expanded(
            child: plannerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : plannerState.error != null
                    ? _ErrorBody(
                        message: plannerState.error!,
                        onRetry: notifier.reload,
                      )
                    : plannerState.assignments.isEmpty
                        ? _EmptyBody(
                            onAddVolunteer: () =>
                                _addVolunteer(context, ref),
                          )
                        : _ColumnsGrid(
                            plannerState: plannerState,
                            ref: ref,
                            onAddVolunteer: () =>
                                _addVolunteer(context, ref),
                          ),
          ),

          // Save bar
          _SaveBar(
            isModified: hasModifications,
            isSaving: plannerState.isSaving,
            assignmentCount: plannerState.assignments.length,
            dogCount: plannerState.assignedDogIds.length,
            totalDogs: ref.watch(totalDogCountProvider).valueOrNull ?? 0,
            onSave: () => notifier.save(),
          ),
        ],
      ),
    );
  }

  Future<void> _addVolunteer(BuildContext context, WidgetRef ref) async {
    final volunteer = await showVolunteerPicker(context);
    if (volunteer != null) {
      ref.read(plannerNotifierProvider.notifier).addVolunteer(volunteer);
    }
  }
}

// ---------------------------------------------------------------------------
// Horizontal scrolling grid of volunteer columns
// ---------------------------------------------------------------------------

class _ColumnsGrid extends StatelessWidget {
  const _ColumnsGrid({
    required this.plannerState,
    required this.ref,
    required this.onAddVolunteer,
  });

  final PlannerState plannerState;
  final WidgetRef ref;
  final VoidCallback onAddVolunteer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - 24; // 12px padding each side
        const gap = 8.0;
        int cols;
        if (usable < 360) {
          cols = 1;
        } else if (usable < 540) {
          cols = 2;
        } else {
          cols = (usable / 180).floor().clamp(3, 8);
        }
        final colWidth = (usable - (cols - 1) * gap) / cols;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final assignment in plannerState.assignments)
                SizedBox(
                  width: colWidth,
                  child: VolunteerColumn(
                    assignment: assignment,
                    onRemoveVolunteer: () =>
                        _confirmRemove(context, ref, assignment),
                    onRemoveDog: (dogId) => ref
                        .read(plannerNotifierProvider.notifier)
                        .removeDogFromVolunteer(
                            assignment.volunteerId, dogId),
                    onAddDog: () =>
                        _addDogs(context, assignment.volunteerId),
                    onTapDog: (dogId) => _showDogActions(
                        context, ref, assignment, dogId),
                    onEditVolunteerNote: () =>
                        _editVolunteerNote(context, ref, assignment),
                  ),
                ),
              SizedBox(
                width: colWidth,
                child: _AddVolunteerButton(onTap: onAddVolunteer),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addDogs(BuildContext context, int volunteerId) async {
    final entries = await showDogPicker(
      context: context,
      volunteerId: volunteerId,
      alreadyAssignedDogIds: plannerState.assignedDogIds,
    );
    if (entries != null && entries.isNotEmpty) {
      ref
          .read(plannerNotifierProvider.notifier)
          .addDogEntries(volunteerId, entries);
    }
  }

  void _confirmRemove(
      BuildContext context, WidgetRef ref, VolunteerAssignment a) {
    if (a.dogs.isEmpty) {
      ref.read(plannerNotifierProvider.notifier).removeVolunteer(a.volunteerId);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${a.volunteerName}?'),
        content: Text(
            'This will unassign ${a.dogs.length} dog${a.dogs.length == 1 ? '' : 's'}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref
                  .read(plannerNotifierProvider.notifier)
                  .removeVolunteer(a.volunteerId);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDogActions(BuildContext context, WidgetRef ref,
      VolunteerAssignment assignment, int dogId) {
    final entry = assignment.dogs.firstWhere((d) => d.dogId == dogId);
    final notifier = ref.read(plannerNotifierProvider.notifier);
    final maxGroup = ref.read(plannerNotifierProvider).maxGroupIndex;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.dogName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                // Group color picker
                Text('Walk group',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    // "No group" option
                    _GroupChip(
                      color: null,
                      label: 'Solo',
                      isSelected: entry.groupIndex == null ||
                          entry.groupIndex == 0,
                      onTap: () {
                        notifier.updateDogGroup(
                            assignment.volunteerId, dogId, null);
                        Navigator.pop(ctx);
                      },
                    ),
                    // Existing groups + one new
                    for (var i = 1; i <= maxGroup + 1; i++)
                      _GroupChip(
                        color: groupColor(i),
                        label: 'Group $i',
                        isSelected: entry.groupIndex == i,
                        onTap: () {
                          notifier.updateDogGroup(
                              assignment.volunteerId, dogId, i);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Add note
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('Add note'),
                  subtitle: entry.note != null
                      ? Text(entry.note!)
                      : null,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _editDogNote(
                        context, ref, assignment.volunteerId, entry);
                  },
                ),
                // Remove
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded,
                      color: theme.colorScheme.error),
                  title: Text('Remove',
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    notifier.removeDogFromVolunteer(
                        assignment.volunteerId, dogId);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editDogNote(BuildContext context, WidgetRef ref,
      int volunteerId, DogEntry entry) {
    final controller = TextEditingController(text: entry.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note for ${entry.dogName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. hospital, bring to vet',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              ref.read(plannerNotifierProvider.notifier).updateDogNote(
                  volunteerId,
                  entry.dogId,
                  text.isEmpty ? null : text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editVolunteerNote(BuildContext context, WidgetRef ref,
      VolunteerAssignment assignment) {
    final controller =
        TextEditingController(text: assignment.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(assignment.volunteerName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 10-13, 2 dogs only',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              ref
                  .read(plannerNotifierProvider.notifier)
                  .updateVolunteerNote(
                      assignment.volunteerId,
                      text.isEmpty ? null : text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "+" button to add another volunteer column
// ---------------------------------------------------------------------------

class _AddVolunteerButton extends StatelessWidget {
  const _AddVolunteerButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(6),
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              'Add volunteer',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group color chip for the dog action sheet
// ---------------------------------------------------------------------------

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color? color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onAddVolunteer});
  final VoidCallback onAddVolunteer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_chart_outlined,
              size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No walks planned yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onAddVolunteer,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add first volunteer'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

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
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load plan',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
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

// ---------------------------------------------------------------------------
// Save bar
// ---------------------------------------------------------------------------

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isModified,
    required this.isSaving,
    required this.assignmentCount,
    required this.dogCount,
    required this.totalDogs,
    required this.onSave,
  });

  final bool isModified;
  final bool isSaving;
  final int assignmentCount;
  final int dogCount;
  final int totalDogs;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$assignmentCount volunteers  •  $dogCount/$totalDogs dogs',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
            FilledButton(
              onPressed: isModified && !isSaving ? onSave : null,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isModified ? 'Save' : 'Saved'),
            ),
          ],
        ),
      ),
    );
  }
}
