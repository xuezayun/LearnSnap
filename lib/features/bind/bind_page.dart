import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../core/device_info_collector.dart';
import '../../core/device_layout.dart';
import '../../core/privacy_consent_store.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/legal_entry_links.dart';

const int _bindCodeLength = 8;

class BindPage extends StatefulWidget {
  const BindPage({super.key, required this.onBound, this.notice});

  final VoidCallback onBound;
  final String? notice;

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  final _fieldKey = GlobalKey();
  final _api = LearnSnapApi();
  bool _loading = false;
  String? _error;
  bool _showNoCodeHelp = false;
  bool _agreedLegal = false;

  String get _code => _normalizeCode(_codeController.text);

  bool get _codeComplete => _code.length == _bindCodeLength && !_loading;

  bool get _canSubmit => _codeComplete && _agreedLegal;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final notice = widget.notice?.trim() ?? '';
      if (notice.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notice), duration: const Duration(seconds: 4)),
        );
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _normalizeCode(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
  }

  void _promptLegal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先阅读并同意隐私政策和用户协议')),
    );
  }

  Future<void> _onLegalChanged(bool value) async {
    setState(() => _agreedLegal = value);
    if (value) {
      await PrivacyConsentStore().agree();
    }
  }

  Future<void> _pasteFromClipboard() async {
    if (!_agreedLegal) {
      _promptLegal();
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = _normalizeCode(data?.text ?? '');
    if (pasted.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有可粘贴的暗号')),
      );
      return;
    }
    final clipped = pasted.length > _bindCodeLength
        ? pasted.substring(0, _bindCodeLength)
        : pasted;
    _codeController.value = TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
    _focusNode.requestFocus();
    if (clipped.length == _bindCodeLength) {
      await _bind();
    }
  }

  Future<void> _bind() async {
    if (!_agreedLegal) {
      _promptLegal();
      return;
    }
    final code = _code;
    if (code.length != _bindCodeLength) {
      setState(() => _error = '请把 8 位暗号填完整哦');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final device = await DeviceInfoCollector().collect();
      await _api.bindChild(
        bindCode: code,
        device: device,
      );
      widget.onBound();
    } on ApiException catch (e) {
      final message = e.code == 40101
          ? '暗号不对或过期了，请爸爸妈妈再看一眼小程序里的暗号'
          : e.message;
      setState(() => _error = message);
      _focusNode.requestFocus();
    } catch (_) {
      setState(() => _error = '绑定失败，请检查网络');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = primaryButtonHeight(context);
    final tablet = isTablet(context);
    final boxHeight = tablet ? 64.0 : 52.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: AdaptiveBody(
              maxWidth: formMaxWidth(context),
              child: SingleChildScrollView(
                // Keep tree stable while IME opens — do not rebuild on viewInsets.
                padding: EdgeInsets.only(
                  bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: tablet ? 42 : 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDeep,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请家长把暗号告诉你',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.inkMuted,
                        fontSize: tablet ? 17 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      padding: EdgeInsets.all(tablet ? 28 : 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.brand.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '输入 8 位暗号',
                            style: GoogleFonts.nunito(
                              fontSize: tablet ? 18 : 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '暗号由爸爸妈妈在微信小程序「${AppConfig.miniprogramName}」里生成。',
                            style: GoogleFonts.nunito(
                              color: AppColors.inkMuted,
                              fontSize: tablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: boxHeight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ListenableBuilder(
                                  listenable: _focusNode,
                                  builder: (context, _) {
                                    return IgnorePointer(
                                      child: _BindCodeBoxes(
                                        code: _code,
                                        focused: _focusNode.hasFocus,
                                        length: _bindCodeLength,
                                      ),
                                    );
                                  },
                                ),
                                Positioned.fill(
                                  child: TextField(
                                    key: _fieldKey,
                                    controller: _codeController,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.done,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    showCursor: false,
                                    enableInteractiveSelection: false,
                                    style: const TextStyle(
                                      color: Colors.transparent,
                                      // Keep a real font size so the IME connection stays valid.
                                      fontSize: 16,
                                    ),
                                    cursorColor: Colors.transparent,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                    ),
                                    inputFormatters: [
                                      _BindCodeFormatter(
                                        maxLength: _bindCodeLength,
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (_normalizeCode(value).length ==
                                              _bindCodeLength &&
                                          !_loading) {
                                        Future<void>.delayed(
                                          const Duration(milliseconds: 120),
                                          () {
                                            if (mounted && _canSubmit) {
                                              _bind();
                                            }
                                          },
                                        );
                                      }
                                    },
                                    onSubmitted: (_) {
                                      if (_canSubmit) _bind();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed:
                                  _loading ? null : _pasteFromClipboard,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
                              label: const Text('粘贴暗号'),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.nunito(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                setState(
                                  () => _showNoCodeHelp = !_showNoCodeHelp,
                                );
                              },
                              child: Text(
                                _showNoCodeHelp ? '收起说明' : '没有暗号？',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandDeep,
                                ),
                              ),
                            ),
                          ),
                          if (_showNoCodeHelp) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '请让爸爸妈妈用微信搜索小程序「${AppConfig.miniprogramName}」→ 添加孩子 → 打开「设备绑定码」→ 把暗号告诉你。\n\n（暗号不是会员邀请码哦。）',
                                style: GoogleFonts.nunito(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '暗号是 8 位字母或数字，大小写都可以',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.inkFaint,
                        fontSize: tablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    LegalConsentCheckbox(
                      agreed: _agreedLegal,
                      onChanged: _onLegalChanged,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _codeComplete
                          ? _bind
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, buttonHeight),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('开始探险'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BindCodeFormatter extends TextInputFormatter {
  _BindCodeFormatter({required this.maxLength});

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^0-9A-F]'), '');
    final clipped = normalized.length > maxLength
        ? normalized.substring(0, maxLength)
        : normalized;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}

class _BindCodeBoxes extends StatelessWidget {
  const _BindCodeBoxes({
    required this.code,
    required this.focused,
    required this.length,
  });

  final String code;
  final bool focused;
  final int length;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final boxHeight = tablet ? 64.0 : 52.0;
    final fontSize = tablet ? 28.0 : 24.0;

    return Row(
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (context) {
                final active = focused &&
                    i == code.length.clamp(0, length - 1) &&
                    code.length < length;
                final filled = i < code.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: boxHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.brandSoft
                        : const Color(0xFFF4F7F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? AppColors.brand
                          : (filled
                              ? AppColors.brand.withValues(alpha: 0.35)
                              : const Color(0xFFE0E6E8)),
                      width: active ? 2.2 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? code[i] : '',
                    style: GoogleFonts.nunito(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.ink,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
