import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/user_profile.dart';
import 'package:tronskins_app/common/storage/app_cache.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final ApiUserProfileServer _api = ApiUserProfileServer();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  bool _showOld = false;
  bool _showNew = false;
  bool _showRepeat = false;
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
    _oldController.dispose();
    _newController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPwd = _oldController.text.trim();
    final newPwd = _newController.text.trim();
    final repeat = _repeatController.text.trim();
    if (oldPwd.isEmpty || newPwd.isEmpty || repeat.isEmpty) {
      _showErrorSnack('app.user.login.password_placeholder'.tr);
      return;
    }
    if (newPwd != repeat) {
      _newController.clear();
      _repeatController.clear();
      _showErrorSnack('app.user.setting.password_inconsistent_error'.tr);
      return;
    }
    final user = UserStorage.getUserInfo();
    final userId = user?.id?.toString() ?? '';
    if (userId.isEmpty) {
      _showErrorSnack('app.system.message.nologin'.tr);
      return;
    }
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.editPassword(
        id: userId,
        password: oldPwd,
        newPassword: newPwd,
      );
      final message = res.datas?.toString().isNotEmpty == true
          ? res.datas.toString()
          : res.message;
      if (res.success) {
        _showSuccessSnack(
          message.isNotEmpty ? message : 'app.system.message.success'.tr,
        );
        _oldController.clear();
        _newController.clear();
        _repeatController.clear();
        await AppCache.clearOnLogout();
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().clearSession();
        } else {
          UserStorage.setUserInfo(null);
        }
        Get.offAllNamed(Routers.LOGIN);
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
      appBar: AppBar(title: Text('app.user.setting.password_change'.tr)),
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
            child: Column(
              children: [
                _buildPasswordField(
                  controller: _oldController,
                  label: 'app.user.setting.password_enter_old_word'.tr,
                  visible: _showOld,
                  onToggle: () => setState(() => _showOld = !_showOld),
                  fillColor: inputFill,
                  borderColor: cardBorder,
                  focusColor: colorScheme.primary,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _newController,
                  label: 'app.user.setting.password_enter_new_word'.tr,
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  fillColor: inputFill,
                  borderColor: cardBorder,
                  focusColor: colorScheme.primary,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _repeatController,
                  label: 'app.user.setting.password_enter_confirm_word'.tr,
                  visible: _showRepeat,
                  onToggle: () => setState(() => _showRepeat = !_showRepeat),
                  fillColor: inputFill,
                  borderColor: cardBorder,
                  focusColor: colorScheme.primary,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                ),
              ],
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(
                isDark ? 0.35 : 0.6,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'app.user.setting.password_format_tip'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required TextInputAction textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      textInputAction: textInputAction,
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
