import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../../../../core/api/api_client.dart';
import 'download_helper.dart' as download;

/// Bottom sheet for exporting walks as CSV with date range filters.
class ExportWalksSheet extends StatefulWidget {
  const ExportWalksSheet({super.key});

  @override
  State<ExportWalksSheet> createState() => _ExportWalksSheetState();
}

class _ExportWalksSheetState extends State<ExportWalksSheet> {
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = now;
    _fromDate = DateTime(now.year, now.month - 3, now.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);

    try {
      final baseUrl = ApiClient.defaultBaseUrl;
      final from = _formatDate(_fromDate);
      final to = _formatDate(_toDate);
      final url = '$baseUrl/api/walks?format=csv&from=$from&to=$to';

      await download.downloadCsv(url);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.exportWalks,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // From date
          _DatePickerRow(
            label: l10n.exportFrom,
            date: _fromDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 12),
          // To date
          _DatePickerRow(
            label: l10n.exportTo,
            date: _toDate,
            onTap: () => _selectDate(context, false),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isExporting ? null : _exportCsv,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(l10n.exportButton),
          ),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
