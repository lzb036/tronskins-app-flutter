import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message, {String? title}) {
    _show(
      message: message,
      title: title,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  static void error(String message, {String? title}) {
    _show(
      message: message,
      title: title,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  static void _show({
    required String message,
    String? title,
    required Color backgroundColor,
    required Color colorText,
  }) {
    if (message.trim().isEmpty) {
      return;
    }
    Get.snackbar(
      title ?? 'app.system.tips.title'.tr,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: colorText,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }
}
