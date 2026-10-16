import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../data/auth_service.dart';
import '../../domain/app_user.dart';
import '../auth_providers.dart';
import '../in_app_browser.dart';

/// App bar action: the account avatar when signed in, a sign-in icon when
/// not. Opens the account sheet either way.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final photoUrl = user?.photoUrl;

    return IconButton(
      tooltip: user == null ? l10n.signIn : l10n.account,
      onPressed: () => showAccountSheet(context),
      icon: user == null
          ? const Icon(Icons.login)
          : CircleAvatar(
              radius: 14,
              foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
              child: Text(_initial(user)),
            ),
    );
  }
}

String _initial(AppUser user) =>
    (user.displayName ?? user.email).characters.first.toUpperCase();

Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _AccountSheet(),
      ),
    ),
  );
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(currentUserProvider);
    return account.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _SignedInError(error: error),
      data: (user) =>
          user == null ? const _SignedOut() : _SignedIn(user: user),
    );
  }
}

class _SignedOut extends ConsumerStatefulWidget {
  const _SignedOut();

  @override
  ConsumerState<_SignedOut> createState() => _SignedOutState();
}

class _SignedOutState extends ConsumerState<_SignedOut> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _signingIn = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } on SignInException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_failureMessage(l10n, e))),
      );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (isInAppBrowser()) return const _OpenInBrowser();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.signIn, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.signInExplanation, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _signingIn ? null : _signIn,
          icon: _signingIn
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.account_circle_outlined),
          label: Text(l10n.signInWithGoogle),
        ),
      ],
    );
  }
}

String _failureMessage(AppLocalizations l10n, SignInException e) {
  return switch (e.failure) {
    SignInFailure.popupBlocked => l10n.signInPopupBlocked,
    SignInFailure.unauthorizedDomain => l10n.signInUnauthorizedDomain,
    SignInFailure.network => l10n.signInNetworkError,
    SignInFailure.unknown => l10n.signInFailed(e.code ?? '?'),
  };
}

/// Shown inside Facebook/Messenger etc., where Google blocks sign-in.
class _OpenInBrowser extends StatelessWidget {
  const _OpenInBrowser();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.openInBrowserTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.openInBrowserMessage, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
            messenger.showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l10n.copyLink),
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final photoUrl = user.photoUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
            child: Text(_initial(user)),
          ),
          title: Text(user.displayName ?? user.email),
          subtitle: Text(user.email),
        ),
        Text(
          '${l10n.accessLevel}: ${user.role.localizedLabel(l10n)}',
          style: theme.textTheme.bodyMedium,
        ),
        if (user.role == UserRole.pending) ...[
          const SizedBox(height: 8),
          Text(
            l10n.accountPendingMessage,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ref.read(authServiceProvider).signOut();
          },
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
        ),
      ],
    );
  }
}

/// Signed in to Google, but the API refused or failed to load the account.
class _SignedInError extends ConsumerWidget {
  const _SignedInError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.accountLoadFailed(error.toString())),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => ref.invalidate(currentUserProvider),
          child: Text(l10n.retry),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
        ),
      ],
    );
  }
}
