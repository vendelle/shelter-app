import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/dog.dart';
import '../providers/manage_providers.dart';
import 'dog_form_dialog.dart';

class DogsTab extends ConsumerWidget {
  const DogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(showArchivedDogsProvider);
    final dogsAsync = ref.watch(managedDogsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Current')),
                  ButtonSegment(value: true, label: Text('Adopted')),
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
                      ? 'No adopted dogs'
                      : 'No dogs found'),
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
                label: const Text('Add Dog'),
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
        onSave: (name, shelterId, kennel) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.createDog(
            name: name,
            shelterId: shelterId,
            kennel: kennel,
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
      title: Text(dog.name),
      subtitle: Text(
        [
          dog.shelterId,
          'K: ${dog.kennel}',
          if (dog.region != null) dog.region!,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dog.region != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  dog.region!,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
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
        isArchived: dog.archived,
        onSave: (name, shelterId, kennel) async {
          final repo = ref.read(manageRepositoryProvider);
          await repo.updateDog(
            id: dog.id,
            name: name,
            shelterId: shelterId,
            kennel: kennel,
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
