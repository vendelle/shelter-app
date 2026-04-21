import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../core/api/api_providers.dart';
import '../../auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _authRepoProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final _usersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(_authRepoProvider);
  return repo.listUsers();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final usersAsync = ref.watch(_usersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(l10n.failed(e.toString())),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Text(l10n.noUsersFound));
        }

        // Group: pending first, then by role
        final pending =
            users.where((u) => u['role'] == 'pending').toList();
        final approved =
            users.where((u) => u['role'] != 'pending').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              _SectionHeader(
                title: l10n.pendingApproval,
                count: pending.length,
                color: theme.colorScheme.error,
              ),
              ...pending.map((u) => _UserTile(
                    user: u,
                    onRoleChanged: () => ref.invalidate(_usersProvider),
                  )),
              const SizedBox(height: 24),
            ],
            if (approved.isNotEmpty) ...[
              _SectionHeader(
                title: l10n.active,
                count: approved.length,
              ),
              ...approved.map((u) => _UserTile(
                    user: u,
                    onRoleChanged: () => ref.invalidate(_usersProvider),
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.color,
  });

  final String title;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Badge(
            label: Text('$count'),
            backgroundColor: color ?? theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.onRoleChanged});

  final Map<String, dynamic> user;
  final VoidCallback onRoleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final role = user['role'] as String;
    final email = user['email'] as String;
    final displayName = user['display_name'] as String?;
    final volFirst = user['volunteer_first_name'] as String?;
    final volLast = user['volunteer_last_name'] as String?;
    final volunteerName =
        (volFirst != null && volLast != null) ? '$volFirst $volLast' : null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(role, theme),
          child: Text(
            (displayName ?? email).substring(0, 1).toUpperCase(),
            style: TextStyle(color: _roleColor(role, theme).computeLuminance() > 0.5
                ? Colors.black
                : Colors.white),
          ),
        ),
        title: Text(displayName ?? email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayName != null)
              Text(email, style: theme.textTheme.bodySmall),
            Row(
              children: [
                _RoleBadge(role: role),
                if (volunteerName != null) ...[
                  const SizedBox(width: 8),
                  Text('→ $volunteerName',
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: displayName != null,
        trailing: PopupMenuButton<String>(
          onSelected: (newRole) =>
              _changeRole(context, ref, newRole, l10n),
          itemBuilder: (_) => [
            for (final r in ['volunteer', 'admin', 'super_admin'])
              if (r != role)
                PopupMenuItem(
                  value: r,
                  child: Text(_roleLabel(r, l10n)),
                ),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    String newRole,
    AppLocalizations l10n,
  ) async {
    final repo = ref.read(_authRepoProvider);
    try {
      await repo.updateUser(
        userId: user['id'] as int,
        role: newRole,
      );
      onRoleChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failed(e.toString()))),
        );
      }
    }
  }

  Color _roleColor(String role, ThemeData theme) {
    return switch (role) {
      'pending' => theme.colorScheme.error,
      'volunteer' => theme.colorScheme.primary,
      'admin' => theme.colorScheme.tertiary,
      'super_admin' => theme.colorScheme.secondary,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    return switch (role) {
      'pending' => l10n.userRolePending,
      'volunteer' => l10n.userRoleVolunteer,
      'admin' => l10n.userRoleAdmin,
      'super_admin' => l10n.userRoleSuperAdmin,
      _ => role,
    };
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = switch (role) {
      'pending' => theme.colorScheme.error,
      'volunteer' => theme.colorScheme.primary,
      'admin' => theme.colorScheme.tertiary,
      'super_admin' => theme.colorScheme.secondary,
      _ => theme.colorScheme.outline,
    };
    final label = switch (role) {
      'pending' => l10n.userRolePending,
      'volunteer' => l10n.userRoleVolunteer,
      'admin' => l10n.userRoleAdmin,
      'super_admin' => l10n.userRoleSuperAdmin,
      _ => role,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
