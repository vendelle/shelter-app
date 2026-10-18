import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../auth_providers.dart';
import 'account_button.dart';
import 'export_only_screen.dart';

/// Shows the app only to approved accounts. Everyone else — signed out or
/// waiting for approval — gets just the [AccountPanel], so volunteers'
/// names and walk history aren't public. The shelter's export-only accounts
/// get just the [ExportOnlyScreen].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    if (permissions.canView) return child;
    if (permissions.isExporter) {
      // The gate sits above the app's navigator; the export's date pickers
      // need one of their own.
      return Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const ExportOnlyScreen()),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const AccountPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
