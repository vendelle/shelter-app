import 'package:flutter/material.dart';
import '../../../shared/domain/volunteer.dart';
import 'volunteers_tab.dart';

class VolunteerFormDialog extends StatefulWidget {
  const VolunteerFormDialog({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialRole,
    this.isArchived = false,
    required this.onSave,
    this.onArchiveToggle,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final VolunteerRole? initialRole;
  final bool isArchived;
  final Future<void> Function(String firstName, String lastName, VolunteerRole role) onSave;
  final Future<void> Function()? onArchiveToggle;

  @override
  State<VolunteerFormDialog> createState() => _VolunteerFormDialogState();
}

class _VolunteerFormDialogState extends State<VolunteerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late VolunteerRole _selectedRole;
  bool _saving = false;

  bool get _isEditing => widget.initialFirstName != null;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.initialFirstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.initialLastName ?? '');
    _selectedRole = widget.initialRole ?? VolunteerRole.newHelper;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Volunteer' : 'Add Volunteer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'First name is required'
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Last name is required'
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VolunteerRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
              items: VolunteerRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: roleColor(role),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(role.label),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (_isEditing && widget.onArchiveToggle != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _toggleArchive,
                  icon: Icon(widget.isArchived ? Icons.undo : Icons.person_off_outlined,
                      size: 18),
                  label: Text(widget.isArchived ? 'Reactivate' : 'Mark as inactive'),
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
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedRole,
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
