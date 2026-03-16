import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/controllers/auth/twofa_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class TwoFaTokenPage extends StatefulWidget {
  const TwoFaTokenPage({super.key});

  @override
  State<TwoFaTokenPage> createState() => _TwoFaTokenPageState();
}

class _TwoFaTokenPageState extends State<TwoFaTokenPage> {
  final TwoFactorController controller = Get.isRegistered<TwoFactorController>()
      ? Get.find<TwoFactorController>()
      : Get.put(TwoFactorController());
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    controller.loadTokens();
    if (userController.isLoggedIn.value || UserStorage.getUserInfo() != null) {
      controller.refreshStatus();
    }
  }

  String _normalizeText(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _normalizeServer(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  bool _matchesServer(
    TwoFactorToken token,
    String normalizedServer, {
    bool allowLegacy = false,
  }) {
    final tokenServer = _normalizeServer(token.server);
    if (tokenServer.isEmpty) {
      return allowLegacy;
    }
    return tokenServer == normalizedServer;
  }

  bool _sameTokenIdentity(TwoFactorToken left, TwoFactorToken right) {
    return left.userId.trim() == right.userId.trim() &&
        _normalizeText(left.appUse) == _normalizeText(right.appUse) &&
        _normalizeServer(left.server) == _normalizeServer(right.server);
  }

  String _currentServer() {
    return ServerStorage.getServer();
  }

  Iterable<String> _currentUserEmails(UserInfoEntity? currentUser) sync* {
    if (currentUser == null) {
      return;
    }
    final values = <String>{
      _normalizeText(currentUser.safeTokenName),
      _normalizeText(currentUser.showEmail),
    }..removeWhere((item) => item.isEmpty);
    yield* values;
  }

  TwoFactorToken? _findCurrentUserSyncedToken(UserInfoEntity? currentUser) {
    if (currentUser == null) {
      return null;
    }

    final currentUserId = currentUser.id?.trim() ?? '';
    final currentAppUse = _normalizeText(currentUser.appUse);
    final currentServer = _normalizeServer(_currentServer());

    for (final token in controller.tokens) {
      if (token.secret.trim().isEmpty) {
        continue;
      }
      if (token.userId.trim() == currentUserId &&
          _normalizeText(token.appUse) == currentAppUse &&
          _matchesServer(token, currentServer)) {
        return token;
      }
    }

    if (currentServer.isNotEmpty) {
      for (final token in controller.tokens) {
        if (token.secret.trim().isEmpty) {
          continue;
        }
        if (token.userId.trim() == currentUserId &&
            _normalizeText(token.appUse) == currentAppUse &&
            _matchesServer(token, currentServer, allowLegacy: true)) {
          return token;
        }
      }
    }

    final emails = _currentUserEmails(currentUser).toList(growable: false);
    if (emails.isEmpty) {
      return null;
    }

    for (final email in emails) {
      final emailMatches = controller.tokens
          .where((token) {
            return token.secret.trim().isNotEmpty &&
                _normalizeText(token.showEmail) == email;
          })
          .toList(growable: false);
      if (emailMatches.isEmpty) {
        continue;
      }

      final exactServerMatches = emailMatches
          .where((token) => _matchesServer(token, currentServer))
          .toList(growable: false);
      if (currentAppUse.isNotEmpty) {
        final appUseMatches = exactServerMatches
            .where((token) => _normalizeText(token.appUse) == currentAppUse)
            .toList(growable: false);
        if (appUseMatches.length == 1) {
          return appUseMatches.first;
        }
      } else if (exactServerMatches.length == 1) {
        return exactServerMatches.first;
      }

      final legacyServerMatches = emailMatches
          .where((token) {
            return _matchesServer(token, currentServer, allowLegacy: true);
          })
          .toList(growable: false);
      if (currentAppUse.isNotEmpty) {
        final appUseMatches = legacyServerMatches
            .where((token) => _normalizeText(token.appUse) == currentAppUse)
            .toList(growable: false);
        if (appUseMatches.length == 1) {
          return appUseMatches.first;
        }
      } else if (legacyServerMatches.length == 1) {
        return legacyServerMatches.first;
      }
    }

    return null;
  }

  bool _isCurrentToken(TwoFactorToken token, UserInfoEntity? currentUser) {
    if (currentUser == null) {
      return false;
    }
    final currentUserId = currentUser.id?.trim() ?? '';
    final currentAppUse = _normalizeText(currentUser.appUse);
    final currentServer = _normalizeServer(_currentServer());
    final isCurrentIdentity =
        token.userId.trim() == currentUserId &&
        _normalizeText(token.appUse) == currentAppUse &&
        _matchesServer(
          token,
          currentServer,
          allowLegacy: currentServer.isNotEmpty,
        );
    if (token.secret.trim().isEmpty) {
      return isCurrentIdentity;
    }
    final syncedToken = _findCurrentUserSyncedToken(currentUser);
    return syncedToken != null &&
        syncedToken.secret.isNotEmpty &&
        _sameTokenIdentity(syncedToken, token);
  }

  bool _hasCurrentUserToken(UserInfoEntity? currentUser) {
    return currentUser != null &&
        _findCurrentUserSyncedToken(currentUser) != null;
  }

  List<TwoFactorToken> _visibleTokens(UserInfoEntity? currentUser) {
    final currentServer = _normalizeServer(_currentServer());
    final currentUserId = currentUser?.id?.trim() ?? '';
    final currentAppUse = _normalizeText(currentUser?.appUse);
    return controller.tokens
        .where((token) {
          if (token.secret.trim().isNotEmpty) {
            return true;
          }
          return currentUser != null &&
              token.userId.trim() == currentUserId &&
              _normalizeText(token.appUse) == currentAppUse &&
              _matchesServer(
                token,
                currentServer,
                allowLegacy: currentServer.isNotEmpty,
              );
        })
        .toList(growable: false);
  }

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'app.system.tips.title'.tr,
      'app.system.message.copy_success'.tr,

      titleText: const SizedBox.shrink(),
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

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    final emailValue = controller.email.value ?? '';
    if (emailValue.isEmpty) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.guard.open_2fa_first'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _TwoFaBindDialog(email: emailValue, controller: controller);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = userController.isLoggedIn.value;
      final currentUser =
          userController.user.value ?? UserStorage.getUserInfo();
      final visibleTokens = _visibleTokens(currentUser);
      final _ = controller.tick.value;
      final remaining = controller.remainingSeconds();
      final progress = remaining / 30;
      final hasCurrentUserToken = _hasCurrentUserToken(currentUser);
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
        body: RefreshIndicator(
          onRefresh: () async {
            await controller.loadTokens();
            if (loggedIn) {
              await controller.refreshStatus();
            }
          },
          child: visibleTokens.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.security_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'app.common.no_data'.tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: visibleTokens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final token = visibleTokens[index];
                    final isCurrent = _isCurrentToken(token, currentUser);
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
                      onBind: isCurrent ? _openBindDialog : null,
                      onDelete: () => _confirmDelete(token),
                    );
                  },
                ),
        ),
      );
    });
  }
}

class _TwoFaBindDialog extends StatefulWidget {
  const _TwoFaBindDialog({required this.email, required this.controller});

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
    AppSnackbar.error(message);
  }

  void _showSuccess(String message) {
    AppSnackbar.success(message);
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

  String _resolveMessage(BaseHttpResponse<dynamic> result, String fallbackKey) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final panelColor = isDark ? const Color(0xFF1E252D) : Colors.white;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF6F7F9);
    final hintColor = isDark ? Colors.white54 : const Color(0xFF7F8894);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE4E8EE);
    final headerBadgeColor = colorScheme.primary.withValues(
      alpha: isDark ? 0.22 : 0.10,
    );
    final sendLabel = _countdown == 0
        ? 'app.user.guard.get_captcha'.tr
        : '${_countdown}s';

    Future<void> sendCaptcha() async {
      if (_countdown != 0) {
        return;
      }
      try {
        final res = await widget.controller.sendEmailCode();
        if (res.success) {
          _showSuccess('app.user.guard.captcha_been_sent'.tr);
          await _startCountdown();
        } else {
          _showError(
            _resolveMessage(res, 'app.user.guard.captcha_send_failed'),
          );
        }
      } catch (_) {
        _showError('app.user.guard.captcha_send_failed'.tr);
      }
    }

    Future<void> confirmSync() async {
      if (!_validateCode()) {
        return;
      }
      final code = _codeController.text.trim();
      try {
        final res = await widget.controller.syncToken(code);
        if (res.success) {
          Get.back();
          _showSuccess('app.user.guard.sync_success'.tr);
          return;
        }
        _showError(_resolveMessage(res, 'app.user.guard.sync_failed'));
      } catch (_) {
        _showError('app.user.guard.sync_failed'.tr);
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: headerBadgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'app.user.guard.bind_tips'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'app.user.login.enter_captcha'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: hintColor, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                enabled: false,
                controller: _emailController,
                style: TextStyle(color: textColor?.withValues(alpha: 0.72)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                onChanged: _onCodeChanged,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.mark_email_read_outlined,
                    color: hintColor,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_codeTouched && _codeError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: Colors.redAccent,
                    ),
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
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: sendCaptcha,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _countdown == 0
                      ? colorScheme.primary
                      : Theme.of(context).disabledColor,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(
                    color: (_countdown == 0 ? colorScheme.primary : borderColor)
                        .withValues(alpha: 0.9),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  sendLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: confirmSync,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'app.common.confirm'.tr,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
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
  final VoidCallback? onBind;
  final VoidCallback onDelete;

  String _serverLabel(String server) {
    final normalized = server.trim();
    if (normalized.isEmpty) {
      return 'legacy';
    }
    final uri = Uri.tryParse(normalized);
    final host = uri?.host ?? '';
    if (host.isEmpty) {
      return normalized;
    }
    if ((uri?.path ?? '').isEmpty || uri?.path == '/') {
      return host;
    }
    return '$host${uri?.path}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isCurrent
        ? (isDark
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.primaryContainer.withValues(alpha: 0.3))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final borderColor = isCurrent
        ? colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.3)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE4E8EE));

    final codeStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: hasSecret ? colorScheme.primary : colorScheme.onSurface,
      fontWeight: FontWeight.w800,
      letterSpacing: hasSecret ? 4 : 0,
      fontSize: 32,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasSecret ? onCopy : onBind,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        token.appUse,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (hasSecret)
                      _CountdownRing(progress: progress, remaining: remaining),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        token.showEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _serverLabel(token.server),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: hasSecret
                        ? colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF6F7F9)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: codeStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasSecret)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: 'app.system.message.copy_success'.tr,
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: onCopy,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        tooltip: 'app.common.delete'.tr,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.progress, required this.remaining});

  final double progress;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor = remaining <= 5
        ? colorScheme.error
        : (remaining <= 10
            ? Colors.orange
            : colorScheme.primary);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: progressColor.withValues(alpha: isDark ? 0.15 : 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              color: progressColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            remaining.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }
}
