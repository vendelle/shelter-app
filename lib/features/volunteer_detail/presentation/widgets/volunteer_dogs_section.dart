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
/// the volunteer's familiarity with that dog. Tapping a pill shows a small
/// tooltip above it with the exact walk count.
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
              // Keyed by dog id so each pill (and its Tooltip) stays bound
              // to the same dog across rebuilds — no shared/queued state
              // that could show the wrong dog's count.
              for (final dog in dogs)
                _DogPill(
                  key: ValueKey(dog.dogId),
                  dog: dog,
                  familiarity: familiarityMap[dog.dogId] ??
                      DogFamiliarityLevel.unknown,
                  tooltipMessage:
                      l10n.dogWalkCountTooltip(dog.dogName, dog.walkCount),
                ),
            ],
          ),
        const SizedBox(height: 10),
        _WalkCountLegend(),
        const SizedBox(height: 4),
        Text(
          l10n.dogFamiliarityDotCaption,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

/// Color-swatch legend spelling out what each pill color means, e.g.
/// "🟨 1-2  🟧 3-5  🟥 5-10  🟪 10+" — the buckets aren't self-explanatory
/// from color alone.
class _WalkCountLegend extends StatelessWidget {
  const _WalkCountLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final sample in walkCountBucketSamples)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: walkCountColor(context, sample),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                walkCountBucketLabel(sample),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
      ],
    );
  }
}

class _DogPill extends StatelessWidget {
  const _DogPill({
    super.key,
    required this.dog,
    required this.familiarity,
    required this.tooltipMessage,
  });

  final VolunteerDogWalkCount dog;
  final DogFamiliarityLevel familiarity;
  final String tooltipMessage;

  @override
  Widget build(BuildContext context) {
    final bg = walkCountColor(context, dog.walkCount);
    final fg = walkCountTextColor(context, dog.walkCount);

    // A tap-triggered Tooltip is the "hint cloud above the dog name" —
    // anchored to this exact pill, so it can't drift to a different dog
    // the way a queued bottom SnackBar could when tapping around quickly.
    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
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
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: familiarityColor(familiarity),
                  // A white ring separates the dot from the pill's own
                  // color so it reads as a badge rather than clashing
                  // with whichever bucket color sits behind it.
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
