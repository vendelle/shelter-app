import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiClient.defaultBaseUrl,
    authTokenProvider: () async {
      final user = FirebaseAuth.instance.currentUser;
      return user?.getIdToken();
    },
  );
});
