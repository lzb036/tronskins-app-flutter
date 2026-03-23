import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/auth/steam_session_controller.dart';

class SteamSessionPage extends StatefulWidget {
  const SteamSessionPage({super.key});

  @override
  State<SteamSessionPage> createState() => _SteamSessionPageState();
}

class _SteamSessionPageState extends State<SteamSessionPage> {
  late final SteamSessionController controller;
  late final Worker _successWorker;

  bool get _isChinese =>
      (Get.locale?.languageCode ?? '').toLowerCase().startsWith('zh');

  String get _usernameLabel => _isChinese ? '用户名' : 'Username';

  String get _passwordLabel => _isChinese ? '密码' : 'Password';

  String get _codeLabel => _isChinese ? '验证码' : 'Code';

  String get _codeHint => _isChinese ? '输入 5 位验证码' : 'Enter 5-digit code';

  String get _codeHelper =>
      _isChinese ? '请填写最新的 5 位验证码' : 'Use the latest 5-digit code';

  String get _loadingLabel => _isChinese ? '登录中...' : 'Logging in...';

  @override
  void initState() {
    super.initState();
    controller = Get.put(SteamSessionController());
    _successWorker = ever<bool>(controller.verificationSucceeded, (success) {
      if (!success || !mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Get.back(result: true);
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.steam.message.verify_success'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          titleText: const SizedBox.shrink(),
        );
      });
    });
  }

  @override
  void dispose() {
    _successWorker.dispose();
    if (Get.isRegistered<SteamSessionController>()) {
      Get.delete<SteamSessionController>();
    }
    super.dispose();
  }

  Widget _buildTipRow(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.tr,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(
            dismissible: false,
            color: Color.fromRGBO(0, 0, 0, 0.35),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.codeController,
                      builder: (context, value, child) {
                        final codeValue = value.text.trim();
                        final canSubmit =
                            codeValue.length == 5 &&
                            !controller.isCodeSubmitting.value;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.security_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _codeLabel,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'app.steam.verify.title'.tr,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: controller.codeController,
                              enabled: !controller.isCodeSubmitting.value,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 5,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              onChanged: (nextValue) {
                                final uppercase = nextValue.toUpperCase();
                                if (uppercase == nextValue) {
                                  return;
                                }
                                controller.codeController.value =
                                    TextEditingValue(
                                      text: uppercase,
                                      selection: TextSelection.collapsed(
                                        offset: uppercase.length,
                                      ),
                                    );
                              },
                              decoration: InputDecoration(
                                hintText: _codeHint,
                                prefixIcon: const Icon(Icons.key_rounded),
                                suffixText: '${codeValue.length}/5',
                                suffixStyle: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                counterText: '',
                              ),
                            ),
                            if (controller.errorMessage.value.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildErrorBox(
                                context,
                                controller.errorMessage.value,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _codeHelper,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: controller.isCodeSubmitting.value
                                        ? null
                                        : controller.hideCodeDialog,
                                    child: Text('app.common.cancel'.tr),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: canSubmit
                                        ? () async {
                                            await controller.submitCode();
                                          }
                                        : null,
                                    child: controller.isCodeSubmitting.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text('app.common.confirm'.tr),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return Scaffold(
      appBar: AppBar(title: Text('app.steam.verification'.tr)),
      body: Obx(() {
        final isStarting = controller.isLoading.value;
        final isAwaitingVerification = controller.isAwaitingVerification.value;
        final showCodeDialog = controller.isCodeDialogVisible.value;
        final hasError = controller.errorMessage.value.isNotEmpty;
        final fieldsEnabled = !isStarting && !isAwaitingVerification;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Card(
                    elevation: 0,
                    shape: cardShape,
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'app.steam.verification'.tr,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: controller.accountController,
                            enabled: fieldsEnabled,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: _usernameLabel,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.25),
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller.passwordController,
                            enabled: fieldsEnabled,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _passwordLabel,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.25),
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 12),
                    _buildErrorBox(context, controller.errorMessage.value),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: controller.isCodeSubmitting.value
                          ? null
                          : () async {
                              await controller.startLogin();
                            },
                      child: isStarting
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(_loadingLabel),
                              ],
                            )
                          : Text('app.user.login.title'.tr),
                    ),
                  ),
                  if (isAwaitingVerification && !showCodeDialog) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: controller.showCodeDialog,
                      icon: const Icon(Icons.security_rounded),
                      label: Text('app.steam.verification'.tr),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: cardShape,
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTipRow(context, 'app.steam.session.tips_1'.tr),
                          const SizedBox(height: 8),
                          _buildTipRow(context, 'app.steam.session.tips_2'.tr),
                          const SizedBox(height: 8),
                          _buildTipRow(context, 'app.steam.session.tips_3'.tr),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCodeDialog) _buildVerificationOverlay(context),
          ],
        );
      }),
    );
  }
}
