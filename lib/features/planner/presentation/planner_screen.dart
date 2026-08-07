import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dog_detail/presentation/providers/dog_detail_providers.dart';
import '../domain/volunteer_assignment.dart';
import 'providers/planner_providers.dart';
import 'widgets/assignment_card.dart';
import 'widgets/date_navigator.dart';
import 'widgets/dog_picker.dart';
import 'widgets/group_colors.dart';
import 'widgets/planner_share.dart';
import 'widgets/volunteer_picker.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final plannerState = ref.watch(plannerNotifierProvider);
    final notifier = ref.read(plannerNotifierProvider.notifier);
    final detailLevel = ref.watch(plannerDetailLevelProvider);
    final isOverview = detailLevel == PlannerDetailLevel.overview;
    final isCompact = detailLevel != PlannerDetailLevel.detailed;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.walkPlanner),
        actions: [
          if (plannerState.assignments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: AppLocalizations.of(context)!.sharePlan,
              onPressed: () => sharePlannerImage(
                context: context,
                date: date,
                assignments: plannerState.assignments,
                totalDogs: ref.read(totalDogCountProvider).valueOrNull ?? 0,
                detailed: detailLevel == PlannerDetailLevel.detailed,
              ),
            ),
          IconButton(
            icon: Icon(switch (detailLevel) {
              PlannerDetailLevel.compact => Icons.unfold_more,
              PlannerDetailLevel.detailed => Icons.visibility_outlined,
              PlannerDetailLevel.overview => Icons.unfold_less,
            }),
            tooltip: switch (detailLevel) {
              PlannerDetailLevel.compact => AppLocalizations.of(
                context,
              )!.showMore,
              PlannerDetailLevel.detailed => AppLocalizations.of(
                context,
              )!.overviewMode,
              PlannerDetailLevel.overview => AppLocalizations.of(
                context,
              )!.showLess,
            },
            onPressed: () {
              final next = switch (detailLevel) {
                PlannerDetailLevel.compact => PlannerDetailLevel.detailed,
                PlannerDetailLevel.detailed => PlannerDetailLevel.overview,
                PlannerDetailLevel.overview => PlannerDetailLevel.compact,
              };
              ref.read(plannerDetailLevelProvider.notifier).state = next;
            },
          ),
        ],
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
                ? _EmptyBody(onAddVolunteer: () => _addVolunteer(context, ref))
                : _ColumnsGrid(
                    plannerState: plannerState,
                    ref: ref,
                    compact: isCompact,
                    overview: isOverview,
                    onAddVolunteer: () => _addVolunteer(context, ref),
                  ),
          ),

          // Status bar
          _StatusBar(
            saveStatus: plannerState.saveStatus,
            autoSaveEnabled: plannerState.autoSaveEnabled,
            assignmentCount: plannerState.assignments.length,
            dogCount: plannerState.assignedDogIds.length,
            totalDogs: ref.watch(totalDogCountProvider).valueOrNull ?? 0,
            onToggleAutoSave: notifier.toggleAutoSave,
            onSave: notifier.save,
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
    this.compact = true,
    this.overview = false,
  });

  final PlannerState plannerState;
  final WidgetRef ref;
  final VoidCallback onAddVolunteer;
  final bool compact;
  final bool overview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final usable = (maxWidth - 24).clamp(
          120.0,
          1400.0,
        ); // 12px padding each side
        final gap = overview ? 6.0 : 8.0;
        int cols;
        if (overview) {
          // Overview: force more columns — min 2 always, aim for tighter fit
          if (usable < 300) {
            cols = 2;
          } else {
            cols = (usable / 150).floor().clamp(2, 8);
          }
        } else {
          if (usable < 360) {
            cols = 1;
          } else if (usable < 540) {
            cols = 2;
          } else {
            cols = (usable / 180).floor().clamp(3, 8);
          }
        }
        final colWidth = (usable - (cols - 1) * gap) / cols;

        return SingleChildScrollView(
          padding: EdgeInsets.all(overview ? 8 : 12),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final assignment in plannerState.assignments)
                SizedBox(
                  width: colWidth,
                  child: VolunteerColumn(
                    assignment: assignment,
                    relationshipLookup: ref.watch(relationshipLookupProvider).valueOrNull,
                    compact: compact,
                    overview: overview,
                    onRemoveVolunteer: () =>
                        _confirmRemove(context, ref, assignment),
                    onRemoveDog: (dogId) => ref
                        .read(plannerNotifierProvider.notifier)
                        .removeDogFromVolunteer(assignment.volunteerId, dogId),
                    onAddDog: () => _addDogs(context, assignment),
                    onTapDog: (dogId) =>
                        _showDogActions(context, ref, assignment, dogId),
                    onEditVolunteerNote: () =>
                        _editVolunteerNote(context, ref, assignment),
                    onReorderDogs: (oldIndex, newIndex) => ref
                        .read(plannerNotifierProvider.notifier)
                        .reorderDogs(
                          assignment.volunteerId,
                          oldIndex,
                          newIndex,
                        ),
                  ),
                ),
              if (!overview)
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

  Future<void> _addDogs(BuildContext context, VolunteerAssignment assignment) async {
    final entries = await showDogPicker(
      context: context,
      volunteerId: assignment.volunteerId,
      alreadyAssignedDogIds: plannerState.assignedDogIds,
    );
    if (entries != null && entries.isNotEmpty) {
      ref
          .read(plannerNotifierProvider.notifier)
          .addDogEntries(assignment.volunteerId, entries);
    }
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    VolunteerAssignment a,
  ) {
    if (a.dogs.isEmpty) {
      ref.read(plannerNotifierProvider.notifier).removeVolunteer(a.volunteerId);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.removeVolunteerTitle(a.volunteerName),
        ),
        content: Text(
          AppLocalizations.of(context)!.removeVolunteerContent(a.dogs.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(plannerNotifierProvider.notifier)
                  .removeVolunteer(a.volunteerId);
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }

  void _showDogActions(
    BuildContext context,
    WidgetRef ref,
    VolunteerAssignment assignment,
    int dogId,
  ) {
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
                Text(
                  entry.dogName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Group color picker
                Text(
                  AppLocalizations.of(ctx)!.walkGroup,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    // "No group" option
                    _GroupChip(
                      groupIndex: null,
                      label: AppLocalizations.of(ctx)!.solo,
                      isSelected:
                          entry.groupIndex == null || entry.groupIndex == 0,
                      onTap: () {
                        notifier.updateDogGroup(
                          assignment.volunteerId,
                          dogId,
                          null,
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                    // Existing groups + one new
                    for (var i = 1; i <= maxGroup + 1; i++)
                      _GroupChip(
                        groupIndex: i,
                        label: AppLocalizations.of(ctx)!.groupN(i),
                        isSelected: entry.groupIndex == i,
                        onTap: () {
                          notifier.updateDogGroup(
                            assignment.volunteerId,
                            dogId,
                            i,
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Add note
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: Text(AppLocalizations.of(ctx)!.addNote),
                  subtitle: entry.note != null ? Text(entry.note!) : null,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _editDogNote(context, ref, assignment.volunteerId, entry);
                  },
                ),
                // View profile
                ListTile(
                  leading: const Icon(Icons.pets_rounded),
                  title: const Text('View profile'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/dog/$dogId', extra: {
                      'dogName': entry.dogName,
                      'shelterId': entry.shelterId,
                      'kennel': entry.kennel,
                      'region': entry.region,
                    });
                  },
                ),
                // Remove
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    AppLocalizations.of(ctx)!.remove,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    notifier.removeDogFromVolunteer(
                      assignment.volunteerId,
                      dogId,
                    );
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

  void _editDogNote(
    BuildContext context,
    WidgetRef ref,
    int volunteerId,
    DogEntry entry,
  ) {
    final controller = TextEditingController(text: entry.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.noteFor(entry.dogName)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.noteHintDog,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              ref
                  .read(plannerNotifierProvider.notifier)
                  .updateDogNote(
                    volunteerId,
                    entry.dogId,
                    text.isEmpty ? null : text,
                  );
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _editVolunteerNote(
    BuildContext context,
    WidgetRef ref,
    VolunteerAssignment assignment,
  ) {
    final controller = TextEditingController(text: assignment.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(assignment.volunteerName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.noteHintVolunteer,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              ref
                  .read(plannerNotifierProvider.notifier)
                  .updateVolunteerNote(
                    assignment.volunteerId,
                    text.isEmpty ? null : text,
                  );
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
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
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_outlined, color: theme.colorScheme.outline),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.addVolunteerButton,
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
    this.groupIndex,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int? groupIndex;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final bgColor = groupIndex != null
        ? groupColor(groupIndex, brightness)
        : theme.colorScheme.surfaceContainerHighest;
    final txtColor = groupIndex != null
        ? groupTextColor(groupIndex, brightness)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : null,
            color: txtColor,
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
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noWalksPlannedYet,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onAddVolunteer,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.addFirstVolunteer),
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
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.failedToLoadPlan,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status bar (replaces save bar — auto-save indicator)
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.saveStatus,
    required this.autoSaveEnabled,
    required this.assignmentCount,
    required this.dogCount,
    required this.totalDogs,
    required this.onToggleAutoSave,
    required this.onSave,
  });

  final SaveStatus saveStatus;
  final bool autoSaveEnabled;
  final int assignmentCount;
  final int dogCount;
  final int totalDogs;
  final VoidCallback onToggleAutoSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.nVolunteersNDogs(assignmentCount, dogCount, totalDogs),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            if (autoSaveEnabled)
              _SaveStatusIndicator(status: saveStatus)
            else
              _ManualSaveButton(status: saveStatus, onSave: onSave),
            const SizedBox(width: 8),
            _AutoSaveToggle(
              enabled: autoSaveEnabled,
              onToggle: onToggleAutoSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoSaveToggle extends StatelessWidget {
  const _AutoSaveToggle({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.autoSave,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 20,
            width: 34,
            child: Transform.scale(
              scale: 0.6,
              child: Switch.adaptive(
                value: enabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: theme.colorScheme.secondaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualSaveButton extends StatelessWidget {
  const _ManualSaveButton({required this.status, required this.onSave});

  final SaveStatus status;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = status == SaveStatus.saving;
    final hasChanges =
        status == SaveStatus.unsaved || status == SaveStatus.error;

    if (isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.saving,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: hasChanges ? onSave : null,
      icon: Icon(
        status == SaveStatus.error ? Icons.error_outline : Icons.save_outlined,
        size: 16,
      ),
      label: Text(
        status == SaveStatus.error
            ? AppLocalizations.of(context)!.saveError
            : hasChanges
            ? AppLocalizations.of(context)!.save
            : AppLocalizations.of(context)!.saved,
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _SaveStatusIndicator extends StatelessWidget {
  const _SaveStatusIndicator({required this.status});
  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case SaveStatus.idle:
      case SaveStatus.saved:
        // Nothing to say once a change has made it to the server — only
        // surface the states that need attention (unsaved/saving/error).
        return const SizedBox.shrink();
      case SaveStatus.unsaved:
        return Text(
          AppLocalizations.of(context)!.unsaved,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        );
      case SaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.saving,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        );
      case SaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.saveError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        );
    }
  }
}
