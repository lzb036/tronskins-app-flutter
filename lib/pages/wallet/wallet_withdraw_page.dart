import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletWithdrawPage extends StatefulWidget {
  const WalletWithdrawPage({super.key});

  @override
  State<WalletWithdrawPage> createState() => _WalletWithdrawPageState();
}

class _WalletWithdrawPageState extends State<WalletWithdrawPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _addressAccountController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.refreshUser();
    controller.loadWithdrawAddresses();
    controller.loadWithdrawFee();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressNameController.dispose();
    _addressAccountController.dispose();
    super.dispose();
  }

  String _formatTips(String template, String value) {
    return template.replaceAll('{0}', value);
  }

  void _fillAll() {
    final available = controller.userInfo.value?.fund?.available ?? 0;
    _amountController.text = available.toStringAsFixed(2);
  }

  bool _isValidAmountInput(String value) {
    return RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(value);
  }

  String _limitAmountText(String raw, {bool showToast = false}) {
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    value = value.replaceAll(',', '.').replaceAll(RegExp(r'\s+'), '');
    value = value.replaceAll(RegExp(r'[^0-9\.]'), '');
    final firstDot = value.indexOf('.');
    if (firstDot >= 0) {
      final integer = value.substring(0, firstDot);
      final decimal = value.substring(firstDot + 1).replaceAll('.', '');
      value = '$integer.$decimal';
    }

    if (value.startsWith('.')) {
      value = '0$value';
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      if (showToast) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.market.filter.message.price_error'.tr,

          titleText: const SizedBox.shrink(),
        );
      }
      return '';
    }

    var limited = parsed;
    final available = controller.userInfo.value?.fund?.available;
    if (available != null && limited > available) {
      limited = available;
    }

    final fixed = limited.toStringAsFixed(2);
    if (value.contains('.')) {
      final decimals = value.split('.').last;
      if (decimals.isEmpty) {
        value = '${limited.truncate()}.';
      } else if (decimals.length == 1) {
        value = fixed.substring(0, fixed.length - 1);
      } else {
        value = fixed;
      }
    } else {
      value = limited.truncate().toString();
    }

    if (!_isValidAmountInput(value)) {
      return limited.toStringAsFixed(2);
    }
    return value;
  }

  void _onAmountChanged(String value) {
    final limited = _limitAmountText(value, showToast: true);
    if (limited != value) {
      _amountController.value = TextEditingValue(
        text: limited,
        selection: TextSelection.collapsed(offset: limited.length),
      );
    }
  }

  void _normalizeAmountOnBlur() {
    final value = _amountController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      _amountController.clear();
      return;
    }
    _amountController.text = amount.toStringAsFixed(2);
  }

  Future<void> _submitWithdraw() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.message.enter_amount'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (amount < 10) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.message.amount_error'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (amount > 20000) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.max_message'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    final available = controller.userInfo.value?.fund?.available ?? 0;
    if (amount > available) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.message.enter_amount'.tr,

        titleText: const SizedBox.shrink(),
      );
      _amountController.text = available.toStringAsFixed(2);
      return;
    }
    final address = controller.selectedWithdrawAddress.value;
    if (address == null || (address.account ?? '').isEmpty) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.enter_address'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    final user = controller.userInfo.value;
    final tokens = await TwoFactorStorage.getList();
    if (user?.need2FA != true ||
        user?.safeTokenStatus != true ||
        tokens.isEmpty) {
      await _promptGuardSetup();
      return;
    }
    TwoFactorToken? token;
    for (final item in tokens) {
      if (item.userId == (user?.id ?? '') &&
          item.appUse == (user?.appUse ?? '')) {
        token = item;
        break;
      }
    }
    if (token == null || token.secret.isEmpty) {
      await _promptGuardSetup();
      return;
    }
    final twoFa = TwoFactorHelper.generateCode(token.secret);
    if (twoFa.isEmpty) {
      await _promptGuardSetup();
      return;
    }
    final success = await controller.submitWithdraw(
      amount: amount,
      account: address.account ?? '',
      twoFa: twoFa,
    );
    if (success) {
      _amountController.clear();
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.message.success'.tr,

        titleText: const SizedBox.shrink(),
      );
    }
  }

  Future<void> _promptGuardSetup() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.user.guard.set_tips'.tr),
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
      Get.toNamed(Routers.USER_GUARD);
    }
  }

  void _showAddressSheet() {
    controller.loadWithdrawAddresses();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'app.user.withdraw.select_address'.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final list = controller.withdrawAddresses;
                  if (controller.isLoadingAddresses.value) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('app.common.no_data'.tr),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        title: Text(item.name ?? ''),
                        subtitle: Text(item.account ?? ''),
                        onTap: () {
                          controller.selectedWithdrawAddress.value = item;
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _confirmDeleteAddress(item.id),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddAddressSheet();
                  },
                  icon: const Icon(Icons.add),
                  label: Text('app.user.withdraw.add_address'.tr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAddress(String? id) async {
    if (id == null) {
      return;
    }
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.user.withdraw.message.delete_address'.tr),
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
      final ok = await controller.removeWithdrawAddress(id);
      if (ok) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.system.message.success'.tr,

          titleText: const SizedBox.shrink(),
        );
      }
    }
  }

  void _showAddAddressSheet() {
    _addressNameController.clear();
    _addressAccountController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'app.user.withdraw.add_address'.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressNameController,
                  decoration: InputDecoration(
                    labelText: 'app.user.withdraw.message.enter_name'.tr,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressAccountController,
                  decoration: InputDecoration(
                    labelText: 'app.user.wallet.address'.tr,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final name = _addressNameController.text.trim();
                    final account = _addressAccountController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar(
                        'app.system.tips.title'.tr,
                        'app.user.withdraw.message.name_empty'.tr,

                        titleText: const SizedBox.shrink(),
                      );
                      return;
                    }
                    if (account.isEmpty) {
                      Get.snackbar(
                        'app.system.tips.title'.tr,
                        'app.user.withdraw.enter_address'.tr,

                        titleText: const SizedBox.shrink(),
                      );
                      return;
                    }
                    final ok = await controller.addWithdrawAddress(
                      name: name,
                      account: account,
                    );
                    if (ok) {
                      Get.back();
                      Get.snackbar(
                        'app.system.tips.title'.tr,
                        'app.system.message.success'.tr,

                        titleText: const SizedBox.shrink(),
                      );
                    }
                  },
                  child: Text('app.common.confirm'.tr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(
        title: Text('app.user.withdraw.title'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.toNamed(Routers.WALLET_WITHDRAW_RECORD),
            child: Text('app.user.wallet.withdraw_record'.tr),
          ),
        ],
      ),
      body: Obx(() {
        final available = controller.userInfo.value?.fund?.available ?? 0;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: WalletUi.primaryGradient(context),
                borderRadius: WalletUi.cardRadius,
                boxShadow: WalletUi.gradientShadow(context),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'app.user.withdraw.available_balance'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currency.formatUsd(available),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: WalletUi.cardShape(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('app.user.wallet.address'.tr),
                      subtitle: Text(
                        controller.selectedWithdrawAddress.value?.name ??
                            'app.user.withdraw.select_address'.tr,
                      ),
                      trailing: const Icon(Icons.expand_more),
                      onTap: _showAddressSheet,
                    ),
                    const SizedBox(height: 12),
                    Text('app.user.withdraw.amount'.tr),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currency.usdSymbol,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: _onAmountChanged,
                            onEditingComplete: _normalizeAmountOnBlur,
                            decoration: WalletUi.inputDecoration(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _fillAll,
                          child: Text('app.user.withdraw.full_title'.tr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('app.inventory.upshop.handling_charge'.tr),
                        Text(
                          '${currency.usdSymbol} ${controller.withdrawFee.value.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitWithdraw,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('app.common.confirm'.tr),
            ),
            const SizedBox(height: 16),
            Text('1. ${'app.user.withdraw.tips'.tr}'),
            const SizedBox(height: 6),
            Text(
              '2. ${_formatTips('app.user.withdraw.tips_2'.tr, controller.withdrawFee.value.toStringAsFixed(2))}',
            ),
            const SizedBox(height: 6),
            Text('3. ${'app.user.withdraw.tips_3'.tr}'),
          ],
        );
      }),
    );
  }
}
