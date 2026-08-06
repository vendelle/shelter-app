import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../manage/presentation/familiarity_colors.dart';
import '../../../manage/presentation/providers/manage_providers.dart';
import '../../../planner/domain/planner_dog.dart';
import '../../domain/volunteer_profile.dart';
import '../walk_count_colors.dart';
import 'section_header.dart';

/// All active dogs as compact pills, colored by how often this volunteer
/// walked them in the last 90 days, ranked highest-first. A small dot marks
/// the volunteer's familiarity with that dog. Tapping a pill reveals the
/// exact walk count.
class VolunteerDogsSection extends ConsumerWidget {
  const VolunteerDogsSection({
    super.key,
    required this.volunteerId,
    required this.dogs,
  });

  final int volunteerId;
  final List<VolunteerDogWalkCount> dogs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final familiarityMap =
        ref.watch(familiarityProvider(volunteerId)).valueOrNull ??
            const <int, DogFamiliarityLevel>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VolunteerSectionHeader(
          title: l10n.dogsWalkedMostOften,
          caption: l10n.last90Days,
        ),
        if (dogs.isEmpty)
          Text(
            l10n.noActiveDogs,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dog in dogs)
                _DogPill(
                  dog: dog,
                  familiarity:
                      familiarityMap[dog.dogId] ?? DogFamiliarityLevel.unknown,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.dogWalkCountSnackbar(
                        dog.dogName,
                        dog.walkCount,
                        l10n.last90Days,
                      )),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          l10n.dogsLegendCaption,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _DogPill extends StatelessWidget {
  const _DogPill({
    required this.dog,
    required this.familiarity,
    required this.onTap,
  });

  final VolunteerDogWalkCount dog;
  final DogFamiliarityLevel familiarity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = walkCountColor(context, dog.walkCount);
    final fg = walkCountTextColor(context, dog.walkCount);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 8, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dog.dogName,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (familiarity != DogFamiliarityLevel.unknown) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: familiarityColor(familiarity),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
