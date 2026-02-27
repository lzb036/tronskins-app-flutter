import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/controllers/auth/twofa_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class TwoFaTokenPage extends StatefulWidget {
  const TwoFaTokenPage({super.key});

  @override
  State<TwoFaTokenPage> createState() => _TwoFaTokenPageState();
}

class _TwoFaTokenPageState extends State<TwoFaTokenPage> {
  final TwoFactorController controller =
      Get.isRegistered<TwoFactorController>()
          ? Get.find<TwoFactorController>()
          : Get.put(TwoFactorController());
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    controller.loadTokens();
    controller.refreshStatus();
  }

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'app.system.tips.title'.tr,
      'app.system.message.copy_success'.tr,
    );
  }

  Future<void> _confirmDelete(TwoFactorToken token) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.common.delete'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteToken(token);
    }
  }

  Future<void> _openBindDialog() async {
    final email = controller.email.value ?? '';
    if (email.isEmpty) {
      await controller.refreshStatus();
    }
    if (controller.isBound.value != true) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.guard.open_2fa_first'.tr,
      );
      return;
    }
    final emailValue = controller.email.value ?? '';
    if (emailValue.isEmpty) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.guard.open_2fa_first'.tr,
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _TwoFaBindDialog(
          email: emailValue,
          controller: controller,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = userController.isLoggedIn.value;
      final currentUser = userController.user.value;
      final hasCurrentUserToken = currentUser != null &&
          controller.tokens.any(
            (token) =>
                token.userId == (currentUser.id ?? '') &&
                token.appUse == (currentUser.appUse ?? '') &&
                token.secret.isNotEmpty,
          );
      return Scaffold(
        appBar: AppBar(
          title: Text('app.user.menu.guard'.tr),
          actions: loggedIn && !hasCurrentUserToken
              ? [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _openBindDialog,
                  ),
                ]
              : const [],
        ),
        body: loggedIn
            ? Obx(() {
                final currentUser = UserStorage.getUserInfo();
                final _ = controller.tick.value;
                if (controller.tokens.isEmpty) {
                  return Center(child: Text('app.common.no_data'.tr));
                }
                final remaining = controller.remainingSeconds();
                final progress = remaining / 30;
                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.loadTokens();
                    await controller.refreshStatus();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: controller.tokens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final token = controller.tokens[index];
                      final isCurrent = currentUser != null &&
                          currentUser.id == token.userId &&
                          currentUser.appUse == token.appUse;
                      final hasSecret = token.secret.isNotEmpty;
                      final code = hasSecret
                          ? controller.codeForToken(token)
                          : 'app.user.guard.bind_tips'.tr;
                      return _TwoFaTokenCard(
                        token: token,
                        isCurrent: isCurrent,
                        code: code,
                        hasSecret: hasSecret,
                        progress: progress,
                        remaining: remaining,
                        onCopy: () => _copyCode(code),
                        onBind: _openBindDialog,
                        onDelete: () => _confirmDelete(token),
                      );
                    },
                  ),
                );
              })
            : _buildLoginPrompt(),
      );
    });
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('app.system.message.nologin'.tr),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Get.toNamed(Routers.LOGIN),
            child: Text('app.user.login.nologin'.tr),
          ),
        ],
      ),
    );
  }
}

class _TwoFaBindDialog extends StatefulWidget {
  const _TwoFaBindDialog({
    required this.email,
    required this.controller,
  });

  final String email;
  final TwoFactorController controller;

  @override
  State<_TwoFaBindDialog> createState() => _TwoFaBindDialogState();
}

class _TwoFaBindDialogState extends State<_TwoFaBindDialog> {
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _countdown = 0;
  bool _codeTouched = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  String? _extractMessage(dynamic datas) {
    if (datas is String && datas.trim().isNotEmpty) {
      return datas;
    }
    if (datas is Map) {
      for (final key in ['message', 'msg', 'error', 'detail', 'desc']) {
        final value = datas[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String _resolveMessage(
    BaseHttpResponse<dynamic> result,
    String fallbackKey,
  ) {
    if (result.message.isNotEmpty) {
      return result.message;
    }
    final dataMessage = _extractMessage(result.datas);
    if (dataMessage != null) {
      return dataMessage;
    }
    return fallbackKey.tr;
  }

  Future<void> _startCountdown() async {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) {
          setState(() => _countdown = 0);
        }
      } else {
        if (mounted) {
          setState(() => _countdown -= 1);
        }
      }
    });
  }

  String? _codeErrorText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'app.user.login.message.code_error'.tr;
    }
    return null;
  }

  void _onCodeChanged(String value) {
    final error = _codeErrorText(value);
    if (!_codeTouched || error != _codeError) {
      setState(() {
        _codeTouched = true;
        _codeError = error;
      });
    }
  }

  bool _validateCode() {
    final error = _codeErrorText(_codeController.text);
    setState(() {
      _codeTouched = true;
      _codeError = error;
    });
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white38 : Colors.grey[400];
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final sendLabel = _countdown == 0
        ? 'app.user.guard.get_captcha'.tr
        : '${_countdown}s';
    return AlertDialog(
      title: Text(
        'app.user.guard.bind_tips'.tr,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            enabled: false,
            controller: _emailController,
            style: TextStyle(color: textColor?.withOpacity(0.7)),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            onChanged: _onCodeChanged,
            decoration: InputDecoration(
              hintText: 'app.user.login.enter_captcha'.tr,
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              filled: true,
              fillColor: fillColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          if (_codeTouched && _codeError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _codeError!,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_countdown != 0) {
              return;
            }
            try {
              final res = await widget.controller.sendEmailCode();
              if (res.success) {
                Get.snackbar(
                  'app.system.tips.title'.tr,
                  'app.user.guard.captcha_been_sent'.tr,
                );
                await _startCountdown();
              } else {
                _showError(
                  _resolveMessage(res, 'app.user.guard.captcha_send_failed'),
                );
              }
            } catch (_) {
              _showError('app.user.guard.captcha_send_failed'.tr);
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: _countdown == 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          child: Text(sendLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('app.common.cancel'.tr),
        ),
        FilledButton(
          onPressed: () async {
            if (!_validateCode()) {
              return;
            }
            final code = _codeController.text.trim();
            final ok = await widget.controller.syncToken(code);
            if (ok) {
              Navigator.pop(context);
              Get.snackbar(
                'app.system.tips.title'.tr,
                'app.system.message.success'.tr,
              );
            }
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size(92, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('app.common.confirm'.tr),
        ),
      ],
    );
  }
}

class _TwoFaTokenCard extends StatelessWidget {
  const _TwoFaTokenCard({
    required this.token,
    required this.isCurrent,
    required this.code,
    required this.hasSecret,
    required this.progress,
    required this.remaining,
    required this.onCopy,
    required this.onBind,
    required this.onDelete,
  });

  final TwoFactorToken token;
  final bool isCurrent;
  final String code;
  final bool hasSecret;
  final double progress;
  final int remaining;
  final VoidCallback onCopy;
  final VoidCallback onBind;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        isCurrent ? colorScheme.primaryContainer : colorScheme.surface;
    final borderColor = isCurrent
        ? colorScheme.primary.withOpacity(0.2)
        : colorScheme.outlineVariant.withOpacity(0.5);
    final codeStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: hasSecret ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: hasSecret ? 2 : 0,
        );

    return Material(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: hasSecret ? onCopy : onBind,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '[${token.appUse}]',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      token.showEmail,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasSecret)
                    _CountdownRing(
                      progress: progress,
                      remaining: remaining,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(code, style: codeStyle),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasSecret)
                    IconButton(
                      tooltip: 'app.system.message.copy_success'.tr,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: onCopy,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.remaining,
  });

  final double progress;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
          ),
          Text(
            remaining.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
