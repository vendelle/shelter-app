import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/dogs_tab.dart';
import 'widgets/volunteers_tab.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pets), text: 'Dogs'),
              Tab(icon: Icon(Icons.people), text: 'Volunteers'),
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
