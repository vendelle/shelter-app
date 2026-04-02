import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/volunteer.dart';
import '../providers/manage_providers.dart';
import 'volunteer_form_dialog.dart';
import 'familiarity_dialog.dart';

Color roleColor(VolunteerRole role) {
  return switch (role) {
    VolunteerRole.senior => const Color(0xFF9C27B0),       // purple
    VolunteerRole.independent => const Color(0xFFE65100),   // dark orange
    VolunteerRole.supporter => const Color(0xFFFF9800),     // light orange
    VolunteerRole.newHelper => const Color(0xFFFFEB3B),     // yellow
  };
}

Color roleTextColor(VolunteerRole role) {
  return switch (role) {
    VolunteerRole.senior => Colors.white,
    VolunteerRole.independent => Colors.white,
    VolunteerRole.supporter => Colors.black87,
    VolunteerRole.newHelper => Colors.black87,
  };
}

class VolunteersTab extends ConsumerWidget {
  const VolunteersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedVolunteersProvider);
    final volunteersAsync = ref.watch(managedVolunteersProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.active)),
                  ButtonSegment(value: true, label: Text(l10n.inactive)),
                ],
                selected: {showArchived},
                onSelectionChanged: (selected) {
                  ref.read(showArchivedVolunteersProvider.notifier).state =
                      selected.first;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: volunteersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (volunteers) {
              if (volunteers.isEmpty) {
                return Center(
                  child: Text(showArchived
                      ? l10n.noInactiveVolunteers
                      : l10n.noVolunteersFound),
                );
              }
              return ListView.builder(
                itemCount: volunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = volunteers[index];
                  return _VolunteerListTile(volunteer: volunteer);
                },
              );
            },
          ),
        ),
        if (!showArchived)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showAddVolunteerDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.addVolunteerTitle),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddVolunteerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => VolunteerFormDialog(
        onSave: (firstName, lastName, role) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.createVolunteer(
            firstName: firstName,
            lastName: lastName,
            role: role,
          );
          ref.invalidate(managedVolunteersProvider);
        },
      ),
    );
  }
}

class _VolunteerListTile extends ConsumerWidget {
  const _VolunteerListTile({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = volunteer.archived
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : roleColor(volunteer.role);
    final fgColor = volunteer.archived
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : roleTextColor(volunteer.role);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bgColor,
        child: Text(
          '${volunteer.firstName[0]}${volunteer.lastName[0]}',
          style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(volunteer.fullName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!volunteer.archived)
            IconButton(
              icon: const Icon(Icons.pets_rounded),
              tooltip: AppLocalizations.of(context)!.dogFamiliarity(volunteer.fullName),
              onPressed: () => _showFamiliarityDialog(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showFamiliarityDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => FamiliarityDialog(volunteer: volunteer),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => VolunteerFormDialog(
        initialFirstName: volunteer.firstName,
        initialLastName: volunteer.lastName,
        initialRole: volunteer.role,
        isArchived: volunteer.archived,
        onSave: (firstName, lastName, role) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.updateVolunteer(
            id: volunteer.id,
            firstName: firstName,
            lastName: lastName,
            role: role,
          );
          ref.invalidate(managedVolunteersProvider);
        },
        onArchiveToggle: () async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.archiveVolunteer(volunteer.id,
              archive: !volunteer.archived);
          ref.invalidate(managedVolunteersProvider);
        },
      ),
    );
  }
}
