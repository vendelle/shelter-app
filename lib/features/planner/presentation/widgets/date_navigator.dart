import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

class DateNavigator extends StatelessWidget {
  const DateNavigator({
    super.key,
    required this.date,
    required this.onDateChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final maxDate = DateTime(today.year, today.month, today.day + 3);
    final atMax = date.year == maxDate.year &&
        date.month == maxDate.month &&
        date.day == maxDate.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () =>
                onDateChanged(date.subtract(const Duration(days: 1))),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickDate(context, maxDate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(context, date, isToday),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: atMax
                ? null
                : () => onDateChanged(date.add(const Duration(days: 1))),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime maxDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2025),
      lastDate: maxDate,
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  String _formatDate(BuildContext context, DateTime d, bool isToday) {
    final l10n = AppLocalizations.of(context)!;
    final fullWeekdays = [
      l10n.weekdayFullMon, l10n.weekdayFullTue, l10n.weekdayFullWed,
      l10n.weekdayFullThu, l10n.weekdayFullFri, l10n.weekdayFullSat,
      l10n.weekdayFullSun,
    ];
    final fullMonths = [
      l10n.monthFullJan, l10n.monthFullFeb, l10n.monthFullMar,
      l10n.monthFullApr, l10n.monthFullMay, l10n.monthFullJun,
      l10n.monthFullJul, l10n.monthFullAug, l10n.monthFullSep,
      l10n.monthFullOct, l10n.monthFullNov, l10n.monthFullDec,
    ];
    final weekday = isToday ? l10n.today : fullWeekdays[d.weekday - 1];
    return l10n.fullDateFormat(
      weekday,
      d.day,
      fullMonths[d.month - 1],
      d.year,
    );
  }
}
