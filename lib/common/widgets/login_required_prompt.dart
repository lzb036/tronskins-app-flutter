import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class LoginRequiredPrompt extends StatelessWidget {
  const LoginRequiredPrompt({super.key});

  @override
  Widget build(BuildContext context) {
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
