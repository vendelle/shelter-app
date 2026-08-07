import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../domain/volunteer_assignment.dart';
import 'group_colors.dart';

/// Renders the planner assignments to an image based on current detail level.

/// Renders the planner assignments to an image and opens the native share sheet.
/// If [detailed] is true, shares full dog info (name, ID, kennel, region).
Future<void> sharePlannerImage({
  required BuildContext context,
  required DateTime date,
  required List<VolunteerAssignment> assignments,
  required int totalDogs,
  bool detailed = false,
}) async {
  final theme = Theme.of(context);
  final brightness = theme.brightness;
  final locale = Localizations.localeOf(context).languageCode;

  // Determine columns + image width
  final n = assignments.length;
  final cols = columnsForVolunteerCount(n);
  final logicalWidth = switch (cols) {
    1 => 420.0,
    2 => 700.0,
    _ => 1000.0,
  };

  final widget = PlannerShareLayout(
    date: date,
    assignments: assignments,
    totalDogs: totalDogs,
    brightness: brightness,
    detailed: detailed,
    cols: cols,
    imageWidth: logicalWidth,
    locale: locale,
  );

  final imageBytes = await _renderWidgetToImage(
    widget: widget,
    context: context,
    logicalWidth: logicalWidth,
  );

  if (imageBytes == null || !context.mounted) return;

  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final xFile = XFile.fromData(
    Uint8List.fromList(imageBytes),
    mimeType: 'image/png',
    name: 'plan-$dateStr.png',
  );

  await Share.shareXFiles([xFile]);
}

/// Determines the number of grid columns for [n] volunteers.
///
/// Counts up to 3 map 1:1 to columns. 4 is special-cased to a 2x2 square
/// instead of a lopsided 3-then-1 row. Anything larger caps at 3 columns.
int columnsForVolunteerCount(int n) {
  if (n <= 1) return 1;
  if (n == 4) return 2;
  return n.clamp(1, 3);
}

/// Renders a widget off-screen to a PNG byte buffer.
/// Lays out with unconstrained height so the full content is captured.
Future<List<int>?> _renderWidgetToImage({
  required Widget widget,
  required BuildContext context,
  required double logicalWidth,
}) async {
  final view = View.of(context);
  final devicePixelRatio = view.devicePixelRatio;
  final theme = Theme.of(context);

  // Create the pipeline
  final repaintBoundary = RenderRepaintBoundary();
  final renderPositioned = RenderPositionedBox(
    alignment: Alignment.topLeft,
    child: repaintBoundary,
  );

  final pipelineOwner = PipelineOwner();
  final focusManager = FocusManager();
  final buildOwner = BuildOwner(focusManager: focusManager);

  final renderView = RenderView(
    view: view,
    child: renderPositioned,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints(
        minWidth: logicalWidth,
        maxWidth: logicalWidth,
        maxHeight: 8000, // generous max
      ),
      devicePixelRatio: devicePixelRatio,
    ),
  );
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final themedWidget = MediaQuery(
    data: MediaQueryData(
      size: Size(logicalWidth, 8000),
      devicePixelRatio: devicePixelRatio,
    ),
    child: Theme(
      data: theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ),
  );

  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: logicalWidth,
        minWidth: logicalWidth,
      ),
      child: themedWidget,
    ),
  ).attachToRenderTree(buildOwner);

  try {
    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    buildOwner.finalizeTree();

    return byteData?.buffer.asUint8List();
  } finally {
    focusManager.dispose();
  }
}

// ---------------------------------------------------------------------------
// Static layout widget for the share image
// ---------------------------------------------------------------------------

/// Builds the static plan layout used for sharing. Public for testing.
class PlannerShareLayout extends StatelessWidget {
  const PlannerShareLayout({
    super.key,
    required this.date,
    required this.assignments,
    required this.totalDogs,
    required this.brightness,
    this.detailed = false,
    this.cols = 2,
    this.imageWidth = 800,
    this.locale = 'pl',
  });

  final DateTime date;
  final List<VolunteerAssignment> assignments;
  final int totalDogs;
  final Brightness brightness;
  final bool detailed;
  final int cols;
  final double imageWidth;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dogCount =
        assignments.fold<int>(0, (sum, a) => sum + a.dogs.length);

    const gap = 6.0;
    const padding = 12.0;
    final colWidth = cols > 0
        ? (imageWidth - 2 * padding - (cols - 1) * gap) / cols
        : imageWidth - 2 * padding;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              formatShareDate(date, locale),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          // Volunteer grid — max 3 per row
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final assignment in assignments)
                SizedBox(
                  width: colWidth,
                  child: _ShareVolunteerCard(
                    assignment: assignment,
                    brightness: brightness,
                    detailed: detailed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Summary footer — localized volunteer/dog count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Po spacerze sprawdź, czy pies nie ma kleszczy ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              Icon(
                Icons.pest_control,
                size: 16,
                color: colorScheme.outline,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.nVolunteersNDogs(
                  assignments.length,
                  dogCount,
                  totalDogs,
                ) ??
                _localizedSummaryFallback(
                  assignments.length,
                  dogCount,
                  totalDogs,
                  locale,
                ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Fallback summary text when AppLocalizations is unavailable.
String _localizedSummaryFallback(
  int volunteers,
  int dogs,
  int totalDogs,
  String locale,
) {
  if (locale == 'pl') {
    return '$volunteers wolo  •  $dogs/$totalDogs psów';
  } else {
    return '$volunteers volunteer${volunteers == 1 ? '' : 's'}  •  $dogs/$totalDogs dog${totalDogs == 1 ? '' : 's'}';
  }
}

/// Formats a date for the share image header in full form.
/// PL: "Niedziela, 19 kwietnia 2026"
/// EN: "Sunday, April 19, 2026"
String formatShareDate(DateTime d, [String locale = 'pl']) {
  if (locale == 'pl') {
    const weekdays = [
      'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek',
      'Piątek', 'Sobota', 'Niedziela',
    ];
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia',
      'maja', 'czerwca', 'lipca', 'sierpnia',
      'września', 'października', 'listopada', 'grudnia',
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  } else {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ShareVolunteerCard extends StatelessWidget {
  const _ShareVolunteerCard({
    required this.assignment,
    required this.brightness,
    this.detailed = false,
  });

  final VolunteerAssignment assignment;
  final Brightness brightness;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
        color: colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Column(
              children: [
                Text(
                  assignment.volunteerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (assignment.note != null && assignment.note!.isNotEmpty)
                  Text(
                    assignment.note!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Dog rows
          for (final dog in assignment.dogs)
            _ShareDogRow(
              entry: dog,
              brightness: brightness,
              detailed: detailed,
            ),
        ],
      ),
    );
  }
}

class _ShareDogRow extends StatelessWidget {
  const _ShareDogRow({
    required this.entry,
    required this.brightness,
    this.detailed = false,
  });

  final DogEntry entry;
  final Brightness brightness;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = groupColor(entry.groupIndex, brightness);
    final hasGroup = entry.groupIndex != null && entry.groupIndex! > 0;
    final textColor =
        hasGroup ? groupTextColor(entry.groupIndex, brightness) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: hasGroup ? bgColor : null,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!detailed)
            // Compact: single line — name + kennel
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: entry.dogName),
                  if (entry.kennel != null)
                    TextSpan(
                      text: '  ${entry.kennel}',
                      style: TextStyle(
                        color: hasGroup
                            ? textColor?.withValues(alpha: 0.7)
                            : colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )
          else ...[
            // Full details: name, then shelterId · kennel · region
            Text(
              entry.dogName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              [
                if (entry.shelterId != null && entry.shelterId!.isNotEmpty)
                  entry.shelterId!,
                if (entry.kennel != null) entry.kennel!,
                if (entry.region != null) entry.region!,
              ].join(' · '),
              style: TextStyle(
                color: hasGroup
                    ? textColor?.withValues(alpha: 0.7)
                    : colorScheme.outline,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entry.note != null && entry.note!.isNotEmpty)
            Text(
              entry.note!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: hasGroup
                    ? textColor?.withValues(alpha: 0.7)
                    : colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
