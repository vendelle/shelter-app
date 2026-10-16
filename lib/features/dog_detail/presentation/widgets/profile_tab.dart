import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/shelter_profile.dart';
import '../providers/dog_detail_providers.dart';
import 'detail_tab_scaffold.dart';

/// A dog's profile: our data (name, shelter ID, kennel, region) and below it
/// what the shelter's website says, with when that was last refreshed.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({
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

  /// Shown until the profile loads, which carries the current values.
  final String? kennel;
  final String? region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(shelterProfileProvider(dogId));
    final profile = profileAsync.valueOrNull;

    final currentKennel = profile?.kennel ?? kennel;
    final currentRegion = profile?.region ?? region;
    final chips = <String>[
      if (currentKennel != null && currentKennel.isNotEmpty)
        'K: $currentKennel',
      if (currentRegion != null && currentRegion.isNotEmpty) currentRegion,
    ];
    final photoUrl = profile?.photoUrl;

    return DetailTabScaffold(
      children: [
        if (photoUrl != null) ...[
          _Photo(url: photoUrl),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                dogName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (shelterId != null && shelterId!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                shelterId!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: chips
                .map(
                  (c) => Chip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
        if (profile?.locationSuggestion != null &&
            ref.watch(permissionsProvider).canManageData) ...[
          const SizedBox(height: 12),
          _LocationSuggestionCard(dogId: dogId, profile: profile!),
        ],
        const SizedBox(height: 24),
        Text(l10n.shelterSectionTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        profileAsync.when(
          // Keep showing the previous data while a refresh is in flight.
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.shelterLoadFailed),
          data: (profile) =>
              _ShelterDetails(profile: profile, shelterId: shelterId),
        ),
        if (profile != null) ...[
          const SizedBox(height: 16),
          _RefreshRow(dogId: dogId, profile: profile),
        ],
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // The shelter's image server sends no CORS headers, which Flutter
          // web needs to draw fetched bytes — an <img> element doesn't.
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ShelterDetails extends StatelessWidget {
  const _ShelterDetails({required this.profile, required this.shelterId});

  final ShelterProfile profile;
  final String? shelterId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('dd.MM.yyyy', locale);

    if (!profile.found) {
      return Text(
        profile.url == null
            ? l10n.shelterNoPage
            : l10n.shelterNotFound(shelterId ?? '?'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final age = profile.ageOn(DateTime.now());
    final weight = profile.weightKg;
    final neutered = profile.neutered;
    final arrival = profile.arrivalDate;
    final departure = profile.departureDate;
    final facts = <(String, String?)>[
      (l10n.shelterStatus, profile.status),
      (
        l10n.shelterAge,
        age == null
            ? null
            : age.years > 0
            ? l10n.ageYearsMonths(age.years, age.months)
            : l10n.ageMonths(age.months),
      ),
      (l10n.shelterSex, profile.sex),
      (
        l10n.shelterWeight,
        weight == null
            ? null
            : '${NumberFormat.decimalPattern(locale).format(weight)} kg',
      ),
      (l10n.shelterBreed, profile.breed),
      (l10n.shelterColor, profile.color),
      (
        l10n.shelterNeutered,
        neutered == null ? null : (neutered ? l10n.yes : l10n.no),
      ),
      (
        l10n.shelterArrival,
        arrival == null
            ? null
            : [dateFormat.format(arrival), ?profile.arrivalReason].join(' · '),
      ),
      (
        l10n.shelterDeparture,
        departure == null ? null : dateFormat.format(departure),
      ),
      (l10n.shelterLocation, profile.location),
    ];
    final description = profile.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in facts)
          if (value != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        if (description != null) ...[
          const SizedBox(height: 12),
          SelectableText(description, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// "Odświeżono 2 godz. temu · [Odśwież teraz] · [Zobacz na stronie]".
class _RefreshRow extends ConsumerStatefulWidget {
  const _RefreshRow({required this.dogId, required this.profile});

  final int dogId;
  final ShelterProfile profile;

  @override
  ConsumerState<_RefreshRow> createState() => _RefreshRowState();
}

class _RefreshRowState extends ConsumerState<_RefreshRow> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _refreshing = true);
    try {
      final profile = await ref
          .read(shelterProfileProvider(widget.dogId).notifier)
          .refresh();
      if (profile.refreshFailed) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.shelterRefreshFailed)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.shelterRefreshFailed)),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = widget.profile;
    final fetchedAt = profile.fetchedAt;
    final url = profile.url;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        if (fetchedAt != null)
          Text(
            _fetchedLabel(l10n, fetchedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        TextButton.icon(
          onPressed: _refreshing || !profile.canRefresh() ? null : _refresh,
          icon: _refreshing
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: Text(l10n.shelterRefresh),
        ),
        if (url != null)
          TextButton.icon(
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l10n.shelterWebsiteLink),
          ),
      ],
    );
  }

  String _fetchedLabel(AppLocalizations l10n, DateTime fetchedAt) {
    final ago = DateTime.now().difference(fetchedAt);
    if (ago.inMinutes < 1) return l10n.shelterFetchedJustNow;
    if (ago.inHours < 1) return l10n.shelterFetchedMinutesAgo(ago.inMinutes);
    if (ago.inDays < 1) return l10n.shelterFetchedHoursAgo(ago.inHours);
    return l10n.shelterFetchedOn(
      DateFormat('dd.MM.yyyy HH:mm').format(fetchedAt),
    );
  }
}

/// Admin-only: the website lists another kennel/region than we have.
class _LocationSuggestionCard extends ConsumerStatefulWidget {
  const _LocationSuggestionCard({required this.dogId, required this.profile});

  final int dogId;
  final ShelterProfile profile;

  @override
  ConsumerState<_LocationSuggestionCard> createState() =>
      _LocationSuggestionCardState();
}

class _LocationSuggestionCardState
    extends ConsumerState<_LocationSuggestionCard> {
  bool _saving = false;

  Future<void> _resolve({required bool accept}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      // On success the card disappears with the suggestion.
      await ref
          .read(shelterProfileProvider(widget.dogId).notifier)
          .resolveLocationSuggestion(accept: accept);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.failedToSave(e is ApiException ? e.message : '$e'),
          ),
        ),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = widget.profile;
    final ours = [profile.kennel, profile.region].whereType<String>().join(' ');
    final onCard = theme.colorScheme.onTertiaryContainer;

    return Card(
      color: theme.colorScheme.tertiaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.locationSuggestionTitle(profile.location ?? ''),
              style: theme.textTheme.titleSmall?.copyWith(color: onCard),
            ),
            Text(
              l10n.locationSuggestionOurs(ours),
              style: theme.textTheme.bodySmall?.copyWith(color: onCard),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => _resolve(accept: false),
                  child: Text(l10n.locationSuggestionIgnore),
                ),
                FilledButton.tonal(
                  onPressed: _saving ? null : () => _resolve(accept: true),
                  child: Text(l10n.locationSuggestionAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
