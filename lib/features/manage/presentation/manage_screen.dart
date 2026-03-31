import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_providers.dart';
import 'widgets/dogs_tab.dart';
import 'widgets/relationships_tab.dart';
import 'widgets/volunteers_tab.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage'),
          actions: [
            IconButton(
              icon: Icon(
                brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: themeMode == ThemeMode.system
                  ? 'Using system theme'
                  : (brightness == Brightness.dark ? 'Switch to light mode' : 'Switch to dark mode'),
              onPressed: () {
                final current = ref.read(themeModeProvider);
                final next = switch (current) {
                  ThemeMode.system => ThemeMode.dark,
                  ThemeMode.dark => ThemeMode.light,
                  ThemeMode.light => ThemeMode.system,
                };
                ref.read(themeModeProvider.notifier).state = next;
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pets), text: 'Dogs'),
              Tab(icon: Icon(Icons.people), text: 'Volunteers'),
              Tab(icon: Icon(Icons.grid_on), text: 'Relations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DogsTab(),
            VolunteersTab(),
            RelationshipsTab(),
          ],
        ),
      ),
    );
  }
}
