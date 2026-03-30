import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/volunteer.dart';
import '../providers/planner_providers.dart';

/// Shows a scrollable list of volunteers to pick from.
/// Filters out volunteers already assigned in the current plan.
Future<Volunteer?> showVolunteerPicker(BuildContext context) async {
  return showModalBottomSheet<Volunteer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _VolunteerPickerSheet(),
  );
}

class _VolunteerPickerSheet extends ConsumerStatefulWidget {
  const _VolunteerPickerSheet();

  @override
  ConsumerState<_VolunteerPickerSheet> createState() =>
      _VolunteerPickerSheetState();
}

class _VolunteerPickerSheetState extends ConsumerState<_VolunteerPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allVolunteers = ref.watch(allVolunteersProvider);
    final plannerState = ref.watch(plannerNotifierProvider);
    final assignedIds =
        plannerState.assignments.map((a) => a.volunteerId).toSet();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Add Volunteer',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search volunteers...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: allVolunteers.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (volunteers) {
                  final query = _search.toLowerCase();
                  final filtered = volunteers
                      .where((v) => !assignedIds.contains(v.id))
                      .where((v) =>
                          v.fullName.toLowerCase().contains(query))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          assignedIds.length == volunteers.length
                              ? 'All volunteers are already assigned'
                              : 'No volunteers match your search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.secondaryContainer,
                          child: Text(
                            v.firstName[0],
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(v.fullName),
                        onTap: () => Navigator.pop(context, v),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
