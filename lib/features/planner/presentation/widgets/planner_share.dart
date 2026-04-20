import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/volunteer_assignment.dart';
import 'group_colors.dart';

/// Renders the planner assignments to an image and opens the native share sheet.
/// On mobile web: opens the Web Share API (share to WhatsApp, etc.).
/// On desktop web / unsupported: falls back to downloading the PNG.
Future<void> sharePlannerImage({
  required BuildContext context,
  required DateTime date,
  required List<VolunteerAssignment> assignments,
  required int totalDogs,
}) async {
  final theme = Theme.of(context);
  final brightness = theme.brightness;

  // Build the static widget to render
  final widget = PlannerShareLayout(
    date: date,
    assignments: assignments,
    totalDogs: totalDogs,
    brightness: brightness,
  );

  // Render off-screen to an image
  final imageBytes = await _renderWidgetToImage(
    widget: widget,
    context: context,
    // Width of the rendered plan — 800 logical px looks good on most screens
    logicalWidth: 800,
  );

  if (imageBytes == null || !context.mounted) return;

  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Create XFile from bytes — works on both web and native (no file system needed)
  final xFile = XFile.fromData(
    Uint8List.fromList(imageBytes),
    mimeType: 'image/png',
    name: 'plan-$dateStr.png',
  );

  // Share via native share sheet (mobile) or download (desktop web fallback)
  await Share.shareXFiles([xFile]);
}

/// Renders a widget off-screen to a PNG byte buffer.
Future<List<int>?> _renderWidgetToImage({
  required Widget widget,
  required BuildContext context,
  required double logicalWidth,
}) async {
  final repaintBoundary = RenderRepaintBoundary();
  final view = View.of(context);
  final devicePixelRatio = view.devicePixelRatio;

  // Wrap in the app's theme so colors match
  final theme = Theme.of(context);
  final themedWidget = MediaQuery(
    data: MediaQueryData(
      size: Size(logicalWidth, 4000), // tall enough for any plan
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

  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(
      alignment: Alignment.topLeft,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration.fromView(view),
  );
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

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

  buildOwner.buildScope(rootElement);
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final image = await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  buildOwner.finalizeTree();

  return byteData?.buffer.asUint8List();
}

// ---------------------------------------------------------------------------
// Static layout widget for the share image
// ---------------------------------------------------------------------------

/// Visible for testing. Builds the static plan layout used for sharing.
class PlannerShareLayout extends StatelessWidget {
  const PlannerShareLayout({
    super.key,
    required this.date,
    required this.assignments,
    required this.totalDogs,
    required this.brightness,
  });

  final DateTime date;
  final List<VolunteerAssignment> assignments;
  final int totalDogs;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dogCount =
        assignments.fold<int>(0, (sum, a) => sum + a.dogs.length);

    // Calculate columns: aim for 2 on narrow, up to 4
    const cols = 2;
    const gap = 6.0;
    const padding = 10.0;

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
              formatShareDate(date),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          // Volunteer grid
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final assignment in assignments)
                SizedBox(
                  width: (800 - 2 * padding - (cols - 1) * gap) / cols,
                  child: _ShareVolunteerCard(
                    assignment: assignment,
                    brightness: brightness,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Summary footer
          Text(
            '${assignments.length} wolo  •  $dogCount/$totalDogs psów',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a date for the share image header.
String formatShareDate(DateTime d) {
  const weekdays = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Niedz'];
  const months = [
    'Sty', 'Lut', 'Mar', 'Kwi', 'Maj', 'Cze',
    'Lip', 'Sie', 'Wrz', 'Paź', 'Lis', 'Gru',
  ];
  return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

class _ShareVolunteerCard extends StatelessWidget {
  const _ShareVolunteerCard({
    required this.assignment,
    required this.brightness,
  });

  final VolunteerAssignment assignment;
  final Brightness brightness;

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
          // Dog rows — compact, no interactive elements
          for (final dog in assignment.dogs)
            _ShareDogRow(entry: dog, brightness: brightness),
        ],
      ),
    );
  }
}

class _ShareDogRow extends StatelessWidget {
  const _ShareDogRow({
    required this.entry,
    required this.brightness,
  });

  final DogEntry entry;
  final Brightness brightness;

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
          ),
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
