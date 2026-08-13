import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/tables/achievements_table.dart';
import '../../application/achievement_actions_provider.dart';
import '../../data/certificate_image_store.dart';

const _kJlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
const _kNatTestLevels = ['5', '4', '3', '2', '1'];

Future<void> showAddAchievementDialog(BuildContext context) {
  return showDialog(context: context, builder: (context) => const AddAchievementDialog());
}

class AddAchievementDialog extends ConsumerStatefulWidget {
  const AddAchievementDialog({super.key});

  @override
  ConsumerState<AddAchievementDialog> createState() => _AddAchievementDialogState();
}

class _AddAchievementDialogState extends ConsumerState<AddAchievementDialog> {
  CertificateType _type = CertificateType.jlpt;
  String _level = _kJlptLevels.first;
  DateTime _earnedAt = DateTime.now();
  final _noteController = TextEditingController();
  File? _photo;
  bool _saving = false;
  bool _pickingPhoto = false;

  List<String> get _levels => _type == CertificateType.jlpt ? _kJlptLevels : _kNatTestLevels;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _earnedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _earnedAt = picked);
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final savedPath = await saveCertificateImage(picked);
      if (mounted) setState(() => _photo = File(savedPath));
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(achievementActionsProvider.notifier).add(
            type: _type,
            level: _level,
            earnedAt: _earnedAt,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            imagePath: _photo?.path,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add certificate'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<CertificateType>(
              segments: const [
                ButtonSegment(value: CertificateType.jlpt, label: Text('JLPT')),
                ButtonSegment(value: CertificateType.natTest, label: Text('NAT-TEST')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _level = _levels.first;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: [
                for (final level in _levels) DropdownMenuItem(value: level, child: Text(level)),
              ],
              onChanged: (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date earned'),
                child: Text('${_earnedAt.year}-${_earnedAt.month.toString().padLeft(2, '0')}-'
                    '${_earnedAt.day.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. score'),
            ),
            const SizedBox(height: 16),
            _PhotoPicker(
              photo: _photo,
              loading: _pickingPhoto,
              onPick: _pickPhoto,
              onRemove: () => setState(() => _photo = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.loading,
    required this.onPick,
    required this.onRemove,
  });

  final File? photo;
  final bool loading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(photo!, height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _RemoveButton(onPressed: onRemove),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: loading ? null : onPick,
      icon: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
      label: Text(
        'Add certificate photo (optional)',
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
