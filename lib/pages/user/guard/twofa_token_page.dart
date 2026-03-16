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
import 'package:tronskins_app/common/widgets/glass_notice_dialog.dart';
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

    // 精确匹配：userId + appUse + server
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

    // 如果 currentAppUse 为空，尝试只匹配 userId + server
    if (currentAppUse.isEmpty && currentUserId.isNotEmpty) {
      final userServerMatches = controller.tokens
          .where((token) {
            return token.secret.trim().isNotEmpty &&
                token.userId.trim() == currentUserId &&
                _matchesServer(token, currentServer);
          })
          .toList(growable: false);
      if (userServerMatches.length == 1) {
        return userServerMatches.first;
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
    final tokens = controller.tokens
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

    if (tokens.length < 2 || currentUser == null) {
      return tokens;
    }

    final prioritized = <TwoFactorToken>[];
    final regular = <TwoFactorToken>[];
    for (final token in tokens) {
      if (_isCurrentToken(token, currentUser)) {
        prioritized.add(token);
      } else {
        regular.add(token);
      }
    }

    return <TwoFactorToken>[...prioritized, ...regular];
  }

  Future<void> _copyCode(String code) async {
    if (code.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    await showGlassNoticeDialog(
      context,
      message: 'app.system.message.copy_success'.tr,
      icon: Icons.check_circle_outline_rounded,
      duration: const Duration(milliseconds: 1200),
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
      final _ = controller.tick.value;
      controller.tokens.length; // 订阅 tokens 变化以触发重建
      final visibleTokens = _visibleTokens(currentUser);
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
        body: visibleTokens.isEmpty
            ? const _TwoFaEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: visibleTokens.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final token = visibleTokens[index];
                  final isCurrent = _isCurrentToken(token, currentUser);
                  final hasSecret = token.secret.isNotEmpty;
                  final code = hasSecret
                      ? controller.codeForToken(token)
                      : 'app.user.guard.bind_tips'.tr;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _TwoFaTokenCard(
                        token: token,
                        isCurrent: isCurrent,
                        code: code,
                        hasSecret: hasSecret,
                        progress: progress,
                        remaining: remaining,
                        onCopy: () => _copyCode(code),
                        onBind: isCurrent ? _openBindDialog : null,
                        onDelete: () => _confirmDelete(token),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}

class _TwoFaEmptyState extends StatelessWidget {
  const _TwoFaEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                size: 40,
                color: colorScheme.primary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'app.common.no_data'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
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

  String _displayCode(String value) {
    final normalized = value.replaceAll(' ', '');
    if (normalized.length != 6) {
      return value;
    }
    return '${normalized.substring(0, 3)} ${normalized.substring(3)}';
  }

  String _title() {
    final value = token.appUse.trim();
    return value.isEmpty ? '2FA' : value;
  }

  String _subtitle() {
    final email = token.showEmail.trim();
    if (email.isNotEmpty) {
      return email;
    }
    final userId = token.userId.trim();
    return userId.isEmpty ? _serverLabel(token.server) : userId;
  }

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
    final baseSurface = isDark ? const Color(0xFF151922) : Colors.white;
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isCurrent
          ? [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                baseSurface,
              ),
              baseSurface,
            ]
          : [
              baseSurface,
              isDark ? const Color(0xFF10141C) : const Color(0xFFF8FAFD),
            ],
    );
    final borderColor = isCurrent
        ? colorScheme.primary.withValues(alpha: isDark ? 0.38 : 0.24)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE4E8EE));
    final panelColor = hasSecret
        ? colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08)
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF4F6FA));
    final codeStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: hasSecret ? colorScheme.primary : colorScheme.onSurface,
      fontWeight: hasSecret ? FontWeight.w800 : FontWeight.w600,
      letterSpacing: hasSecret ? 2.6 : 0,
      fontSize: hasSecret ? 28 : 15,
      height: 1,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: isCurrent ? 1.4 : 1),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasSecret ? null : onBind,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TwoFaTokenGlyph(label: _title(), isCurrent: isCurrent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _title(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: isDark ? 0.18 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        if (hasSecret) ...[
                          _CountdownRing(
                            progress: progress,
                            remaining: remaining,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _TwoFaActionButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'app.common.delete'.tr,
                          foregroundColor: colorScheme.error,
                          backgroundColor: colorScheme.error.withValues(
                            alpha: isDark ? 0.14 : 0.1,
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TwoFaMetaChip(
                  icon: Icons.dns_outlined,
                  label: _serverLabel(token.server),
                  isCurrent: isCurrent,
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasSecret ? onCopy : onBind,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasSecret
                              ? colorScheme.primary.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                )
                              : borderColor.withValues(alpha: 0.75),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                hasSecret ? _displayCode(code) : code,
                                maxLines: hasSecret ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: codeStyle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _TwoFaActionButton(
                              icon: hasSecret
                                  ? Icons.copy_rounded
                                  : Icons.sync_rounded,
                              tooltip: hasSecret
                                  ? 'app.system.message.copy_success'.tr
                                  : 'app.user.guard.bind_tips'.tr,
                              foregroundColor: hasSecret
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              backgroundColor: hasSecret
                                  ? colorScheme.primary.withValues(
                                      alpha: isDark ? 0.18 : 0.12,
                                    )
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFEDEFF4)),
                              onPressed: hasSecret ? onCopy : onBind,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
        : (remaining <= 10 ? Colors.orange : colorScheme.primary);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: progressColor.withValues(alpha: isDark ? 0.15 : 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoFaTokenGlyph extends StatelessWidget {
  const _TwoFaTokenGlyph({required this.label, required this.isCurrent});

  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seed = label.trim().isEmpty ? '2' : label.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [
                  colorScheme.primary.withValues(alpha: isDark ? 0.7 : 0.92),
                  colorScheme.primary.withValues(alpha: isDark ? 0.36 : 0.62),
                ]
              : [
                  colorScheme.secondaryContainer.withValues(
                    alpha: isDark ? 0.45 : 0.92,
                  ),
                  colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.28 : 0.72,
                  ),
                ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          seed,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isCurrent
                ? colorScheme.onPrimary
                : colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

class _TwoFaMetaChip extends StatelessWidget {
  const _TwoFaMetaChip({
    required this.icon,
    required this.label,
    required this.isCurrent,
  });

  final IconData icon;
  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F7FA)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isCurrent
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoFaActionButton extends StatelessWidget {
  const _TwoFaActionButton({
    required this.icon,
    required this.tooltip,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 20,
            iconSize: 18,
            onPressed: onPressed,
            icon: Icon(icon, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
