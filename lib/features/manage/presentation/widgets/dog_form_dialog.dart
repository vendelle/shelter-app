import 'package:flutter/material.dart';

class DogFormDialog extends StatefulWidget {
  const DogFormDialog({
    super.key,
    this.initialName,
    this.initialShelterId,
    this.initialKennel,
    this.isArchived = false,
    required this.onSave,
    this.onArchiveToggle,
  });

  final String? initialName;
  final String? initialShelterId;
  final String? initialKennel;
  final bool isArchived;
  final Future<void> Function(String name, String shelterId, String kennel) onSave;
  final Future<void> Function()? onArchiveToggle;

  @override
  State<DogFormDialog> createState() => _DogFormDialogState();
}

class _DogFormDialogState extends State<DogFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shelterIdController;
  late final TextEditingController _kennelController;
  bool _saving = false;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _shelterIdController =
        TextEditingController(text: widget.initialShelterId ?? '');
    _kennelController =
        TextEditingController(text: widget.initialKennel ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shelterIdController.dispose();
    _kennelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Dog' : 'Add Dog'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shelterIdController,
              decoration: const InputDecoration(labelText: 'Shelter ID'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Shelter ID is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kennelController,
              decoration: const InputDecoration(
                labelText: 'Kennel',
                hintText: '3-digit number',
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Kennel is required' : null,
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
                  label: Text(widget.isArchived ? 'Restore' : 'Mark as adopted'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
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
          SnackBar(content: Text('Failed: $e')),
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
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
