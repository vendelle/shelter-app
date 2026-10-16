import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_account.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../planner/presentation/providers/planner_providers.dart';

/// Invites a new user (no [account]) or edits an existing one's access
/// level and volunteer profile link.
class UserAccountDialog extends ConsumerStatefulWidget {
  const UserAccountDialog({super.key, this.account, this.isMe = false});

  final UserAccount? account;

  /// Your own role can't be changed and your account can't be deleted —
  /// that would risk locking every super admin out.
  final bool isMe;

  @override
  ConsumerState<UserAccountDialog> createState() => _UserAccountDialogState();
}

class _UserAccountDialogState extends ConsumerState<UserAccountDialog> {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late UserRole _role = widget.account?.role ?? UserRole.volunteer;
  late int? _volunteerId = widget.account?.volunteerId;
  bool _saving = false;

  bool get _isInvite => widget.account == null;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await action();
      ref.invalidate(userAccountsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.failedToSave(e is ApiException ? e.message : '$e'),
          ),
        ),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(userRepositoryProvider);
    final account = widget.account;

    _run(() async {
      if (account == null) {
        await repo.invite(
          email: _emailController.text.trim(),
          role: _role,
          volunteerId: _volunteerId,
        );
        return;
      }
      if (_role != account.role) await repo.setRole(account.id, _role);
      if (_volunteerId != account.volunteerId) {
        await repo.setVolunteer(account.id, _volunteerId);
      }
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final account = widget.account!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUserTitle(account.label)),
        content: Text(l10n.deleteUserContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _run(() => ref.read(userRepositoryProvider).delete(account.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = widget.account;
    final volunteers = ref.watch(allVolunteersProvider).valueOrNull ?? [];

    return AlertDialog(
      title: Text(_isInvite ? l10n.inviteUserTitle : account!.label),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isInvite) ...[
                Text(l10n.inviteUserExplanation),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.googleEmail),
                  validator: (value) => _email.hasMatch(value?.trim() ?? '')
                      ? null
                      : l10n.invalidEmail,
                ),
              ] else
                Text(account!.email),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.accessLevel),
                items: [
                  for (final role in UserRole.values)
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.localizedLabel(l10n)),
                    ),
                ],
                onChanged: widget.isMe
                    ? null
                    : (role) => setState(() => _role = role!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _volunteerId,
                decoration:
                    InputDecoration(labelText: l10n.linkedVolunteerProfile),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.none)),
                  for (final v in volunteers)
                    DropdownMenuItem(value: v.id, child: Text(v.fullName)),
                  // Keep a linked-but-archived volunteer selectable.
                  if (_volunteerId != null &&
                      !volunteers.any((v) => v.id == _volunteerId))
                    DropdownMenuItem(
                      value: _volunteerId,
                      child: Text(account?.volunteerName ?? '#$_volunteerId'),
                    ),
                ],
                onChanged: (id) => setState(() => _volunteerId = id),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!_isInvite && !widget.isMe)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(l10n.remove),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_isInvite ? l10n.inviteUser : l10n.save),
        ),
      ],
    );
  }
}
