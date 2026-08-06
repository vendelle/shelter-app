import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../dog_detail/presentation/widgets/detail_tab_scaffold.dart';
import '../../manage/presentation/providers/manage_providers.dart';
import '../../manage/presentation/widgets/familiarity_dialog.dart';
import '../../manage/presentation/widgets/volunteer_form_dialog.dart';
import '../../shared/domain/volunteer.dart';
import 'providers/volunteer_detail_providers.dart';
import 'widgets/volunteer_dogs_section.dart';
import 'widgets/volunteer_stats_section.dart';
import 'widgets/volunteer_status_header.dart';
import 'widgets/volunteer_visits_section.dart';

/// Read-only volunteer profile: status, activity stats, dogs walked most
/// often, and visit history. Fetches everything by [volunteerId] rather
/// than relying on route `extra` data, so a browser refresh or a deep link
/// still works.
class VolunteerDetailScreen extends ConsumerWidget {
  const VolunteerDetailScreen({super.key, required this.volunteerId});

  final int volunteerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(volunteerProfileProvider(volunteerId));
    final volunteer = profileAsync.valueOrNull?.volunteer;

    return Scaffold(
      appBar: AppBar(
        title: Text(volunteer?.fullName ?? ''),
        actions: volunteer == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.pets_rounded),
                  tooltip: l10n.dogFamiliarity(volunteer.fullName),
                  onPressed: () => _showFamiliarityDialog(context, volunteer),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.edit,
                  onPressed: () => _showEditDialog(context, ref, volunteer),
                ),
              ],
      ),
      body: DetailTabScaffold(
        onRefresh: () async {
          ref.invalidate(volunteerProfileProvider(volunteerId));
          await ref.read(volunteerProfileProvider(volunteerId).future);
        },
        children: [
          profileAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('${l10n.saveFailed}: $e'),
            ),
            data: (profile) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VolunteerStatusHeader(volunteer: profile.volunteer),
                const SizedBox(height: 24),
                VolunteerStatsSection(profile: profile),
                const SizedBox(height: 24),
                VolunteerDogsSection(
                  volunteerId: volunteerId,
                  dogs: profile.dogs,
                ),
                const SizedBox(height: 24),
                VolunteerVisitsSection(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFamiliarityDialog(BuildContext context, Volunteer volunteer) {
    showDialog(
      context: context,
      builder: (context) => FamiliarityDialog(volunteer: volunteer),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, Volunteer volunteer) {
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
          ref.invalidate(volunteerProfileProvider(volunteerId));
        },
        onArchiveToggle: () async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.archiveVolunteer(volunteer.id, archive: !volunteer.archived);
          ref.invalidate(managedVolunteersProvider);
          ref.invalidate(volunteerProfileProvider(volunteerId));
        },
      ),
    );
  }
}
