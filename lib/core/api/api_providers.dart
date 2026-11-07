import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiClient.defaultBaseUrl,
    idToken: ref.watch(authServiceProvider).idToken,
  );
});
