import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../core/debug_logger.dart';
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
  bool _showDebugLogs = false;

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

                const SizedBox(height: 16),
                
                // Debug logs (expandable)
                _DebugLogsWidget(
                  showLogs: _showDebugLogs,
                  onToggle: () => setState(() => _showDebugLogs = !_showDebugLogs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    DebugLogger.log('Sign-in button clicked');
    setState(() => _isSigningIn = true);
    try {
      DebugLogger.log('Calling signInWithGoogle...');
      await ref.read(appUserProvider.notifier).signInWithGoogle(
            volunteerId: _selectedVolunteerId,
          );
      // Note: On redirect-based flows, the page may redirect to Google.
      // When the user returns, appUserProvider will automatically update
      // and the router will navigate away from login screen.
      // The following pop is only reached on mobile where it returns synchronously.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      DebugLogger.log('Error in _signIn: $e');
      if (mounted) rethrow;
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

/// Debug logs widget that displays persisted logs from SharedPreferences.
class _DebugLogsWidget extends ConsumerStatefulWidget {
  const _DebugLogsWidget({
    required this.showLogs,
    required this.onToggle,
  });

  final bool showLogs;
  final VoidCallback onToggle;

  @override
  ConsumerState<_DebugLogsWidget> createState() => _DebugLogsWidgetState();
}

class _DebugLogsWidgetState extends ConsumerState<_DebugLogsWidget> {
  Future<void> _copyLogsToClipboard() async {
    final logs = await DebugLogger.getLogs();
    if (logs.isEmpty) return;
    
    final logText = logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearLogs() async {
    await DebugLogger.clearLogs();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: widget.onToggle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.showLogs
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.showLogs ? 'Hide Debug Logs' : 'Show Debug Logs',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showLogs) ...[
              IconButton(
                onPressed: _copyLogsToClipboard,
                icon: const Icon(Icons.copy),
                iconSize: 16,
                tooltip: 'Copy logs',
              ),
              IconButton(
                onPressed: _clearLogs,
                icon: const Icon(Icons.delete_outline),
                iconSize: 16,
                tooltip: 'Clear logs',
              ),
            ],
          ],
        ),
        if (widget.showLogs)
          FutureBuilder<List<String>>(
            future: DebugLogger.getLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'No logs yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final logs = snapshot.data!;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 0.5,
                  ),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    logs.join('\n'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
