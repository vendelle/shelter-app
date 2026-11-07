import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_account.dart';
import '../../../auth/presentation/auth_providers.dart';
import 'user_account_dialog.dart';

/// Accounts and invites — super_admin only (see ManageScreen).
class UsersTab extends ConsumerWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(userAccountsProvider);

    return Column(
      children: [
        Expanded(
          child: accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.failed(e.toString()))),
            data: (accounts) => ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) =>
                  _UserTile(account: accounts[index]),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const UserAccountDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.inviteUser),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.account});

  final UserAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMe = ref.watch(currentUserProvider).valueOrNull?.id == account.id;
    final photoUrl = account.photoUrl;

    final details = [
      if (account.displayName != null) account.email,
      if (account.volunteerName != null) account.volunteerName!,
      if (account.invitePending) l10n.invitePending,
    ];

    return ListTile(
      leading: CircleAvatar(
        foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
        child: Icon(account.invitePending ? Icons.mail_outline : Icons.person),
      ),
      title: Text(isMe ? '${account.label} (${l10n.you})' : account.label),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: Chip(
        label: Text(account.role.localizedLabel(l10n)),
        backgroundColor: account.role == UserRole.pending
            ? theme.colorScheme.errorContainer
            : null,
        visualDensity: VisualDensity.compact,
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => UserAccountDialog(account: account, isMe: isMe),
      ),
    );
  }
}
