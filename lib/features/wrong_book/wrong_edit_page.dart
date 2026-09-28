import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_colors.dart';
import 'wrong_book_repository.dart';
import 'wrong_item.dart';

class WrongEditPage extends StatefulWidget {
  const WrongEditPage({
    super.key,
    required this.childId,
    required this.repository,
    this.existing,
    this.imagePath = '',
    this.initialSubject,
  });

  final int childId;
  final WrongBookRepository repository;
  final WrongItem? existing;
  final String imagePath;
  final String? initialSubject;

  @override
  State<WrongEditPage> createState() => _WrongEditPageState();
}

class _WrongEditPageState extends State<WrongEditPage> {
  late String _subject = widget.existing?.subject ?? widget.initialSubject ?? 'math';
  late String _status = widget.existing?.status ?? 'open';
  late final TextEditingController _note = TextEditingController(text: widget.existing?.note ?? '');
  late final String _imagePath = widget.imagePath.isNotEmpty
      ? widget.imagePath
      : (widget.existing?.localPath ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({bool deleted = false}) async {
    if (_saving) return;
    final note = _note.text.trim();
    if (note.length > 200) {
      _toast('错因请写在 200 字以内');
      return;
    }
    if (!deleted && _imagePath.isEmpty && (widget.existing?.imageKey.isEmpty ?? true)) {
      _toast('先拍下这道错题');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final imageChanged = widget.imagePath.isNotEmpty;
    final item = WrongItem(
      clientUuid: widget.existing?.clientUuid ?? const Uuid().v4(),
      subject: _subject,
      note: note,
      status: _status,
      imageKey: imageChanged ? '' : (widget.existing?.imageKey ?? ''),
      localPath: _imagePath,
      deleted: deleted,
      pendingSync: true,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await widget.repository.saveLocalAndSync(widget.childId, item);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('已记在本机，联网后会再同步');
      Navigator.of(context).pop(true);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final file = _imagePath.isEmpty ? null : File(_imagePath);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? '收录错题' : '这道错题'),
        actions: [
          if (widget.existing != null)
            IconButton(
              onPressed: _saving ? null : () => _save(deleted: true),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (file != null && file.existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(file, height: 220, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('还没有照片'),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in wrongSubjects)
                ChoiceChip(
                  label: Text(wrongSubjectLabel(subject)),
                  selected: _subject == subject,
                  onSelected: (_) => setState(() => _subject = subject),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '错因（可以不写）',
              hintText: '例如：进位忘了加',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final status in const ['open', 'reviewing', 'mastered'])
                ChoiceChip(
                  label: Text(wrongStatusLabel(status)),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : () => _save(),
            child: Text(_saving ? '保存中…' : '保存'),
          ),
          const SizedBox(height: 8),
          Text(
            '只保存这道题的照片和你写的错因，不判断对错，也不给答案。',
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.inkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
