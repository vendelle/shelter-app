import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/volunteer_detail_repository.dart';
import '../../domain/volunteer_profile.dart';

final volunteerDetailRepositoryProvider =
    Provider<VolunteerDetailRepository>((ref) {
  return ApiVolunteerDetailRepository(ref.watch(apiClientProvider));
});

final volunteerProfileProvider =
    FutureProvider.family<VolunteerProfile, int>((ref, volunteerId) {
  return ref.watch(volunteerDetailRepositoryProvider).getProfile(volunteerId);
});
