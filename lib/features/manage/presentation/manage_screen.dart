import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_provider.dart';
import '../../../core/theme/theme_providers.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.manage),
          actions: [
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DogsTab(),
            VolunteersTab(),
          ],
        ),
      ),
    );
  }
}
