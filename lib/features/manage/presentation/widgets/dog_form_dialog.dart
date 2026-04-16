import 'package:flutter/material.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

class DogFormDialog extends StatefulWidget {
  const DogFormDialog({
    super.key,
    this.initialName,
    this.initialShelterId,
    this.initialKennel,
    this.initialRegion,
    this.initialRegionOverride,
    this.isArchived = false,
    required this.onSave,
    this.onArchiveToggle,
  });

  final String? initialName;
  final String? initialShelterId;
  final String? initialKennel;
  final String? initialRegion;
  final String? initialRegionOverride;
  final bool isArchived;
  final Future<void> Function(String name, String shelterId, String kennel, {String? region, bool clearRegion}) onSave;
  final Future<void> Function()? onArchiveToggle;

  @override
  State<DogFormDialog> createState() => _DogFormDialogState();
}

class _DogFormDialogState extends State<DogFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shelterIdController;
  late final TextEditingController _kennelController;
  late final TextEditingController _regionController;
  bool _saving = false;
  bool _regionOverrideMode = false;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _shelterIdController =
        TextEditingController(text: widget.initialShelterId ?? '');
    _kennelController =
        TextEditingController(text: widget.initialKennel ?? '');
    _regionController =
        TextEditingController(text: widget.initialRegionOverride ?? '');
    _regionOverrideMode = widget.initialRegionOverride != null &&
        widget.initialRegionOverride!.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shelterIdController.dispose();
    _kennelController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEditing ? l10n.editDog : l10n.addDogButton),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.nameRequired : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shelterIdController,
              decoration: InputDecoration(labelText: l10n.shelterId),
              validator: (v) => v == null || v.trim().isEmpty
                  ? l10n.shelterIdRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kennelController,
              decoration: InputDecoration(
                labelText: l10n.kennel,
                hintText: l10n.kennelHint,
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.kennelRequired : null,
            ),
            const SizedBox(height: 12),
            // Region display / override
            if (!_regionOverrideMode)
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.region,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        widget.initialRegion ?? '—',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _regionOverrideMode = true;
                    }),
                    child: Text(l10n.overrideRegion),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _regionController,
                      decoration: InputDecoration(
                        labelText: l10n.region,
                        hintText: widget.initialRegion != null
                            ? l10n.regionAuto(widget.initialRegion!)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _regionOverrideMode = false;
                      _regionController.clear();
                    }),
                    child: Text(l10n.resetRegion),
                  ),
                ],
              ),
            if (_isEditing && widget.onArchiveToggle != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _toggleArchive,
                  icon: Icon(widget.isArchived ? Icons.undo : Icons.home_outlined,
                      size: 18),
                  label: Text(widget.isArchived ? l10n.restore : l10n.markAsAdopted),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.isArchived
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }

  Future<void> _toggleArchive() async {
    setState(() => _saving = true);
    try {
      await widget.onArchiveToggle!();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failed(e.toString()))),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _nameController.text.trim(),
        _shelterIdController.text.trim(),
        _kennelController.text.trim(),
        region: _regionOverrideMode && _regionController.text.trim().isNotEmpty
            ? _regionController.text.trim()
            : null,
        clearRegion: !_regionOverrideMode && widget.initialRegionOverride != null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSave(e.toString()))),
        );
        setState(() => _saving = false);
      }
    }
  }
}
