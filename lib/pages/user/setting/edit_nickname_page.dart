import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/user_profile.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class EditNicknamePage extends StatefulWidget {
  const EditNicknamePage({super.key});

  @override
  State<EditNicknamePage> createState() => _EditNicknamePageState();
}

class _EditNicknamePageState extends State<EditNicknamePage> {
  final ApiUserProfileServer _api = ApiUserProfileServer();
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  void _showSuccessSnack(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnack(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      _showErrorSnack('app.user.setting.nickname_placeholder'.tr);
      return;
    }
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.editNickname(nickname: nickname);
      final message = res.datas?.toString().isNotEmpty == true
          ? res.datas.toString()
          : res.message;
      if (res.success) {
        _showSuccessSnack(
          message.isNotEmpty ? message : 'app.system.message.success'.tr,
        );
        if (Get.isRegistered<UserController>()) {
          await Get.find<UserController>().fetchUserData(showLoading: false);
        }
        Get.back();
      } else {
        _showErrorSnack(
          message.isNotEmpty ? message : 'app.system.message.not_open'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBorder = colorScheme.outlineVariant.withOpacity(
      isDark ? 0.5 : 0.7,
    );
    final inputFill = isDark
        ? colorScheme.surfaceVariant.withOpacity(0.35)
        : colorScheme.surfaceVariant.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(title: Text('app.user.setting.nickname_change'.tr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'app.user.setting.nickname_placeholder'.tr,
                filled: true,
                fillColor: inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: const Icon(Icons.person_outline),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.4,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('app.common.confirm'.tr),
                      ],
                    )
                  : Text('app.common.confirm'.tr),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(
                isDark ? 0.35 : 0.6,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tipLine('1. ${'app.user.setting.nickname_tips_1'.tr}'),
                const SizedBox(height: 6),
                _tipLine('2. ${'app.user.setting.nickname_tips_2'.tr}'),
                const SizedBox(height: 6),
                _tipLine('3. ${'app.user.setting.nickname_tips_3'.tr}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipLine(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
