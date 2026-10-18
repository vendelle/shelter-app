import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../shared/presentation/shelter_image.dart';
import '../auth_providers.dart';
import 'account_button.dart';

/// The sign-in screen for signed-out visitors: a 4×4 grid whose border is
/// photos of the group's current dogs, with the logo, the app's name and
/// the sign-in button in the middle 2×2.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const _gap = 6.0;
  static const _maxSide = 560.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(welcomePhotosProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = min(
              min(constraints.maxWidth, constraints.maxHeight) - 32,
              _maxSide,
            );
            final tile = (side - 3 * _gap) / 4;
            Widget photo(int i) => _PhotoTile(
                  url: i < photos.length ? photos[i] : null,
                  size: tile,
                );

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: _gap,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: _gap,
                      children: [for (var i = 0; i < 4; i++) photo(i)],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: _gap,
                      children: [
                        Column(spacing: _gap, children: [photo(4), photo(5)]),
                        _Centre(size: 2 * tile + _gap),
                        Column(spacing: _gap, children: [photo(6), photo(7)]),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: _gap,
                      children: [for (var i = 8; i < 12; i++) photo(i)],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A dog's photo, or a paw while it loads or when there's none.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = this.url;
    final placeholder = Icon(
      Icons.pets,
      size: size / 3,
      color: colors.outlineVariant,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: colors.surfaceContainerHighest,
        child: url == null
            ? placeholder
            : ShelterImage(url, fit: BoxFit.cover, error: placeholder),
      ),
    );
  }
}

class _Centre extends StatelessWidget {
  const _Centre({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: size,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/welcome-logo.png',
              height: (size * 0.28).clamp(40, 72),
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context)!.appTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            const AccountPanel(compact: true),
          ],
        ),
      ),
    );
  }
}
