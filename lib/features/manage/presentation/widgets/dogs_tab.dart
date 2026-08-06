import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/domain/dog.dart';
import '../providers/manage_providers.dart';
import 'dog_form_dialog.dart';

class DogsTab extends ConsumerWidget {
  const DogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedDogsProvider);
    final dogsAsync = ref.watch(managedDogsProvider);
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
                  ButtonSegment(value: false, label: Text(l10n.current)),
                  ButtonSegment(value: true, label: Text(l10n.adopted)),
                ],
                selected: {showArchived},
                onSelectionChanged: (selected) {
                  ref.read(showArchivedDogsProvider.notifier).state =
                      selected.first;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: dogsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (dogs) {
              if (dogs.isEmpty) {
                return Center(
                  child: Text(showArchived
                      ? l10n.noAdoptedDogs
                      : l10n.noDogsFound),
                );
              }
              return ListView.builder(
                itemCount: dogs.length,
                itemBuilder: (context, index) {
                  final dog = dogs[index];
                  return _DogListTile(dog: dog);
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
                onPressed: () => _showAddDogDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.addDogButton),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddDogDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DogFormDialog(
        onSave: (name, shelterId, kennel, {String? region, bool clearRegion = false}) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.createDog(
            name: name,
            shelterId: shelterId,
            kennel: kennel,
            region: region,
          );
          ref.invalidate(managedDogsProvider);
        },
      ),
    );
  }
}

class _DogListTile extends ConsumerWidget {
  const _DogListTile({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => context.push('/dog/${dog.id}', extra: {
        'dogName': dog.name,
        'shelterId': dog.shelterId,
        'kennel': dog.kennel,
        'region': dog.region,
      }),
      title: Text(dog.name),
      subtitle: Text(
        [
          dog.shelterId,
          dog.kennel,
          if (dog.region != null) dog.region!,
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: AppLocalizations.of(context)!.edit,
        onPressed: () => _showEditDialog(context, ref),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DogFormDialog(
        initialName: dog.name,
        initialShelterId: dog.shelterId,
        initialKennel: dog.kennel,
        initialRegion: dog.region,
        initialRegionOverride: dog.regionOverride,
        isArchived: dog.archived,
        onSave: (name, shelterId, kennel, {String? region, bool clearRegion = false}) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.updateDog(
            id: dog.id,
            name: name,
            shelterId: shelterId,
            kennel: kennel,
            region: region,
            clearRegion: clearRegion,
          );
          ref.invalidate(managedDogsProvider);
        },
        onArchiveToggle: () async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.archiveDog(dog.id, archive: !dog.archived);
          ref.invalidate(managedDogsProvider);
        },
      ),
    );
  }
}
