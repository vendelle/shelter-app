import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../shared/presentation/shelter_image.dart';
import '../../domain/shelter_profile.dart';
import '../providers/dog_detail_providers.dart';
import 'detail_tab_scaffold.dart';

/// Wider than this, the description moves into a second column.
const _twoColumnWidth = 760.0;

/// A dog's profile: our data (name, shelter ID, kennel, region) combined
/// with what the shelter's website says — photo and quick facts up top,
/// details and description below (beside, on wide screens).
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
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(shelterProfileProvider(dogId));
    final profile = profileAsync.valueOrNull;
    final canManage = ref.watch(permissionsProvider).canManageData;

    final header = _Header(
      dogName: dogName,
      shelterId: shelterId,
      kennel: profile?.kennel ?? kennel,
      region: profile?.region ?? region,
      profile: profile,
    );
    final suggestion = profile?.locationSuggestion != null && canManage
        ? _LocationSuggestionCard(dogId: dogId, profile: profile!)
        : null;

    return DetailTabScaffold(
      maxWidth: 1000,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnWidth;
            final main = <Widget>[
              header,
              if (suggestion != null) ...[
                const SizedBox(height: 12),
                suggestion,
              ],
              const SizedBox(height: 16),
              profileAsync.when(
                // Keep showing the previous data while a refresh is in flight.
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text(l10n.shelterLoadFailed),
                data: (profile) => profile.found
                    ? _Facts(profile: profile)
                    : _NotFound(profile: profile, shelterId: shelterId),
              ),
            ];
            final description = profile?.found == true
                ? profile!.description
                : null;
            final footer =
                profile == null ? null : _Footer(dogId: dogId, profile: profile);

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...main,
                  if (description != null) _Description(text: description),
                  if (footer != null) ...[const SizedBox(height: 16), footer],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: main,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 4,
                      child: description == null
                          ? const SizedBox.shrink()
                          : _Description(text: description, collapsed: false),
                    ),
                  ],
                ),
                if (footer != null) ...[const SizedBox(height: 24), footer],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header: photo, name, status, kennel
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.dogName,
    required this.shelterId,
    required this.kennel,
    required this.region,
    required this.profile,
  });

  final String dogName;
  final String? shelterId;
  final String? kennel;
  final String? region;
  final ShelterProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final website = profile?.found == true ? profile : null;
    final photoUrl = website?.photoUrl;
    final status = website?.status;
    final place = [
      if (kennel != null && kennel!.isNotEmpty) 'K: $kennel',
      if (region != null && region!.isNotEmpty) region!,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Photo(url: photoUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: dogName,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (shelterId != null && shelterId!.isNotEmpty)
                    TextSpan(
                      text: '  $shelterId',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                ]),
              ),
              if (status != null) ...[
                const SizedBox(height: 6),
                _StatusChip(status: status),
              ],
              if (place.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(place, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  static const _size = 112.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = this.url;
    final placeholder = Icon(Icons.pets, size: 40, color: colors.outline);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: _size,
        height: _size,
        color: colors.surfaceContainerHighest,
        child: url == null
            ? placeholder
            : InkWell(
                onTap: () => _showFullSize(context, url),
                child: ShelterImage(url,
                    fit: BoxFit.cover, error: placeholder),
              ),
      ),
    );
  }

  void _showFullSize(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ShelterImage(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  /// Statuses meaning the dog has left the shelter.
  static const _departed = {'Adopcja', 'Odbiór', 'Ucieczka', 'Zmarł'};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      'Do adopcji' => (colors.primaryContainer, colors.onPrimaryContainer),
      'Kwarantanna' => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ when _departed.contains(status) =>
        (colors.surfaceContainerHighest, colors.onSurfaceVariant),
      _ => (colors.secondaryContainer, colors.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Facts from the website
// ---------------------------------------------------------------------------

class _Facts extends StatelessWidget {
  const _Facts({required this.profile});

  final ShelterProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('dd.MM.yyyy', locale);
    final today = DateTime.now();

    final age = profile.ageOn(today);
    final weight = profile.weightKg;
    final neutered = profile.neutered;
    final sex = profile.sex;
    final tiles = [
      if (age != null)
        _FactTile(
          icon: Icons.cake_outlined,
          label: l10n.shelterAge,
          value: _span(l10n, age),
        ),
      if (sex != null)
        _FactTile(
          icon: switch (sex) {
            'Samiec' => Icons.male,
            'Samica' => Icons.female,
            _ => Icons.pets,
          },
          label: l10n.shelterSex,
          value: switch (sex) {
            'Samiec' => l10n.sexMale,
            'Samica' => l10n.sexFemale,
            _ => sex,
          },
        ),
      if (weight != null)
        _FactTile(
          icon: Icons.monitor_weight_outlined,
          label: l10n.shelterWeight,
          value: '${NumberFormat.decimalPattern(locale).format(weight)} kg',
        ),
      if (neutered != null)
        _FactTile(
          icon: Icons.content_cut,
          label: l10n.shelterNeutered,
          value: neutered ? l10n.yes : l10n.no,
        ),
    ];

    final arrival = profile.arrivalDate;
    final departure = profile.departureDate;
    final inShelter = [
      if (arrival != null)
        l10n.shelterSince(
          _span(
            l10n,
            _monthsBetween(arrival, departure ?? today),
            (departure ?? today).difference(arrival).inDays,
          ),
          dateFormat.format(arrival),
        ),
      ?profile.arrivalReason,
      if (departure != null) l10n.shelterLeft(dateFormat.format(departure)),
      if (profile.location != null)
        l10n.shelterKennelOnSite(profile.location!),
    ];
    final looks =
        [profile.breed, profile.color].whereType<String>().join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tiles.isNotEmpty) _TileGrid(tiles: tiles),
        if (inShelter.isNotEmpty)
          _Section(title: l10n.shelterSectionInShelter, lines: inShelter),
        if (looks.isNotEmpty)
          _Section(title: l10n.shelterSectionLooks, lines: [looks]),
      ],
    );
  }

  /// "5 lat, 9 mies." / "3 mies." / "12 dni".
  static String _span(AppLocalizations l10n, ({int years, int months}) span,
      [int? days]) {
    if (span.years > 0) return l10n.ageYearsMonths(span.years, span.months);
    if (span.months > 0 || days == null) return l10n.ageMonths(span.months);
    return l10n.durationDays(days);
  }

  static ({int years, int months}) _monthsBetween(DateTime from, DateTime to) {
    var months = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) months--;
    if (months < 0) months = 0;
    return (years: months ~/ 12, months: months % 12);
  }
}

/// Equal-width tiles: all in one row when each gets [_minTileWidth],
/// otherwise two per row — never a lone tile on the last row of a phone.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  static const _minTileWidth = 110.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final oneRow = tiles.length * _minTileWidth +
              (tiles.length - 1) * _gap <=
          width;
      final columns = oneRow ? tiles.length : 2;
      final tileWidth = (width - (columns - 1) * _gap) / columns;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
        ],
      );
    });
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleSmall),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          for (final line in lines)
            Text(line, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.text, this.collapsed = true});

  final String text;

  /// Starts folded to a few lines (narrow screens).
  final bool collapsed;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  static const _collapsedLines = 5;

  late bool _collapsed = widget.collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shelterSectionDescription,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              maxLines: _collapsedLines,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            // Only foldable text gets the toggle (not the wide layout).
            final overflows = widget.collapsed && painter.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  widget.text,
                  style: style,
                  maxLines: _collapsed && overflows ? _collapsedLines : null,
                ),
                if (overflows)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    child: Text(_collapsed
                        ? l10n.descriptionShowMore
                        : l10n.descriptionShowLess),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.profile, required this.shelterId});

  final ShelterProfile profile;
  final String? shelterId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Text(
      profile.url == null
          ? l10n.shelterNoPage
          : l10n.shelterNotFound(shelterId ?? '?'),
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer: source, refresh, link
// ---------------------------------------------------------------------------

/// "Ze strony schroniska · odświeżono 2 godz. temu · ⟳ · ↗".
class _Footer extends ConsumerStatefulWidget {
  const _Footer({required this.dogId, required this.profile});

  final int dogId;
  final ShelterProfile profile;

  @override
  ConsumerState<_Footer> createState() => _FooterState();
}

class _FooterState extends ConsumerState<_Footer> {
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
            SnackBar(content: Text(l10n.shelterRefreshFailed)));
      }
    } catch (_) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.shelterRefreshFailed)));
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
    final small = TextButton.styleFrom(
      textStyle: theme.textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          [
            l10n.shelterSectionTitle,
            if (fetchedAt != null) _fetchedLabel(l10n, fetchedAt),
          ].join(' · '),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        TextButton.icon(
          style: small,
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
            style: small,
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
    return l10n
        .shelterFetchedOn(DateFormat('dd.MM.yyyy HH:mm').format(fetchedAt));
  }
}

// ---------------------------------------------------------------------------
// Admin: website kennel differs from ours
// ---------------------------------------------------------------------------

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
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.failedToSave(e is ApiException ? e.message : '$e')),
      ));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = widget.profile;
    final ours =
        [profile.kennel, profile.region].whereType<String>().join(' ');
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
