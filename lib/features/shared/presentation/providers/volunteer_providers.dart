import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../domain/volunteer.dart';

/// Active (non-archived) volunteer list, shared across features.
///
/// Used by the login screen for volunteer linking and anywhere else
/// a simple volunteer list is needed.
final volunteerListProvider = FutureProvider<List<Volunteer>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/api/volunteers') as List;
  return data
      .map((json) => Volunteer.fromJson(json as Map<String, dynamic>))
      .toList();
});
