import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/order_filter_sheet.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/shop/shop_order_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class MyPurchasePage extends StatefulWidget {
  const MyPurchasePage({super.key});

  @override
  State<MyPurchasePage> createState() => _MyPurchasePageState();
}

class _MyPurchasePageState extends State<MyPurchasePage>
    with SingleTickerProviderStateMixin {
  final ShopOrderController controller = Get.isRegistered<ShopOrderController>()
      ? Get.find<ShopOrderController>()
      : Get.put(ShopOrderController());
  final ApiSteamServer _steamApi = ApiSteamServer();

  late final TabController _tabController;
  late int _currentAppId;
  final ScrollController _receiptScroll = ScrollController();
  final ScrollController _recordScroll = ScrollController();
  final TextEditingController _receiptSearchController =
      TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();
  void _handleSearchTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  static const List<StatusOption> _statusOptions = [
    StatusOption(
      labelKey: 'app.market.filter.all',
      values: [-2, -1, 1, 2, 3, 4, 5, 6, 9],
    ),
    StatusOption(labelKey: 'app.trade.filter.in', values: [2, 3, 4]),
    StatusOption(labelKey: 'app.trade.filter.failed', values: [-1]),
    StatusOption(labelKey: 'app.trade.filter.revoked', values: [-2]),
    StatusOption(labelKey: 'app.trade.filter.settling', values: [5]),
    StatusOption(labelKey: 'app.trade.filter.success', values: [6]),
  ];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    int initialTab = 0;
    if (args is Map && args['initialTab'] is int) {
      initialTab = args['initialTab'] as int;
    }
    if (initialTab < 0 || initialTab > 1) {
      initialTab = 0;
    }
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _currentAppId = GameStorage.getGameType();
    _receiptScroll.addListener(_handleReceiptScroll);
    _recordScroll.addListener(_handleRecordScroll);
    _receiptSearchController.addListener(_handleSearchTextChange);
    _recordSearchController.addListener(_handleSearchTextChange);
    controller.refreshWaitingReceipts();
    controller.refreshBuyRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiptScroll
      ..removeListener(_handleReceiptScroll)
      ..dispose();
    _recordScroll
      ..removeListener(_handleRecordScroll)
      ..dispose();
    _receiptSearchController.removeListener(_handleSearchTextChange);
    _recordSearchController.removeListener(_handleSearchTextChange);
    _receiptSearchController.dispose();
    _recordSearchController.dispose();
    super.dispose();
  }

  void _handleReceiptScroll() {
    if (_receiptScroll.position.pixels >
        _receiptScroll.position.maxScrollExtent - 200) {
      controller.loadWaitingReceipts();
    }
  }

  void _handleRecordScroll() {
    if (_recordScroll.position.pixels >
        _recordScroll.position.maxScrollExtent - 200) {
      controller.loadBuyRecords();
    }
  }

  ShopSchemaInfo? _lookupSchema(
    Map<String, ShopSchemaInfo> schemas,
    ShopOrderDetail? detail,
  ) {
    if (detail == null) {
      return null;
    }
    final hash = detail.marketHashName;
    if (hash != null && schemas.containsKey(hash)) {
      return schemas[hash];
    }
    final key = detail.schemaId?.toString();
    if (key != null && schemas.containsKey(key)) {
      return schemas[key];
    }
    return null;
  }

  double _sumOrderPrice(ShopOrderItem order) {
    if (order.price != null) {
      return order.price!;
    }
    double total = 0;
    for (final detail in order.details) {
      final unit = detail.price ?? 0;
      final count = detail.count ?? 1;
      total += unit * count;
    }
    return total;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MM-dd HH:mm').format(date);
  }

  Future<void> _openReceiptFilterSheet() async {
    final result = await showModalBottomSheet<OrderFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderFilterSheet(
        initial: OrderFilterResult(
          startDate: controller.waitingStartDate.value,
          endDate: controller.waitingEndDate.value,
        ),
        statusOptions: _statusOptions,
        showStatus: false,
        showDateRange: true,
      ),
    );
    if (result != null) {
      await controller.applyWaitingFilter(
        startDate: result.startDate,
        endDate: result.endDate,
      );
    }
  }

  Future<void> _openBuyRecordFilterSheet() async {
    final result = await showModalBottomSheet<OrderFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderFilterSheet(
        initial: OrderFilterResult(
          statusList: controller.buyRecordStatusList.toList(),
          startDate: controller.buyRecordStartDate.value,
          endDate: controller.buyRecordEndDate.value,
        ),
        statusOptions: _statusOptions,
        showStatus: true,
        showDateRange: true,
      ),
    );
    if (result != null) {
      await controller.applyBuyRecordFilter(
        statusList: result.statusList,
        startDate: result.startDate,
        endDate: result.endDate,
      );
    }
  }

  Future<void> _switchGame(int appId) async {
    if (appId == GameStorage.getGameType()) {
      return;
    }
    await GameStorage.setGameType(appId);
    if (mounted) {
      setState(() => _currentAppId = appId);
    }
    controller.refreshWaitingReceipts();
    controller.refreshBuyRecords();
  }

  Future<void> _receiveOrder(ShopOrderItem order) async {
    final id = order.id?.toString();
    if (id == null) {
      return;
    }
    final steamStatus = await _steamApi.steamOnlineState();
    if (steamStatus.datas != true) {
      final tradeOfferId = order.tradeOfferId ?? '';
      if (tradeOfferId.isNotEmpty) {
        Get.toNamed(
          Routers.RECEIVE_GOODS,
          arguments: {'tradeOfferId': tradeOfferId},
        );
      } else {
        Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
      }
      return;
    }
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
    try {
      await controller.acceptTradeOffer(id);
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.success'.tr);
    } catch (_) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.menu.buy'.tr),
        actions: [
          Builder(
            builder: (iconContext) {
              return IconButton(
                icon: Image.asset(
                  'assets/images/game/icon/$_currentAppId.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.videogame_asset);
                  },
                ),
                onPressed: () async {
                  final selected = await showGameSwitchMenu(
                    iconContext: iconContext,
                    currentAppId: _currentAppId,
                  );
                  if (selected == null) {
                    return;
                  }
                  await _switchGame(selected);
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'app.market.product.wait_for_receipt'.tr),
            Tab(text: 'app.user.menu.buy'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWaitingReceipts(), _buildBuyRecords(currency)],
      ),
    );
  }

  Widget _buildWaitingReceipts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white38 : Colors.grey[400];
    final hasKeyword = _receiptSearchController.text.trim().isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _receiptSearchController,
                    onSubmitted: controller.searchWaiting,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'app.market.filter.search'.tr,
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.search,
                        color: hintColor,
                        size: 20,
                      ),
                      suffixIcon: hasKeyword
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _receiptSearchController.clear();
                                controller.searchWaiting('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'app.market.filter.search'.tr,
                icon: const Icon(Icons.search),
                onPressed: () =>
                    controller.searchWaiting(_receiptSearchController.text),
              ),
              Obx(() {
                return IconButton(
                  tooltip: 'app.market.filter.time'.tr,
                  icon: Icon(
                    controller.waitingSortAsc.value
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  onPressed: controller.toggleWaitingSort,
                );
              }),
              IconButton(
                tooltip: 'app.market.filter.text'.tr,
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: _openReceiptFilterSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (controller.waitingReceipts.isEmpty &&
                controller.isLoadingWaiting.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final showLoadingFooter =
                controller.isLoadingWaiting.value &&
                controller.waitingReceipts.isNotEmpty;
            final showNoMoreFooter =
                controller.waitingReceipts.isNotEmpty &&
                !controller.isLoadingWaiting.value &&
                !controller.waitingHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return RefreshIndicator(
              onRefresh: controller.refreshWaitingReceipts,
              child: ListView.separated(
                controller: _receiptScroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount:
                    controller.waitingReceipts.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= controller.waitingReceipts.length) {
                    return _buildLoadMoreFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final order = controller.waitingReceipts[index];
                  final detail = order.details.isNotEmpty
                      ? order.details.first
                      : null;
                  final schema = _lookupSchema(controller.schemas, detail);
                  final imageUrl = detail?.imageUrl ?? schema?.imageUrl ?? '';
                  final title = detail?.marketName ?? schema?.marketName ?? '-';
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => const SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, _, __) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                      title: Text(title, maxLines: 2),
                      subtitle: Text(
                        _formatTime(order.changeTime ?? order.createTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: FilledButton(
                        onPressed: () => _receiveOrder(order),
                        child: Text('app.market.product.receive'.tr),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBuyRecords(CurrencyController currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white38 : Colors.grey[400];
    final hasKeyword = _recordSearchController.text.trim().isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _recordSearchController,
                    onSubmitted: controller.searchBuyRecords,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'app.market.filter.search'.tr,
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.search,
                        color: hintColor,
                        size: 20,
                      ),
                      suffixIcon: hasKeyword
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _recordSearchController.clear();
                                controller.searchBuyRecords('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'app.market.filter.search'.tr,
                icon: const Icon(Icons.search),
                onPressed: () =>
                    controller.searchBuyRecords(_recordSearchController.text),
              ),
              Obx(() {
                return IconButton(
                  tooltip: 'app.market.filter.time'.tr,
                  icon: Icon(
                    controller.buyRecordSortAsc.value
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  onPressed: controller.toggleBuyRecordSort,
                );
              }),
              IconButton(
                tooltip: 'app.market.filter.text'.tr,
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: _openBuyRecordFilterSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (controller.buyRecords.isEmpty &&
                controller.isLoadingRecords.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final showLoadingFooter =
                controller.isLoadingRecords.value &&
                controller.buyRecords.isNotEmpty;
            final showNoMoreFooter =
                controller.buyRecords.isNotEmpty &&
                !controller.isLoadingRecords.value &&
                !controller.recordHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return RefreshIndicator(
              onRefresh: controller.refreshBuyRecords,
              child: ListView.separated(
                controller: _recordScroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: controller.buyRecords.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= controller.buyRecords.length) {
                    return _buildLoadMoreFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final order = controller.buyRecords[index];
                  final detail = order.details.isNotEmpty
                      ? order.details.first
                      : null;
                  final schema = _lookupSchema(controller.schemas, detail);
                  final imageUrl = detail?.imageUrl ?? schema?.imageUrl ?? '';
                  final title = detail?.marketName ?? schema?.marketName ?? '-';
                  final price = _sumOrderPrice(order);
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => const SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, _, __) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                      title: Text(title, maxLines: 2),
                      subtitle: Text(
                        _formatTime(order.createTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Obx(
                            () => Text(
                              currency.format(price),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.statusName ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLoadMoreFooter({
    required bool showLoading,
    required bool showNoMore,
  }) {
    if (showLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (showNoMore) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }
    return const SizedBox(height: 4);
  }
}
