import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../dog_detail/presentation/providers/dog_detail_providers.dart';
import '../../../shared/presentation/photo_preload.dart';
import '../providers/manage_providers.dart';
import 'familiarity_dialog.dart';

/// Asks a signed-in volunteer to rate the dogs they haven't rated yet, once
/// per app start. Needs the account linked to a volunteer profile (an admin
/// does that in Manage → Users) and stays quiet once every active dog has a
/// rating. The same [FamiliarityDialog] is available any time in Manage.
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
    if (!_asked) _askIfDogsUnrated();
    return widget.child;
  }

  void _askIfDogsUnrated() {
    final user = ref.watch(permissionsProvider).user;
    final volunteerId = user?.volunteerId;
    if (user == null || !user.role.isAtLeast(UserRole.volunteer)) return;
    if (volunteerId == null) return;

    final dogs = ref.watch(managedDogsProvider).valueOrNull;
    final volunteers = ref.watch(managedVolunteersProvider).valueOrNull;
    final ratings = ref.watch(familiarityProvider(volunteerId)).valueOrNull;
    if (dogs == null || volunteers == null || ratings == null) return;

    final volunteer = volunteers.where((v) => v.id == volunteerId).firstOrNull;
    final anyUnrated = dogs.any(
      (d) => !d.archived && !ratings.containsKey(d.id),
    );
    if (volunteer == null || !anyUnrated) return;

    _asked = true;
    final photos = ref.read(dogPhotoUrlsProvider).valueOrNull;
    if (photos != null) preloadPhotos(photos.values);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => FamiliarityDialog(
          volunteer: volunteer,
          intro: AppLocalizations.of(context)!.familiarityPromptIntro,
        ),
      );
    });
  }
}
