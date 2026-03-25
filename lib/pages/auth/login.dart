import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/api/model/loginModel.dart';
import 'package:tronskins_app/api/model/loginRequest.dart';
import 'package:tronskins_app/common/device/device_id_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/security/sm2_helper.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/auth_floating_input_field.dart';
import 'package:tronskins_app/common/widgets/scale_button.dart';
import 'package:tronskins_app/controllers/auth/login_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final LoginController controller = Get.put(LoginController());
  bool _isLoading = false;
  bool _isAutoSubmittingTwoFactor = false;
  bool _hasAttemptedAutoTwoFactor = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _codeTouched = false;
  late final AnimationController _brandAnim;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _brandAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _brandAnim,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _brandAnim,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _brandAnim.forward();
  }

  @override
  void dispose() {
    _brandAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
      colors.surface,
    );
    final headerGlowColor = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
      backgroundColor,
    );
    final primaryColor = colors.primary;
    final accentColor = colors.secondary;
    final textColor = colors.onSurface;
    final subTextColor = colors.onSurfaceVariant;
    final inputFillColor = colors.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.44 : 0.76,
    );
    final steamButtonBackground = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.40)
        : colors.surface.withValues(alpha: 0.92);
    final steamButtonBorder = colors.primary.withValues(
      alpha: isDark ? 0.18 : 0.28,
    );
    final isSubmitting = _isLoading || _isAutoSubmittingTwoFactor;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true, // 确保键盘弹出时页面调整
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [headerGlowColor, backgroundColor],
          ),
        ),
        child: SafeArea(
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
                        // 自定义返回按钮
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

                        const Spacer(flex: 2), // 弹性间距

                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      primaryColor,
                                      accentColor.withValues(
                                        alpha: isDark ? 0.85 : 0.92,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'app.user.login.tronskins'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 3), // 弹性间距，使标题略微偏上
                        // 表单区域
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernInputField(
                                hint: 'app.user.login.email_placeholder'.tr,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                fillColor: inputFillColor,
                                textColor: textColor,
                                hintColor: subTextColor,
                                onChanged: (v) {
                                  final wasTouched = _emailTouched;
                                  _markTouched(email: true);
                                  controller.username.value = v.trim();
                                  if (wasTouched && mounted) {
                                    setState(() {});
                                  }
                                },
                                error: _emailTouched
                                    ? _emailErrorText(controller.username.value)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernInputField(
                                hint: 'app.user.login.password_placeholder'.tr,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                fillColor: inputFillColor,
                                textColor: textColor,
                                hintColor: subTextColor,
                                onChanged: (v) {
                                  final wasTouched = _passwordTouched;
                                  _markTouched(password: true);
                                  controller.password.value = v;
                                  if (wasTouched && mounted) {
                                    setState(() {});
                                  }
                                },
                                error: _passwordTouched
                                    ? _passwordErrorText(
                                        controller.password.value,
                                      )
                                    : null,
                              ),
                            ),
                            Obx(() {
                              if (!controller.isVerificationRequired) {
                                return const SizedBox.shrink();
                              }
                              if (_isAutoSubmittingTwoFactor &&
                                  controller.isTwoFactorAuth.value) {
                                return const SizedBox.shrink();
                              }

                              final isEmail =
                                  controller.isEmailVerification.value;
                              final hint = isEmail
                                  ? 'app.user.login.enter_captcha'.tr
                                  : 'app.user.login.enter_2fa_captcha'.tr;

                              return Column(
                                children: [
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildModernInputField(
                                      hint: hint,
                                      keyboardType: TextInputType.number,
                                      prefixIcon: Icons.security_outlined,
                                      maxLength: 6,
                                      fillColor: inputFillColor,
                                      textColor: textColor,
                                      hintColor: subTextColor,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (v) {
                                        final wasTouched = _codeTouched;
                                        _markTouched(code: true);
                                        controller.code.value = v.trim();
                                        if (wasTouched && mounted) {
                                          setState(() {});
                                        }
                                      },
                                      suffix: isEmail
                                          ? _buildResendButton()
                                          : null,
                                      error: _codeTouched
                                          ? _codeErrorText(
                                              controller.code.value,
                                              isEmailVerification: isEmail,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),

                        const Spacer(flex: 3), // 弹性间距
                        // 登录按钮
                        ScaleButton(
                          key: const ValueKey('login_btn'),
                          onPressed: isSubmitting ? null : _handleLogin,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54, // 微调高度
                            child: ElevatedButton(
                              onPressed: null, // 事件由 ScaleButton 处理
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: primaryColor,
                                disabledForegroundColor: Colors.white,
                                shadowColor: primaryColor.withValues(
                                  alpha: isDark ? 0.24 : 0.34,
                                ),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'app.user.login.title'.tr,
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

                        const SizedBox(height: 26),

                        // Steam 登录
                        ScaleButton(
                          key: const ValueKey('steam_btn'),
                          onPressed: () => Get.toNamed(Routers.STEAM_LOGIN),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: null, // 事件由 ScaleButton 处理
                              icon: Icon(
                                Icons.sports_esports,
                                size: 24,
                                color: primaryColor,
                              ),
                              label: Text(
                                'app.steam.login.title'.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  steamButtonBackground,
                                ),
                                foregroundColor: WidgetStatePropertyAll(
                                  textColor,
                                ),
                                side: WidgetStatePropertyAll(
                                  BorderSide(
                                    color: steamButtonBorder,
                                    width: 1.4,
                                  ),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                overlayColor: const WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2), // 弹性间距
                        // 底部功能链接
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Get.toNamed(Routers.FORGET_PASSWORD),
                                child: Text(
                                  'app.user.login.forget_password'.tr,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 12,
                                color: subTextColor.withValues(alpha: 0.3),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Get.toNamed(Routers.TOKEN_RECOVERY),
                                child: Text(
                                  'app.user.login.token_loss'.tr,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
    AppSnackbar.error(message);
  }

  void _showSuccess(String message) {
    AppSnackbar.success(message);
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

  String? _codeErrorText(String value, {required bool isEmailVerification}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return isEmailVerification
          ? 'app.user.login.enter_captcha'.tr
          : 'app.user.login.enter_2fa_captcha'.tr;
    }
    if (trimmed.length < 6) {
      return 'app.user.login.message.code_length_error'.tr;
    }
    return null;
  }

  void _markTouched({
    bool email = false,
    bool password = false,
    bool code = false,
  }) {
    var updated = false;
    if (email && !_emailTouched) {
      _emailTouched = true;
      updated = true;
    }
    if (password && !_passwordTouched) {
      _passwordTouched = true;
      updated = true;
    }
    if (code && !_codeTouched) {
      _codeTouched = true;
      updated = true;
    }
    if (updated && mounted) {
      setState(() {});
    }
  }

  // 现代风格输入框构建器
  Widget _buildModernInputField({
    required String hint,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
    IconData? prefixIcon,
    bool obscureText = false,
    required ValueChanged<String> onChanged,
    String? error,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return AuthFloatingInputField(
      label: hint,
      fillColor: fillColor,
      textColor: textColor,
      hintColor: hintColor,
      prefixIcon: prefixIcon,
      obscureText: obscureText,
      onChanged: onChanged,
      error: error,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      suffix: suffix,
    );
  }

  Widget _buildResendButton() {
    return Obx(() {
      final isActive = controller.isCountdownActive;
      final label = isActive
          ? '${'app.user.login.reacquire'.tr}(${controller.countdown.value}s)'
          : 'app.user.login.reacquire'.tr;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: TextButton(
          onPressed: isActive || _isLoading ? null : _sendEmailCode,
          style: TextButton.styleFrom(
            foregroundColor: isActive
                ? Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.56)
                : Theme.of(context).colorScheme.primary,
            disabledForegroundColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    });
  }

  Future<void> _sendEmailCode({bool force = false}) async {
    if (controller.isCountdownActive) {
      return;
    }

    if (_isLoading && !force) {
      return;
    }

    final email = controller.username.value.trim();
    final authToken = controller.authToken.value.trim();
    _markTouched(email: true);
    final emailError = _emailErrorText(email);
    if (emailError != null) {
      return;
    }
    if (authToken.isEmpty) {
      _showError('app.user.login.message.error'.tr);
      return;
    }

    try {
      final result = await ApiLoginServer().sendLoginEmailCode(
        email: email,
        authToken: authToken,
      );
      if (result.success) {
        controller.startCountdown();
        _showSuccess('app.user.login.message.send_to_email'.tr);
      } else {
        final message = _resolveMessage(result, 'app.user.login.message.error');
        _showError(message);
      }
    } catch (e) {
      _showError('app.user.login.message.error'.tr);
    }
  }

  Future<void> _tryAutoSubmitTwoFactor(LoginEntity data) async {
    if (_hasAttemptedAutoTwoFactor) {
      _showSuccess('app.user.login.enter_2fa_captcha'.tr);
      return;
    }

    final token = await TwoFactorStorage.findStoredTokenForLogin(
      server: ServerStorage.getServer(),
      appUse: data.appUse ?? '',
      userId: data.userId ?? '',
      showEmail: data.userName ?? '',
      loginAccount: controller.username.value.trim(),
    );
    if (token == null || token.secret.trim().isEmpty) {
      _showSuccess('app.user.login.enter_2fa_captcha'.tr);
      return;
    }

    final code = TwoFactorHelper.generateCode(token.secret);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showSuccess('app.user.login.enter_2fa_captcha'.tr);
      return;
    }

    _hasAttemptedAutoTwoFactor = true;
    controller.code.value = code;
    if (mounted) {
      setState(() => _isAutoSubmittingTwoFactor = true);
    }
    try {
      await _handleLogin(isAutoTwoFactorRetry: true, manageLoadingState: false);
    } finally {
      if (mounted) {
        setState(() => _isAutoSubmittingTwoFactor = false);
      }
    }
  }

  Future<void> _handleLogin({
    bool isAutoTwoFactorRetry = false,
    bool manageLoadingState = true,
  }) async {
    if (_isLoading && manageLoadingState) return;
    final username = controller.username.value.trim();
    final password = controller.password.value;
    if (!controller.isVerificationRequired) {
      _hasAttemptedAutoTwoFactor = false;
    }
    _markTouched(
      email: true,
      password: true,
      code: controller.isVerificationRequired && !isAutoTwoFactorRetry,
    );

    final emailError = _emailErrorText(username);
    if (emailError != null) {
      return;
    }

    final passwordError = _passwordErrorText(password);
    if (passwordError != null) {
      return;
    }

    if (controller.isVerificationRequired) {
      final codeError = _codeErrorText(
        controller.code.value,
        isEmailVerification: controller.isEmailVerification.value,
      );
      if (codeError != null) {
        return;
      }
    }

    if (manageLoadingState) {
      setState(() => _isLoading = true);
    }

    try {
      final pubKeyResult = await ApiLoginServer().getLoginPubKey(
        username: username,
      );
      String encryptedPassword = password;
      if (pubKeyResult.success && (pubKeyResult.datas ?? '').isNotEmpty) {
        encryptedPassword = Sm2Helper.encryptPassword(
          password: password,
          base64PublicKey: pubKeyResult.datas!,
        );
      }

      final params = LoginParams(
        username: username,
        password: encryptedPassword,
        udid: DeviceIdHelper.getUdid(),
        rememberMe: true,
        code: controller.isVerificationRequired
            ? controller.code.value.trim()
            : null,
        verifyType: controller.isVerificationRequired
            ? controller.verifyType.value
            : null,
        authToken: controller.isVerificationRequired
            ? controller.authToken.value.trim()
            : null,
      );

      final result = await ApiLoginServer().loginApi(params);
      if (!result.success || result.datas == null) {
        final message = _resolveMessage(result, 'app.user.login.message.error');
        if (isAutoTwoFactorRetry && controller.isTwoFactorAuth.value) {
          controller.code.value = '';
          _showError(message);
        } else {
          _showError(message);
        }
        return;
      }

      final data = result.datas!;
      final currentVerifyType = data.verifyType ?? 0;
      if (currentVerifyType == 0) {
        final accessToken = data.effectiveAccessToken;
        if (accessToken == null || accessToken.isEmpty) {
          _showError('app.user.login.message.error'.tr);
          return;
        }

        controller.resetVerification();
        await AuthInterceptor.setAccessToken(
          accessToken: accessToken,
          accessTokenExpireTime: data.accessTokenExpireTime,
          refreshTokenExpireTime: data.effectiveRefreshTokenExpireTime,
          header: data.header,
        );
        final userId = data.userId ?? '';
        final appUse = data.appUse ?? '';
        if (userId.isNotEmpty && appUse.isNotEmpty) {
          await TwoFactorStorage.ensureTokenEntry(
            server: ServerStorage.getServer(),
            appUse: appUse,
            userId: userId,
            showEmail: data.userName ?? username,
          );
        }
        Get.offAllNamed(Routers.HOME);
        _showSuccess('app.user.login.message.success'.tr);
        return;
      }

      if (currentVerifyType == 1) {
        controller.setEmailVerification(
          authToken: data.authToken ?? '',
          verifyType: currentVerifyType,
        );
        if (_codeTouched) {
          setState(() => _codeTouched = false);
        }
        await _sendEmailCode(force: true);
        return;
      }

      if (currentVerifyType == 2) {
        controller.setTwoFactorVerification(
          authToken: data.authToken ?? '',
          verifyType: currentVerifyType,
        );
        if (_codeTouched) {
          setState(() => _codeTouched = false);
        }
        await _tryAutoSubmitTwoFactor(data);
        return;
      }

      final fallbackMessage = (data.desc != null && data.desc!.isNotEmpty)
          ? data.desc!
          : (result.message.isNotEmpty
                ? result.message
                : 'app.user.login.message.error'.tr);
      _showError(fallbackMessage);
    } catch (e) {
      if (isAutoTwoFactorRetry && controller.isTwoFactorAuth.value) {
        controller.code.value = '';
        _showError('app.user.login.message.error'.tr);
      } else {
        _showError('app.user.login.message.error'.tr);
      }
    } finally {
      if (manageLoadingState && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
