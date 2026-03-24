import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/security/sm2_helper.dart';
import 'package:tronskins_app/common/widgets/auth_floating_input_field.dart';
import 'package:tronskins_app/common/widgets/scale_button.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class TokenRecoveryPage extends StatefulWidget {
  const TokenRecoveryPage({super.key});

  @override
  State<TokenRecoveryPage> createState() => _TokenRecoveryPageState();
}

class _TokenRecoveryPageState extends State<TokenRecoveryPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  Timer? _timer;
  int _countdown = 0;
  bool _submitting = false;
  bool _sending = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _codeTouched = false;
  String? _emailError;
  String? _passwordError;
  String? _codeError;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown -= 1);
      }
    });
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

  void _showError(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,

      titleText: const SizedBox.shrink(),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,

      titleText: const SizedBox.shrink(),
    );
  }

  String? _emailErrorText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'app.user.login.message.email_error'.tr;
    }
    if (!GetUtils.isEmail(trimmed)) {
      return 'app.user.login.message.email_format_error'.tr;
    }
    return null;
  }

  String? _passwordErrorText(String value) {
    if (value.trim().isEmpty) {
      return 'app.user.login.message.password_error'.tr;
    }
    if (value.length < 6) {
      return 'app.user.setting.password_format_tip'.tr;
    }
    return null;
  }

  String? _codeErrorText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'app.user.login.message.code_error'.tr;
    }
    return null;
  }

  void _onEmailChanged(String value) {
    final error = _emailErrorText(value);
    if (!_emailTouched || error != _emailError) {
      setState(() {
        _emailTouched = true;
        _emailError = error;
      });
    }
  }

  void _onPasswordChanged(String value) {
    final error = _passwordErrorText(value);
    if (!_passwordTouched || error != _passwordError) {
      setState(() {
        _passwordTouched = true;
        _passwordError = error;
      });
    }
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

  bool _validateEmailAndPassword() {
    final emailError = _emailErrorText(_emailController.text);
    final passwordError = _passwordErrorText(_passwordController.text);
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _emailError = emailError;
      _passwordError = passwordError;
    });
    return emailError == null && passwordError == null;
  }

  bool _validateSubmitInputs() {
    final emailError = _emailErrorText(_emailController.text);
    final passwordError = _passwordErrorText(_passwordController.text);
    final codeError = _codeErrorText(_codeController.text);
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _codeTouched = true;
      _emailError = emailError;
      _passwordError = passwordError;
      _codeError = codeError;
    });
    return emailError == null && passwordError == null && codeError == null;
  }

  Future<void> _sendCode() async {
    if (_sending || _countdown > 0) return;
    if (!_validateEmailAndPassword()) {
      return;
    }
    final email = _emailController.text.trim();

    setState(() => _sending = true);
    try {
      final result = await ApiLoginServer().sendEmailCodeBySubmit(
        email: email,
        purpose: 4,
      );
      if (result.success) {
        _startCountdown();
        _showSuccess('app.user.login.message.send_to_email'.tr);
      } else {
        _showError(_resolveMessage(result, 'app.user.login.message.error'));
      }
    } catch (_) {
      _showError('app.user.login.message.error'.tr);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validateSubmitInputs()) {
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final code = _codeController.text.trim();

    setState(() => _submitting = true);
    try {
      final pubKeyResult = await ApiLoginServer().getLoginPubKey(
        username: email,
      );
      String encryptedPassword = password;
      if (pubKeyResult.success && (pubKeyResult.datas ?? '').isNotEmpty) {
        encryptedPassword = Sm2Helper.encryptPassword(
          password: password,
          base64PublicKey: pubKeyResult.datas!,
        );
      }

      final result = await ApiLoginServer().tokenLostSubmit(
        username: email,
        password: encryptedPassword,
        code: code,
      );
      if (result.success) {
        _showSuccess('app.system.message.success'.tr);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Get.offAllNamed(Routers.HOME);
          }
        });
      } else {
        _showError(_resolveMessage(result, 'app.user.login.message.error'));
      }
    } catch (_) {
      _showError('app.user.login.message.error'.tr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 高级感配色方案
    final backgroundColor = isDark
        ? const Color(0xFF0F1115)
        : const Color(0xFFF5F7FA);
    final primaryColor = const Color(0xFF007AFF);
    final textColor = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final subTextColor = isDark
        ? const Color(0xFF86868B)
        : const Color(0xFF8E8E93);
    final inputFillColor = isDark
        ? const Color(0xFF2C2E34)
        : const Color(0xFFF2F2F7);

    final resendLabel = _countdown > 0
        ? '${'app.user.login.reacquire'.tr}(${_countdown}s)'
        : 'app.user.login.reacquire'.tr;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const Spacer(flex: 2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'app.user.login.token_loss'.tr,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'app.user.login.token_loss_desc'.tr,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 3),
                      Column(
                        children: [
                          AuthFloatingInputField(
                            controller: _emailController,
                            label: 'app.user.login.email_placeholder'.tr,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            hintColor: subTextColor,
                            onChanged: _onEmailChanged,
                            error: _emailTouched ? _emailError : null,
                          ),
                          const SizedBox(height: 16),
                          AuthFloatingInputField(
                            controller: _passwordController,
                            label: 'app.user.login.password_placeholder'.tr,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            hintColor: subTextColor,
                            onChanged: _onPasswordChanged,
                            error: _passwordTouched ? _passwordError : null,
                          ),
                          const SizedBox(height: 16),
                          AuthFloatingInputField(
                            controller: _codeController,
                            label: 'app.user.login.enter_captcha'.tr,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.security_outlined,
                            maxLength: 6,
                            fillColor: inputFillColor,
                            textColor: textColor,
                            hintColor: subTextColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: _onCodeChanged,
                            error: _codeTouched ? _codeError : null,
                            suffix: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton(
                                onPressed: _countdown > 0 || _sending
                                    ? null
                                    : _sendCode,
                                style: TextButton.styleFrom(
                                  foregroundColor: (_countdown > 0 || _sending)
                                      ? const Color(0xFFC7C7CC)
                                      : const Color(0xFF007AFF),
                                  disabledForegroundColor: const Color(
                                    0xFFC7C7CC,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  resendLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 3),
                      ScaleButton(
                        onPressed: _submitting ? null : _submit,
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: primaryColor,
                              disabledForegroundColor: Colors.white,
                              shadowColor: primaryColor.withValues(alpha: 0.4),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'app.common.confirm'.tr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
