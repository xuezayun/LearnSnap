import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/checkin_media_prepare.dart';
import '../../core/harmony_os.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import 'dictation_ocr.dart';
import 'dictation_select_page.dart';
import 'dictation_settings.dart';
import 'dictation_words.dart';

class DictationPage extends StatefulWidget {
  const DictationPage({super.key});

  @override
  State<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends State<DictationPage> {
  final _picker = ImagePicker();
  final _settingsStore = DictationSettingsStore();
  DictationSettings _settings = const DictationSettings();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settingsStore.load().then((settings) {
      if (!mounted) return;
      setState(() => _settings = settings);
    });
  }

  DictationLang get _lang => _settings.lang == DictationLangPref.english
      ? DictationLang.english
      : DictationLang.chinese;

  Future<void> _setLang(DictationLangPref lang) async {
    final next = _settings.copyWith(lang: lang);
    setState(() => _settings = next);
    await _settingsStore.save(next);
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final harmony = await HarmonyOs.isHarmonyOs();
      if (!mounted) return;
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: harmony ? null : 92,
        maxWidth: harmony ? null : 2400,
      );
      if (photo == null || !mounted) return;
      final path = await _keepLocal(photo);
      if (!mounted) return;
      final words = await recognizeDictationWords(path: path, lang: _lang);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DictationSelectPage(
            imagePath: path,
            words: words,
            lang: _lang,
            initialSettings: _settings,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _keepLocal(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final prepared = await prepareCheckinImage(
      bytes: bytes,
      filename: photo.name,
    );
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'dictation'));
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    } else {
      await dir.create(recursive: true);
    }
    final file = File(p.join(dir.path, prepared.filename));
    final data = prepared.bytes;
    if (data == null || data.isEmpty) {
      throw Exception('照片是空的，请重新拍一张');
    }
    await file.writeAsBytes(data, flush: true);
    return file.path;
  }

  String _message(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    if (raw.contains('本机') || raw.contains('照片')) return raw;
    return '没能认出照片里的词语，请换一张更清晰的印刷体词语表';
  }

  @override
  Widget build(BuildContext context) {
    final english = _settings.lang == DictationLangPref.english;
    return Scaffold(
      appBar: AppBar(title: const Text('拍照听写')),
      body: AppScaffoldBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '拍一张词语表，点选或圈出要听的词，再按间隔和语速读出来。',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '照片只留在这台设备上，不会上传，也不批改对错。印刷体更准。',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '词语语言',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDeep,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _LangChip(
                    label: '语文',
                    selected: !english,
                    onTap: _busy ? null : () => _setLang(DictationLangPref.chinese),
                  ),
                  const SizedBox(width: 10),
                  _LangChip(
                    label: '英语',
                    selected: english,
                    onTap: _busy ? null : () => _setLang(DictationLangPref.english),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('拍照'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('从相册选择'),
              ),
              if (_busy) ...[
                const SizedBox(height: 28),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),
                Text(
                  '正在这台设备上识别词语…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.brand : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.brand : AppColors.brandSoft,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.brandDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
