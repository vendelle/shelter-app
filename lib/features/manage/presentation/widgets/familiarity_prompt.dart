import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../../core/locale/locale_provider.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../dog_detail/presentation/providers/dog_detail_providers.dart';
import '../../../shared/presentation/photo_preload.dart';
import '../providers/manage_providers.dart';
import 'familiarity_dialog.dart';

/// How long "remind me later" keeps the prompt away.
const familiarityPromptSnooze = Duration(days: 14);

/// Per volunteer, so a shared browser doesn't carry one person's choice over
/// to another. Holds the time (ms since epoch) the prompt may come back.
String familiarityPromptSnoozeKey(int volunteerId) =>
    'familiarity_prompt_snoozed_until_$volunteerId';

/// Asks a signed-in volunteer to rate the dogs they haven't rated yet, once
/// per page load, unless they chose "remind me later" (kept in the browser's
/// local storage, not the database). Needs the account linked to a volunteer
/// profile (an admin does that in Manage → Users) and stays quiet when every
/// active dog has a rating or the ratings can't be loaded. The same
/// [FamiliarityDialog] is available any time in Manage.
class FamiliarityPrompt extends ConsumerStatefulWidget {
  const FamiliarityPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FamiliarityPrompt> createState() => _FamiliarityPromptState();
}

class _FamiliarityPromptState extends ConsumerState<FamiliarityPrompt> {
  bool _asked = false;

  @override
  Widget build(BuildContext context) {
    _askIfDogsUnrated();
    return widget.child;
  }

  void _askIfDogsUnrated() {
    final user = ref.watch(permissionsProvider).user;
    final volunteerId = user?.volunteerId;
    final dogs = volunteerId == null ? null : ref.watch(managedDogsProvider);
    final volunteers =
        volunteerId == null ? null : ref.watch(managedVolunteersProvider);
    final ratings = volunteerId == null
        ? null
        : ref.watch(familiarityProvider(volunteerId));
    final photos = ref.watch(dogPhotoUrlsProvider).valueOrNull;

    if (_asked || user == null || !user.role.isAtLeast(UserRole.volunteer)) {
      return;
    }
    if (volunteerId == null || _isSnoozed(volunteerId)) return;
    // A failed request is not "nothing rated" — stay quiet instead.
    final dogList = dogs?.valueOrNull;
    final volunteerList = volunteers?.valueOrNull;
    final ratingMap = ratings?.valueOrNull;
    if (dogList == null || volunteerList == null || ratingMap == null) return;

    final volunteer =
        volunteerList.where((v) => v.id == volunteerId).firstOrNull;
    final anyUnrated =
        dogList.any((d) => !d.archived && !ratingMap.containsKey(d.id));
    if (volunteer == null || !anyUnrated) return;

    _asked = true;
    if (photos != null) preloadPhotos(photos.values);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => FamiliarityDialog(
          volunteer: volunteer,
          intro: AppLocalizations.of(context)!.familiarityPromptIntro,
          onRemindLater: () => _snooze(volunteerId),
        ),
      );
    });
  }

  bool _isSnoozed(int volunteerId) {
    final until = ref
        .read(sharedPreferencesProvider)
        .getInt(familiarityPromptSnoozeKey(volunteerId));
    return until != null && DateTime.now().millisecondsSinceEpoch < until;
  }

  void _snooze(int volunteerId) {
    final until = DateTime.now().add(familiarityPromptSnooze);
    ref
        .read(sharedPreferencesProvider)
        .setInt(familiarityPromptSnoozeKey(volunteerId),
            until.millisecondsSinceEpoch);
  }
}
