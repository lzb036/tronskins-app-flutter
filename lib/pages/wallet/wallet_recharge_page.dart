import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletRechargePage extends StatefulWidget {
  const WalletRechargePage({super.key});

  @override
  State<WalletRechargePage> createState() => _WalletRechargePageState();
}

class _WalletRechargePageState extends State<WalletRechargePage>
    with SingleTickerProviderStateMixin {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());

  late final TabController _tabController;
  final TextEditingController _secretKeyController = TextEditingController();
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isSubmittingChargeCard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.refreshUser();
    _loadWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _secretKeyController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    await controller.loadOfficialWallet();
    _startCountdown(controller.officialWallet.value?.remainTime ?? 0);
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    _remainingSeconds = seconds;
    if (_remainingSeconds <= 0) {
      setState(() {});
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _remainingSeconds = 0;
        _loadWallet();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  String _formatRemaining(int seconds) {
    if (seconds <= 0) {
      return '00:00';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _copyAddress(String address) async {
    if (address.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: address));
    _showTopSnack('app.system.message.copy_success'.tr, isSuccess: true);
  }

  Future<void> _submitChargeCard() async {
    if (_isSubmittingChargeCard) {
      _showTopSnack('app.system.tips.please_wait'.tr);
      return;
    }
    final value = _secretKeyController.text.trim();
    if (value.isEmpty || value.length != 32) {
      _showTopSnack(
        'app.user.recharge.secretKey_placeholder'.tr,
        isError: true,
      );
      return;
    }
    setState(() => _isSubmittingChargeCard = true);
    try {
      final result = await controller.consumeChargeCard(value);
      if (result.success) {
        _secretKeyController.clear();
        _showTopSnack('app.user.recharge.message.success'.tr, isSuccess: true);
        _returnToWalletAndClearRechargeRoute();
        return;
      }
      _showTopSnack(_resolveErrorMessage(result), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingChargeCard = false);
      }
    }
  }

  void _showTopSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (isSuccess) {
      AppSnackbar.success(message);
      return;
    }
    if (isError) {
      AppSnackbar.error(message);
      return;
    }
    AppSnackbar.info(message);
  }

  String? _extractMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (data is Map) {
      for (final key in ['message', 'msg', 'error', 'detail', 'desc']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String _resolveErrorMessage(dynamic response) {
    final rawMessage = response?.message;
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage;
    }
    final dataMessage = _extractMessage(response?.datas);
    if (dataMessage != null) {
      return dataMessage;
    }
    return 'app.trade.filter.failed'.tr;
  }

  void _returnToWalletAndClearRechargeRoute() {
    var walletFound = false;
    Get.until((route) {
      final isWallet = route.settings.name == Routers.WALLET;
      if (isWallet) {
        walletFound = true;
      }
      return isWallet;
    });
    if (!walletFound) {
      Get.offAllNamed(Routers.WALLET);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        backgroundColor: WalletUi.pageBackground(context),
        appBar: AppBar(
          title: Text('app.user.recharge.title'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.toNamed(Routers.WALLET_RECHARGE_RECORD),
              child: Text('app.user.wallet.recharge_record'.tr),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'app.user.wallet.usdt'.tr),
              Tab(text: 'app.user.recharge.card'.tr),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [Obx(() => _buildUsdtTab(currency)), _buildCardTab()],
        ),
      ),
    );
  }

  Widget _buildUsdtTab(CurrencyController currency) {
    final wallet = controller.officialWallet.value;
    final balance = controller.userInfo.value?.fund?.balance ?? 0;
    final address = wallet?.walletAddress ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: WalletUi.primaryGradient(context),
            borderRadius: WalletUi.cardRadius,
            boxShadow: WalletUi.gradientShadow(context),
          ),
          child: Column(
            children: [
              Text(
                currency.formatUsd(balance),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'app.user.wallet.account'.tr,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (controller.isLoadingOfficialWallet.value)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              if (address.isNotEmpty)
                QrImageView(
                  data: address,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              const SizedBox(height: 12),
              Text(
                _formatRemaining(_remainingSeconds),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _copyAddress(address),
                child: Card(
                  elevation: 0,
                  shape: WalletUi.cardShape(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'app.user.recharge.payment_collection_address'
                                    .tr,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                address,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy_outlined),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTips([
                'app.user.recharge.tips'.tr,
                'app.user.recharge.tips_4'.tr,
                'app.user.recharge.tips_5'.tr,
                'app.user.recharge.tips_2'.tr,
                'app.user.recharge.tips_3'.tr,
              ]),
            ],
          ),
      ],
    );
  }

  Widget _buildCardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: WalletUi.cardDecoration(context),
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _secretKeyController,
            decoration: WalletUi.inputDecoration(
              context,
              labelText: 'app.user.wallet.secret_key'.tr,
              hintText: 'app.user.recharge.secretKey_placeholder'.tr,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isSubmittingChargeCard ? null : _submitChargeCard,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSubmittingChargeCard
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text('app.common.confirm'.tr),
        ),
        const SizedBox(height: 16),
        _buildTips([
          'app.user.recharge.tips_2'.tr,
          'app.user.recharge.tips_3'.tr,
        ]),
      ],
    );
  }

  Widget _buildTips(List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${i + 1}. ${tips[i]}'),
          ),
      ],
    );
  }
}
