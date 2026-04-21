import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_mode.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/theme/theme_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/login_screen.dart';
import 'user_management_screen.dart';
import 'widgets/dogs_tab.dart';
import 'widgets/volunteers_tab.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final currentLang = locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final appUser = ref.watch(appUserProvider);
    final user = appUser.valueOrNull;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return DefaultTabController(
      length: isSuperAdmin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(l10n.manage),
              if (isDemoMode) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEMO MODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // Auth action
            if (user != null)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: l10n.signOut,
                onPressed: () =>
                    ref.read(appUserProvider.notifier).signOut(),
              )
            else
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: l10n.signIn,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                ),
              ),
            IconButton(
              icon: Text(
                currentLang == 'pl' ? '🇵🇱' : '🇬🇧',
                style: const TextStyle(fontSize: 20),
              ),
              tooltip: l10n.languageToggle,
              onPressed: () {
                ref.read(localeProvider.notifier).toggle();
              },
            ),
            IconButton(
              icon: Icon(
                brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: themeMode == ThemeMode.system
                  ? l10n.usingSystemTheme
                  : (brightness == Brightness.dark ? l10n.switchToLightMode : l10n.switchToDarkMode),
              onPressed: () {
                ref.read(themeModeProvider.notifier).cycle();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.pets), text: l10n.dogsTitleTab),
              Tab(icon: const Icon(Icons.people), text: l10n.volunteersTab),
              if (isSuperAdmin)
                Tab(icon: const Icon(Icons.admin_panel_settings), text: l10n.usersTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DogsTab(),
            const VolunteersTab(),
            if (isSuperAdmin) const UserManagementScreen(),
          ],
        ),
      ),
    );
  }
}
