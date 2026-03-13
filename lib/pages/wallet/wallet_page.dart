import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    if (userController.isLoggedIn.value) {
      controller.refreshUser();
    }
  }

  Future<void> _navigateRecharge() async {
    if (!userController.isLoggedIn.value) {
      return;
    }
    final allow = await controller.checkRechargeEnable();
    if (allow == false) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.recharge.disable'.tr,
        titleText: const SizedBox.shrink(),
      );
      return;
    }
    Get.toNamed(Routers.WALLET_RECHARGE);
  }

  Future<void> _navigateWithdraw() async {
    final allow = await controller.checkWithdrawEnable();
    if (allow == false) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.withdraw.disable'.tr,
        titleText: const SizedBox.shrink(),
      );
      return;
    }
    Get.toNamed(Routers.WALLET_WITHDRAW);
  }

  Future<void> _refreshWallet() async {
    if (!userController.isLoggedIn.value) {
      return;
    }
    await controller.refreshUser(showLoading: true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Obx(() {
      final loggedIn = userController.isLoggedIn.value;
      final refreshing = controller.isLoadingUser.value;
      return Scaffold(
        backgroundColor: WalletUi.pageBackground(context),
        appBar: AppBar(
          title: Text('app.user.wallet.title'.tr),
          actions: loggedIn
              ? [
                  IconButton(
                    tooltip: 'app.common.refresh'.tr,
                    onPressed: refreshing ? null : _refreshWallet,
                    icon: const Icon(Icons.refresh),
                  ),
                ]
              : const [],
        ),
        body: loggedIn
            ? refreshing
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        Obx(() => _buildHeader(context, currency)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildActionTile(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'app.user.recharge.title'.tr,
                                onTap: _navigateRecharge,
                              ),
                              _buildActionTile(
                                icon: Icons.outbox_outlined,
                                title: 'app.user.withdraw.title'.tr,
                                onTap: _navigateWithdraw,
                              ),
                              _buildActionTile(
                                icon: Icons.receipt_long_outlined,
                                title: 'app.user.wallet.flow'.tr,
                                onTap: () => Get.toNamed(Routers.WALLET_FLOW),
                              ),
                              _buildActionTile(
                                icon: Icons.timer_outlined,
                                title: 'app.user.wallet.unsettled_details'.tr,
                                onTap: () =>
                                    Get.toNamed(Routers.WALLET_SETTLEMENT),
                              ),
                              _buildActionTile(
                                icon: Icons.lock_clock_outlined,
                                title: 'app.user.wallet.lock_details'.tr,
                                onTap: () => Get.toNamed(Routers.WALLET_LOCKED),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
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
            style: FilledButton.styleFrom(
              minimumSize: const Size(180, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text('app.user.login.nologin'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CurrencyController currency) {
    final fund = controller.userInfo.value?.fund;
    final balance = fund?.balance ?? 0;
    final available = fund?.available ?? 0;
    final locked = fund?.locked ?? 0;
    final gift = fund?.gift ?? 0;
    final settlement = fund?.settlement ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        gradient: WalletUi.primaryGradient(context),
        borderRadius: WalletUi.cardRadius,
        boxShadow: WalletUi.gradientShadow(context),
      ),
      child: Column(
        children: [
          Text(
            '${'app.user.wallet.assets_total'.tr} '
            '(${currency.formatUsd(balance)})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                label: 'app.user.wallet.available'.tr,
                value: currency.formatUsd(available),
                onTap: () => Get.toNamed(Routers.WALLET_FLOW),
              ),
              _buildSummaryItem(
                context,
                label: 'app.user.wallet.lock_amount'.tr,
                value: currency.formatUsd(locked),
                onTap: () => Get.toNamed(Routers.WALLET_LOCKED),
              ),
              _buildSummaryItem(
                context,
                label: 'app.user.wallet.gift'.tr,
                value: currency.formatUsd(gift),
              ),
              _buildSummaryItem(
                context,
                label: 'app.user.wallet.unsettled'.tr,
                value: currency.formatUsd(settlement),
                onTap: () => Get.toNamed(Routers.WALLET_SETTLEMENT),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final child = Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
    if (onTap == null) {
      return child;
    }
    return InkWell(onTap: onTap, child: child);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
