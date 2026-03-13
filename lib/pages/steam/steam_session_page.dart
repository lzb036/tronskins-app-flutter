import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/auth/steam_session_controller.dart';

class SteamSessionPage extends StatelessWidget {
  const SteamSessionPage({super.key});

  Future<void> _submitCodeAndClose(SteamSessionController controller) async {
    final ok = await controller.submitCodeAndRefresh();
    if (!ok) {
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SteamSessionController());
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
        final isLoading = controller.isLoading.value;
        final isAwaitingCode = controller.isAwaitingCode.value;
        final hasError = controller.errorMessage.value.isNotEmpty;
        return Container(
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
                              isAwaitingCode
                                  ? 'app.steam.verify.title'.tr
                                  : 'app.steam.verification'.tr,
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
                        enabled: !isAwaitingCode && !isLoading,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText:
                              'app.steam.session.username_placeholder'.tr,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
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
                        enabled: !isAwaitingCode && !isLoading,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'app.user.login.password_placeholder'.tr,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
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
              const SizedBox(height: 12),
              if (isAwaitingCode)
                Card(
                  elevation: 0,
                  shape: cardShape,
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'app.steam.code.number'.tr,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.codeController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 5,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          onChanged: (value) {
                            final uppercase = value.toUpperCase();
                            if (uppercase == value) {
                              return;
                            }
                            controller.codeController.value = TextEditingValue(
                              text: uppercase,
                              selection: TextSelection.collapsed(
                                offset: uppercase.length,
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            labelText: 'app.steam.placeholder.code'.tr,
                            helperText: 'app.steam.code.number'.tr,
                            prefixIcon: const Icon(Icons.security_rounded),
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
                            counterStyle: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
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
              if (hasError) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value.tr,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (isAwaitingCode) {
                            await _submitCodeAndClose(controller);
                            return;
                          }
                          await controller.startLogin();
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isAwaitingCode
                              ? 'app.common.confirm'.tr
                              : 'app.user.login.title'.tr,
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
