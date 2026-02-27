import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/components/notify/notify_trade_deliver_sheet.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletLockedDetailPage extends StatefulWidget {
  const WalletLockedDetailPage({super.key});

  @override
  State<WalletLockedDetailPage> createState() => _WalletLockedDetailPageState();
}

class _WalletLockedDetailPageState extends State<WalletLockedDetailPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final ApiSteamServer _steamApi = ApiSteamServer();

  Map<String, dynamic> args = const {};
  bool _loading = true;
  WalletLockedDetail? _detail;

  @override
  void initState() {
    super.initState();
    args = (Get.arguments as Map<String, dynamic>?) ?? {};
    controller.refreshUser();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = args['id']?.toString();
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final detail = await controller.loadLockedDetail(
      id: id,
      lockType: args['lockType'] as int?,
    );
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  String _formatTime(int? value) {
    if (value == null) {
      return '-';
    }
    var timestamp = value;
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'app.system.tips.title'.tr,
      'app.system.message.copy_success'.tr,
    );
  }

  void _showTopSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final backgroundColor = isSuccess
        ? Colors.green
        : isError
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
    final colorText = (isSuccess || isError)
        ? Colors.white
        : Theme.of(context).colorScheme.onPrimary;
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: backgroundColor,
      colorText: colorText,
      snackPosition: SnackPosition.TOP,
    );
  }

  String _currentUserId() {
    return controller.userInfo.value?.id?.trim() ?? '';
  }

  bool _isBuyer(WalletLockedOrder? order) {
    if (order == null) {
      return false;
    }
    final userId = _currentUserId();
    final buyerId = order.buyerId?.trim() ?? '';
    if (userId.isEmpty || buyerId.isEmpty) {
      return false;
    }
    return userId == buyerId;
  }

  bool _isSeller(WalletLockedOrder? order) {
    if (order == null) {
      return false;
    }
    final userId = _currentUserId();
    final sellerId = order.sellerId?.trim() ?? '';
    if (userId.isEmpty || sellerId.isEmpty) {
      return false;
    }
    return userId == sellerId;
  }

  Future<void> _openDeliverDrawer(WalletLockedOrder order) async {
    final buyerId = order.buyerId?.trim() ?? '';
    if (buyerId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }
    await showNotifyTradeDeliverSheet(
      context,
      buyerId: buyerId,
      status: order.status,
      onDelivered: () {
        _loadDetail();
      },
    );
  }

  Future<void> _receiveGoods(WalletLockedOrder order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.trade.receipt.message.confirm_auto'.tr),
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
    if (confirmed != true) {
      return;
    }

    final orderId = order.id?.toString() ?? '';
    if (orderId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }

    try {
      final steamStatus = await _steamApi.steamOnlineState();
      if (steamStatus.datas != true) {
        final tradeOfferId = order.tradeOfferId ?? '';
        if (tradeOfferId.isNotEmpty) {
          Get.toNamed(
            Routers.RECEIVE_GOODS,
            arguments: {'tradeOfferId': tradeOfferId},
          );
        } else {
          _showTopSnack('app.trade.filter.failed'.tr, isError: true);
        }
        return;
      }

      final response = await _shopApi.tradeofferReceipt(id: orderId);
      if (response.success) {
        _showTopSnack(
          response.message.isNotEmpty
              ? response.message
              : 'app.system.message.success'.tr,
          isSuccess: true,
        );
        await _loadDetail();
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              Get.back();
            }
          });
        }
      } else {
        _showTopSnack(
          response.message.isNotEmpty
              ? response.message
              : 'app.trade.filter.failed'.tr,
          isError: true,
        );
      }
    } catch (_) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
    }
  }

  Future<void> _cancelOrder(WalletLockedOrder order) async {
    final orderId = order.id?.toString() ?? '';
    if (orderId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final changeTime = order.changeTime ?? order.createTime ?? 0;
    final isCancelTimeLess =
        changeTime > 0 && (nowSeconds - changeTime).abs() <= 1800;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.trade.order.cancel'.tr),
        content: Text(
          isCancelTimeLess
              ? 'app.trade.order.message.cancel_time_less'.tr
              : 'app.trade.order.message.confirm_cancel'.tr,
        ),
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
    if (confirmed != true) {
      return;
    }

    try {
      final response = await _shopApi.cancelOrder(id: orderId);
      if (response.success) {
        _showTopSnack('app.system.message.success'.tr, isSuccess: true);
        await _loadDetail();
        if (mounted) {
          Get.back();
        }
        return;
      }
      _showTopSnack(
        response.message.isNotEmpty
            ? response.message
            : 'app.trade.filter.failed'.tr,
        isError: true,
      );
    } catch (_) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
    }
  }

  Widget? _buildBottomActions() {
    final order = _detail?.order;
    if (order == null) {
      return null;
    }
    final status = order.status ?? -999;
    final isSeller = _isSeller(order);
    final isBuyer = _isBuyer(order);

    final actions = <Widget>[];
    if (isSeller && status == 2) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _openDeliverDrawer(order),
            child: Text('app.market.product.deliver'.tr),
          ),
        ),
      );
    }
    if (isBuyer && status == 4) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _receiveGoods(order),
            child: Text('app.market.product.receive'.tr),
          ),
        ),
      );
    }
    if (isBuyer && status == 2) {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelOrder(order),
            child: Text('app.trade.order.cancel'.tr),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(
        title: Text('app.trade.order.details'.tr),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(Routers.FEEDBACK_LIST),
            icon: const Icon(Icons.support_agent_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
          ? Center(child: Text('app.common.no_data'.tr))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOrderInfo(currency),
                const SizedBox(height: 16),
                _buildAssetInfo(currency),
                const SizedBox(height: 16),
                _buildTips(),
              ],
            ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildOrderInfo(CurrencyController currency) {
    final order = _detail?.order;
    final orderId = order?.id?.toString() ?? '-';
    final price = currency.formatUsd(order?.price ?? 0);
    final time = _formatTime(order?.changeTime ?? order?.createTime);
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('${'app.trade.order.number'.tr}: $orderId'),
                const Spacer(),
                TextButton(
                  onPressed: () => _copy(orderId),
                  child: Text('app.common.copy'.tr),
                ),
              ],
            ),
            Row(
              children: [
                Text('${'app.trade.order.total_price'.tr}:'),
                const Spacer(),
                Text(
                  price,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${'app.trade.order.time'.tr}:'),
                const Spacer(),
                Text(time),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetInfo(CurrencyController currency) {
    final schema = _detail?.schema;
    final name = schema?.marketName ?? schema?.marketHashName ?? '-';
    final sellMin = schema?.sellMin;
    final buyMax = schema?.buyMax;
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (sellMin != null)
              Text(
                '${'app.market.detail.sale_lowest'.tr} '
                '${currency.formatUsd(sellMin)}',
              ),
            if (buyMax != null)
              Text(
                '${'app.market.detail.purchase_highest'.tr} '
                '${currency.formatUsd(buyMax)}',
              ),
            if (schema?.paintWear != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${'app.market.csgo.abradability'.tr}: '
                  '${schema?.paintWear?.toStringAsFixed(2)}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    final tips = [
      'app.trade.order.buyer_tips_1'.tr,
      'app.trade.order.buyer_tips_2'.tr,
      'app.trade.order.buyer_tips_3'.tr,
      'app.trade.order.buyer_tips_4'.tr,
    ];
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.system.tips.warm'.tr,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < tips.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. ${tips[i]}'),
              ),
          ],
        ),
      ),
    );
  }
}
