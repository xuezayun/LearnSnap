import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../services/learn_snap_api.dart';

class BindPage extends StatefulWidget {
  const BindPage({super.key, required this.onBound});

  final VoidCallback onBound;

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final _codeController = TextEditingController();
  final _api = LearnSnapApi();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _bind() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '请输入绑定码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.bindChild(
        bindCode: code,
        deviceId: const Uuid().v4(),
      );
      widget.onBound();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AdaptiveBody(
            maxWidth: formMaxWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '绑定设备',
                  style: TextStyle(
                    fontSize: tablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('请在家长小程序生成绑定码后输入', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontSize: tablet ? 18 : 16),
                  decoration: InputDecoration(
                    labelText: '设备绑定码',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: tablet ? 18 : 14,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _bind,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(double.infinity, buttonHeight),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('绑定并开始'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
