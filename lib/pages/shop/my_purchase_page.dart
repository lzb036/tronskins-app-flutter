import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/order_filter_sheet.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
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
    if (args is Map && args['mode']?.toString() == 'records') {
      initialTab = 1;
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
    final result = await OrderFilterSheet.showFromRight(
      context: context,
      initial: OrderFilterResult(
        itemName: controller.waitingItemName.value,
        tags: Map<String, dynamic>.from(controller.waitingTags),
      ),
      statusOptions: _statusOptions,
      showStatus: false,
      showDateRange: false,
      enableAttributeFilter: true,
      appId: _currentAppId,
    );
    if (result != null) {
      await controller.applyWaitingFilter(
        startDate: result.startDate,
        endDate: result.endDate,
        tags: result.tags,
        itemName: result.itemName,
      );
    }
  }

  Future<void> _openBuyRecordFilterSheet() async {
    final result = await OrderFilterSheet.showFromRight(
      context: context,
      initial: OrderFilterResult(
        statusList: controller.buyRecordStatusList.toList(),
        startDate: controller.buyRecordStartDate.value,
        endDate: controller.buyRecordEndDate.value,
        itemName: controller.buyRecordItemName.value,
        tags: Map<String, dynamic>.from(controller.buyRecordTags),
      ),
      statusOptions: _statusOptions,
      showStatus: true,
      showDateRange: true,
      enableAttributeFilter: true,
      appId: _currentAppId,
    );
    if (result != null) {
      await controller.applyBuyRecordFilter(
        statusList: result.statusList,
        startDate: result.startDate,
        endDate: result.endDate,
        tags: result.tags,
        itemName: result.itemName,
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

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  TagInfo? _schemaTag(ShopSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  int _resolveDetailAppId(ShopOrderDetail? detail, ShopSchemaInfo? schema) {
    final raw = detail?.raw;
    final schemaRaw = schema?.raw;
    final rawApp = raw?['app_id'] ?? raw?['appId'];
    final schemaApp = schemaRaw?['app_id'] ?? schemaRaw?['appId'];
    return _asInt(rawApp) ?? _asInt(schemaApp) ?? _currentAppId;
  }

  Future<void> _openOrderDetail(ShopOrderItem order) async {
    await Get.toNamed(
      Routers.SHOP_ORDER_DETAIL,
      arguments: {
        'order': order,
        'schemas': Map<String, ShopSchemaInfo>.from(controller.schemas),
        'users': Map<String, ShopUserInfo>.from(controller.users),
      },
    );
  }

  String _buildStatusText(ShopOrderItem order) {
    if (order.status == 6) {
      return 'app.trade.sale.success'.tr;
    }
    final statusName = order.statusName?.trim();
    if ([2, 3, 4].contains(order.status)) {
      return (statusName == null || statusName.isEmpty) ? '-' : statusName;
    }
    final cancelDesc = order.cancelDesc?.trim();
    if (![2, 3, 4, 5, 6].contains(order.status) &&
        cancelDesc != null &&
        cancelDesc.isNotEmpty) {
      return cancelDesc;
    }
    if (statusName != null && statusName.isNotEmpty) {
      return statusName;
    }
    return '-';
  }

  ({Color bg, Color fg}) _statusPalette(int? status) {
    if ([5, 6].contains(status)) {
      return (bg: const Color(0xFFE8F5E9), fg: const Color(0xFF008000));
    }
    if ([2, 3, 4].contains(status)) {
      return (bg: const Color(0xFFFDECEC), fg: const Color(0xFFC22121));
    }
    return (bg: const Color(0xFFF5F5F5), fg: const Color(0xFF888888));
  }

  Widget _buildStatusBadge(ShopOrderItem order) {
    final palette = _statusPalette(order.status);
    final text = _buildStatusText(order);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: palette.fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  double _waitingShippingHours(ShopOrderItem order) {
    final status = order.status;
    final type = order.type;
    if (status == 3) {
      return 0.5;
    }
    if (type == 2 && status == 2) {
      return 0.5;
    }
    if (type == 1 && status == 2) {
      return 18;
    }
    if (status == 4) {
      return 18;
    }
    return 18;
  }

  int _waitingDeadlineMs(ShopOrderItem order) {
    final changeTime = order.changeTime;
    if (changeTime == null || changeTime <= 0) {
      return 0;
    }
    final shippingMs = (_waitingShippingHours(order) * 3600 * 1000).round();
    return changeTime * 1000 + shippingMs;
  }

  bool _showWaitingCountdown(ShopOrderItem order) {
    final deadline = _waitingDeadlineMs(order);
    if (deadline <= 0) {
      return false;
    }
    return deadline > DateTime.now().millisecondsSinceEpoch;
  }

  bool _hasWaitingFilter() {
    if (controller.waitingItemName.value?.isNotEmpty == true) {
      return true;
    }
    return controller.waitingTags.isNotEmpty;
  }

  bool _hasBuyRecordFilter() {
    if (controller.buyRecordStatusList.isNotEmpty) {
      return true;
    }
    if (controller.buyRecordStartDate.value != null ||
        controller.buyRecordEndDate.value != null) {
      return true;
    }
    if (controller.buyRecordItemName.value?.isNotEmpty == true) {
      return true;
    }
    return controller.buyRecordTags.isNotEmpty;
  }

  Widget _buildSearchActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final background = active
        ? colors.primary.withValues(alpha: 0.12)
        : baseColor;
    final iconColor = active ? colors.primary : colors.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onSearch,
    required bool sortAsc,
    required VoidCallback onToggleSort,
    required VoidCallback onFilter,
    bool filterActive = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final hintColor = isDark ? Colors.white38 : colors.onSurfaceVariant;
    final hasKeyword = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: Material(
                color: fillColor,
                borderRadius: BorderRadius.circular(9),
                child: TextField(
                  controller: controller,
                  onSubmitted: onSubmitted,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'app.market.filter.search'.tr,
                    hintStyle: TextStyle(color: hintColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: hintColor, size: 18),
                    suffixIcon: hasKeyword
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              controller.clear();
                              onSubmitted('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildSearchActionButton(
            tooltip: 'app.market.filter.search'.tr,
            icon: Icons.send,
            onTap: onSearch,
          ),
          const SizedBox(width: 6),
          _buildSearchActionButton(
            tooltip: 'app.market.filter.time'.tr,
            icon: sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
            onTap: onToggleSort,
          ),
          const SizedBox(width: 6),
          _buildSearchActionButton(
            tooltip: 'app.market.filter.text'.tr,
            icon: Icons.filter_alt_outlined,
            onTap: onFilter,
            active: filterActive,
          ),
        ],
      ),
    );
  }

  Widget _buildPullToRefreshEmpty({
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 180),
          Center(child: Text('app.common.no_data'.tr)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              dividerColor: Colors.transparent,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
              tabs: [
                Tab(height: 30, text: 'app.market.product.wait_for_receipt'.tr),
                Tab(height: 30, text: 'app.user.menu.buy'.tr),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWaitingReceipts(currency), _buildBuyRecords(currency)],
      ),
    );
  }

  Widget _buildWaitingReceipts(CurrencyController currency) {
    return Column(
      children: [
        Obx(
          () => _buildSearchBar(
            controller: _receiptSearchController,
            onSubmitted: controller.searchWaiting,
            onSearch: () =>
                controller.searchWaiting(_receiptSearchController.text),
            sortAsc: controller.waitingSortAsc.value,
            onToggleSort: controller.toggleWaitingSort,
            onFilter: _openReceiptFilterSheet,
            filterActive: _hasWaitingFilter(),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.waitingReceipts.isEmpty &&
                controller.isLoadingWaiting.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.waitingReceipts.isEmpty) {
              return _buildPullToRefreshEmpty(
                onRefresh: controller.refreshWaitingReceipts,
              );
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
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount:
                    controller.waitingReceipts.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                  final imageUrl = detail?.imageUrl ?? schema?.imageUrl;
                  final title = detail?.marketName ?? schema?.marketName ?? '-';
                  final appId = _resolveDetailAppId(detail, schema);
                  final rarity = _schemaTag(schema, 'rarity');
                  final quality = _schemaTag(schema, 'quality');
                  final exterior = _schemaTag(schema, 'exterior');
                  final count = detail?.count ?? order.nums ?? 1;
                  final price = _sumOrderPrice(order);
                  final wear = detail?.paintWear;
                  final showCountdown = _showWaitingCountdown(order);
                  final deadlineMs = _waitingDeadlineMs(order);
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openOrderDetail(order),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatTime(
                                      order.changeTime ?? order.createTime,
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                _buildStatusBadge(order),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 98,
                                  height: 58,
                                  child: GameItemImage(
                                    imageUrl: imageUrl,
                                    appId: appId,
                                    rarity: rarity,
                                    quality: quality,
                                    exterior: exterior,
                                    count: count > 1 ? count : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (wear != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '${'app.market.csgo.abradability'.tr}: '
                                          '${wear.toStringAsFixed(6)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        WearProgressBar(paintWear: wear),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Obx(
                                      () => Text(
                                        currency.format(price),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (showCountdown) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            _InlineCountdownText(
                                              endTimeMs: deadlineMs,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 34,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(92, 34),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () => _receiveOrder(order),
                                  child: Text('app.market.product.receive'.tr),
                                ),
                              ),
                            ),
                          ],
                        ),
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
    return Column(
      children: [
        Obx(
          () => _buildSearchBar(
            controller: _recordSearchController,
            onSubmitted: controller.searchBuyRecords,
            onSearch: () =>
                controller.searchBuyRecords(_recordSearchController.text),
            sortAsc: controller.buyRecordSortAsc.value,
            onToggleSort: controller.toggleBuyRecordSort,
            onFilter: _openBuyRecordFilterSheet,
            filterActive: _hasBuyRecordFilter(),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.buyRecords.isEmpty &&
                controller.isLoadingRecords.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.buyRecords.isEmpty) {
              return _buildPullToRefreshEmpty(
                onRefresh: controller.refreshBuyRecords,
              );
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
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: controller.buyRecords.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= controller.buyRecords.length) {
                    return _buildLoadMoreFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final order = controller.buyRecords[index];
                  final details = order.details;
                  final hasMultiple = details.length > 1;
                  final detail = details.isNotEmpty ? details.first : null;
                  final schema = _lookupSchema(controller.schemas, detail);
                  final imageUrl = detail?.imageUrl ?? schema?.imageUrl;
                  final title = detail?.marketName ?? schema?.marketName ?? '-';
                  final appId = _resolveDetailAppId(detail, schema);
                  final rarity = _schemaTag(schema, 'rarity');
                  final quality = _schemaTag(schema, 'quality');
                  final exterior = _schemaTag(schema, 'exterior');
                  final price = _sumOrderPrice(order);
                  final protectionTime = order.protectionTime;
                  final showProtectionCountdown =
                      protectionTime != null &&
                      protectionTime > 0 &&
                      order.status == 5;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openOrderDetail(order),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatTime(order.createTime),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                _buildStatusBadge(order),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!hasMultiple)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 98,
                                    height: 58,
                                    child: GameItemImage(
                                      imageUrl: imageUrl,
                                      appId: appId,
                                      rarity: rarity,
                                      quality: quality,
                                      exterior: exterior,
                                      count: (detail?.count ?? 1) > 1
                                          ? detail?.count
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Obx(
                                    () => Text(
                                      currency.format(price),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...details.take(3).map((detailItem) {
                                          final detailSchema = _lookupSchema(
                                            controller.schemas,
                                            detailItem,
                                          );
                                          return SizedBox(
                                            width: 74,
                                            height: 44,
                                            child: GameItemImage(
                                              imageUrl:
                                                  detailItem.imageUrl ??
                                                  detailSchema?.imageUrl,
                                              appId: _resolveDetailAppId(
                                                detailItem,
                                                detailSchema,
                                              ),
                                              rarity: _schemaTag(
                                                detailSchema,
                                                'rarity',
                                              ),
                                              quality: _schemaTag(
                                                detailSchema,
                                                'quality',
                                              ),
                                              exterior: _schemaTag(
                                                detailSchema,
                                                'exterior',
                                              ),
                                              count: (detailItem.count ?? 1) > 1
                                                  ? detailItem.count
                                                  : null,
                                            ),
                                          );
                                        }),
                                        if (details.length > 3)
                                          Container(
                                            width: 74,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '+${details.length - 3}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'x${details.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Obx(
                                        () => Text(
                                          currency.format(price),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (showProtectionCountdown) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  _RecordProtectionCountdownText(
                                    endTimeSeconds: protectionTime,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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

class _InlineCountdownText extends StatefulWidget {
  const _InlineCountdownText({required this.endTimeMs, this.style});

  final int endTimeMs;
  final TextStyle? style;

  @override
  State<_InlineCountdownText> createState() => _InlineCountdownTextState();
}

class _InlineCountdownTextState extends State<_InlineCountdownText> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _InlineCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeMs != widget.endTimeMs) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final next = _format(widget.endTimeMs);
    if (!mounted) {
      return;
    }
    if (_text != next) {
      setState(() => _text = next);
    }
    if (next.isEmpty) {
      _timer?.cancel();
    }
  }

  String _format(int endTimeMs) {
    final remainMs = endTimeMs - DateTime.now().millisecondsSinceEpoch;
    if (remainMs <= 0) {
      return '';
    }
    final totalSeconds = remainMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(_text, style: widget.style);
  }
}

class _RecordProtectionCountdownText extends StatefulWidget {
  const _RecordProtectionCountdownText({
    required this.endTimeSeconds,
    this.style,
  });

  final int endTimeSeconds;
  final TextStyle? style;

  @override
  State<_RecordProtectionCountdownText> createState() =>
      _RecordProtectionCountdownTextState();
}

class _RecordProtectionCountdownTextState
    extends State<_RecordProtectionCountdownText> {
  Timer? _timer;
  String _remainText = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _RecordProtectionCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeSeconds != widget.endTimeSeconds) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final next = _formatRemainText(widget.endTimeSeconds);
    if (!mounted) {
      return;
    }
    if (_remainText != next) {
      setState(() => _remainText = next);
    }
    if (next.isEmpty) {
      _timer?.cancel();
    }
  }

  String _formatRemainText(int endTimeSeconds) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final totalTimeLeft = endTimeSeconds - nowSeconds;
    if (totalTimeLeft <= 0) {
      return '';
    }

    var days = totalTimeLeft ~/ (24 * 60 * 60);
    final hoursTotal = totalTimeLeft ~/ (60 * 60);
    final minutes = (totalTimeLeft % (60 * 60)) ~/ 60;
    var remainingHours = hoursTotal - days * 24 + (minutes > 0 ? 1 : 0);

    if (remainingHours % 24 == 0) {
      days += 1;
      remainingHours -= 24;
    }

    final localeTag = Get.locale?.toLanguageTag().toLowerCase() ?? '';
    final isCjkLocale =
        localeTag.startsWith('zh') ||
        localeTag.startsWith('ja') ||
        localeTag.startsWith('zh-hk');

    if (days > 0) {
      if (isCjkLocale) {
        return '$days${'app.common.day'.tr}$remainingHours${'app.common.hours'.tr}';
      }
      final dayKey = days > 1 ? 'app.common.days' : 'app.common.day';
      final hourKey = remainingHours > 1
          ? 'app.common.hours'
          : 'app.common.hour';
      return '$days${dayKey.tr}$remainingHours${hourKey.tr}';
    }

    if (remainingHours > 0) {
      if (isCjkLocale) {
        return '$remainingHours${'app.common.hours'.tr}';
      }
      final hourKey = remainingHours > 1
          ? 'app.common.hours'
          : 'app.common.hour';
      return '$remainingHours${hourKey.tr}';
    }

    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final minuteKey = isCjkLocale
        ? 'app.common.minutes'.tr
        : (minutes > 1 ? 'app.common.minutes'.tr : 'app.common.minute'.tr);
    return '$formattedMinutes$minuteKey';
  }

  @override
  Widget build(BuildContext context) {
    if (_remainText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(_remainText, style: widget.style);
  }
}
