import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import 'widgets/profile_tab.dart';
import 'widgets/relationships_tab.dart';
import 'widgets/walks_tab.dart';

/// Dog detail view: general profile, relationship overview, and recent walks
/// as separate tabs (mirrors the tab pattern used in ManageScreen).
class DogDetailScreen extends StatelessWidget {
  const DogDetailScreen({
    super.key,
    required this.dogId,
    required this.dogName,
    this.shelterId,
    this.kennel,
    this.region,
  });

  final int dogId;
  final String dogName;
  final String? shelterId;
  final String? kennel;
  final String? region;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      // Buddies is the default tab for now — it's what volunteers check
      // most when opening a dog's profile.
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(dogName),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.badge_outlined), text: l10n.profileTab),
              Tab(icon: const Icon(Icons.diversity_3_outlined), text: l10n.relationships),
              Tab(icon: const Icon(Icons.history_rounded), text: l10n.walksTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProfileTab(
              dogName: dogName,
              shelterId: shelterId,
              kennel: kennel,
              region: region,
            ),
            RelationshipsTab(dogId: dogId),
            WalksTab(dogId: dogId),
          ],
        ),
      ),
    );
  }
}
