import 'dart:async';

import 'package:get/get.dart';

class LoginController extends GetxController {
  final username = ''.obs;
  final password = ''.obs;
  final code = ''.obs;
  final authToken = ''.obs;
  final verifyType = 0.obs;
  final isEmailVerification = false.obs;
  final isTwoFactorAuth = false.obs;
  final countdown = 0.obs;
  Timer? _countdownTimer;

  // 实时判断按钮是否可点击
  bool get isLoginButtonEnabled =>
      GetUtils.isEmail(username.value) && password.value.length >= 6;
  bool get isVerificationRequired =>
      isEmailVerification.value || isTwoFactorAuth.value;
  bool get isCountdownActive => countdown.value > 0;

  @override
  void onInit() {
    super.onInit();
    // 防抖监听（可选）
    everAll([username, password], (_) => update());
  }

  void clear() {
    username.value = '';
    password.value = '';
    resetVerification();
  }

  void setEmailVerification({
    required String authToken,
    required int verifyType,
  }) {
    isEmailVerification.value = true;
    isTwoFactorAuth.value = false;
    this.authToken.value = authToken;
    this.verifyType.value = verifyType;
    code.value = '';
  }

  void setTwoFactorVerification({
    required String authToken,
    required int verifyType,
  }) {
    isTwoFactorAuth.value = true;
    isEmailVerification.value = false;
    this.authToken.value = authToken;
    this.verifyType.value = verifyType;
    code.value = '';
    stopCountdown();
  }

  void resetVerification() {
    isEmailVerification.value = false;
    isTwoFactorAuth.value = false;
    authToken.value = '';
    verifyType.value = 0;
    code.value = '';
    stopCountdown();
  }

  void startCountdown({int seconds = 60}) {
    stopCountdown();
    countdown.value = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        timer.cancel();
        countdown.value = 0;
      } else {
        countdown.value -= 1;
      }
    });
  }

  void stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (countdown.value != 0) {
      countdown.value = 0;
    }
  }

  @override
  void onClose() {
    stopCountdown();
    super.onClose();
  }
}
