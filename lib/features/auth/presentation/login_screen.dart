import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../shared/domain/volunteer.dart';
import '../../shared/presentation/providers/volunteer_providers.dart';
import 'auth_providers.dart';

/// Login screen with Google Sign-In and optional volunteer linking.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int? _selectedVolunteerId;
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final volunteersAsync = ref.watch(volunteerListProvider);
    final appUser = ref.watch(appUserProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Volunteer picker
                volunteersAsync.when(
                  data: (volunteers) => _VolunteerPicker(
                    volunteers: volunteers,
                    selectedId: _selectedVolunteerId,
                    onChanged: (id) =>
                        setState(() => _selectedVolunteerId = id),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => Text(l10n.loginVolunteerLoadError),
                ),

                const SizedBox(height: 24),

                // Google Sign-In button
                FilledButton.icon(
                  onPressed: _isSigningIn ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.loginWithGoogle),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                if (appUser.hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l10n.loginError}\n${appUser.error}',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.loginContinueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      await ref.read(appUserProvider.notifier).signInWithGoogle(
            volunteerId: _selectedVolunteerId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }
}

class _VolunteerPicker extends StatelessWidget {
  const _VolunteerPicker({
    required this.volunteers,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Volunteer> volunteers;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: l10n.loginSelectVolunteer,
        helperText: l10n.loginVolunteerHelper,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(l10n.loginNotAVolunteer),
        ),
        ...volunteers.map((v) => DropdownMenuItem<int?>(
              value: v.id,
              child: Text(v.fullName),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
