import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/controllers/shop/shop_controller.dart';

class ShopRenamePage extends StatefulWidget {
  const ShopRenamePage({super.key});

  @override
  State<ShopRenamePage> createState() => _ShopRenamePageState();
}

class _ShopRenamePageState extends State<ShopRenamePage> {
  final ShopController controller = Get.isRegistered<ShopController>()
      ? Get.find<ShopController>()
      : Get.put(ShopController());
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        controller.shop.value?.shopName ?? controller.shop.value?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.error('app.user.shop.name.change_placeholder'.tr);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await controller.changeShopName(name);
      Get.back();
      AppSnackbar.success('app.system.message.success'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app.user.shop.name.change'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('app.user.shop.name.label'.tr),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'app.user.shop.name.change_placeholder'.tr,
              ),
            ),
            const SizedBox(height: 16),
            Text('- ${'app.user.shop.name.change_tips_1'.tr}'),
            const SizedBox(height: 6),
            Text('- ${'app.user.shop.name.change_tips_2'.tr}'),
            const SizedBox(height: 6),
            Text('- ${'app.user.shop.name.change_tips_3'.tr}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('app.common.confirm'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
