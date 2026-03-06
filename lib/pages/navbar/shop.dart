import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/tradeoffer.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/shop_sale_item_card.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_order_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_sales_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_shipping_notice_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

enum _ShopTabFilter { onSale, pending, saleRecord }

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  final ShopController shopController = Get.isRegistered<ShopController>()
      ? Get.find<ShopController>()
      : Get.put(ShopController());
  final ShopSalesController salesController =
      Get.isRegistered<ShopSalesController>()
      ? Get.find<ShopSalesController>()
      : Get.put(ShopSalesController());
  final ShopOrderController orderController =
      Get.isRegistered<ShopOrderController>()
      ? Get.find<ShopOrderController>()
      : Get.put(ShopOrderController());
  final ShopShippingNoticeController shippingNoticeController =
      Get.isRegistered<ShopShippingNoticeController>()
      ? Get.find<ShopShippingNoticeController>()
      : Get.put(ShopShippingNoticeController(), permanent: true);
  final UserController userController = Get.find<UserController>();

  late final TabController _tabController;
  int _activeTab = 0;
  final ScrollController _onSaleScroll = ScrollController();
  final ScrollController _pendingScroll = ScrollController();
  final ScrollController _recordScroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pendingSearchController =
      TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  Worker? _loginWorker;
  Worker? _shopTargetTabWorker;
  static const List<StatusOption> _statusOptions = [
    StatusOption(
      labelKey: 'app.market.filter.all',
      values: [-2, -1, 1, 3, 4, 5, 6, 9],
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
    _tabController = TabController(length: 3, vsync: this);
    _activeTab = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _onSaleScroll.addListener(_handleOnSaleScroll);
    _pendingScroll.addListener(_handlePendingScroll);
    _recordScroll.addListener(_handleRecordScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarketFilterSheet.preload(appId: GameStorage.getGameType());
    });
    final navController = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    _shopTargetTabWorker = ever<int?>(navController.pendingShopTabIndex, (
      targetTab,
    ) {
      if (targetTab == null) {
        return;
      }
      _switchToShopTab(targetTab);
      navController.clearPendingShopTab();
    });
    final initialTargetTab = navController.pendingShopTabIndex.value;
    if (initialTargetTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _switchToShopTab(initialTargetTab);
        navController.clearPendingShopTab();
      });
    }

    if (userController.isLoggedIn.value) {
      salesController.refreshOnSale();
      orderController.refreshPending();
      salesController.refreshSellRecords();
      shippingNoticeController.refreshPendingTotals();
    }

    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        salesController.refreshOnSale();
        orderController.refreshPending();
        salesController.refreshSellRecords();
        shippingNoticeController.refreshPendingTotals();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _onSaleScroll
      ..removeListener(_handleOnSaleScroll)
      ..dispose();
    _pendingScroll
      ..removeListener(_handlePendingScroll)
      ..dispose();
    _recordScroll
      ..removeListener(_handleRecordScroll)
      ..dispose();
    _searchController.dispose();
    _pendingSearchController.dispose();
    _recordSearchController.dispose();
    _loginWorker?.dispose();
    _shopTargetTabWorker?.dispose();
    super.dispose();
  }

  void _switchToShopTab(int targetTab) {
    final safeIndex = targetTab.clamp(0, _tabController.length - 1).toInt();
    if (_tabController.index == safeIndex) {
      return;
    }
    _tabController.animateTo(safeIndex);
  }

  void _handleTabChange() {
    if (_tabController.index == _activeTab) {
      return;
    }
    setState(() {
      _activeTab = _tabController.index;
      if (_activeTab != 0 && _selectedIds.isNotEmpty) {
        _selectedIds.clear();
      }
    });
  }

  void _handleOnSaleScroll() {
    if (_onSaleScroll.position.pixels >
        _onSaleScroll.position.maxScrollExtent - 200) {
      salesController.loadOnSale();
    }
  }

  void _handlePendingScroll() {
    if (_pendingScroll.position.pixels >
        _pendingScroll.position.maxScrollExtent - 200) {
      orderController.loadPendingShipments();
    }
  }

  void _handleRecordScroll() {
    if (_recordScroll.position.pixels >
        _recordScroll.position.maxScrollExtent - 200) {
      salesController.loadSellRecords();
    }
  }

  void _toggleSelection(ShopItemAsset item) {
    final id = item.id;
    if (id == null) {
      return;
    }
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    final ids = salesController.onSaleItems
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    setState(() {
      if (_selectedIds.length == ids.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _confirmDelist() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.inventory.message.confirm_delist'.tr),
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
      final res = await salesController.delistItems(_selectedIds.toList());
      if (res.success) {
        setState(_selectedIds.clear);
        AppSnackbar.success('app.system.message.success'.tr);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    }
  }

  ShopSchemaInfo? _lookupSchema(
    Map<String, ShopSchemaInfo> schemas,
    String? marketHashName,
    int? schemaId,
  ) {
    if (marketHashName != null && schemas.containsKey(marketHashName)) {
      return schemas[marketHashName];
    }
    final key = schemaId?.toString();
    if (key != null && schemas.containsKey(key)) {
      return schemas[key];
    }
    return null;
  }

  TagInfo? _schemaTag(ShopSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  int _resolveDetailAppId(ShopOrderDetail detail, ShopSchemaInfo? schema) {
    final raw = detail.raw;
    final schemaRaw = schema?.raw;
    final rawApp = raw['app_id'] ?? raw['appId'];
    final schemaApp = schemaRaw?['app_id'] ?? schemaRaw?['appId'];
    return _asInt(rawApp) ?? _asInt(schemaApp) ?? GameStorage.getGameType();
  }

  String? _detailText(ShopOrderDetail detail, List<String> keys) {
    final raw = detail.raw;
    for (final key in keys) {
      final value = raw[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  double? _detailDouble(ShopOrderDetail detail, List<String> keys) {
    final raw = detail.raw;
    for (final key in keys) {
      final value = raw[key];
      if (value == null) {
        continue;
      }
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
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

  int _sumOrderCount(ShopOrderItem order) {
    if (order.nums != null) {
      return order.nums!;
    }
    int total = 0;
    for (final detail in order.details) {
      total += detail.count ?? 1;
    }
    return total;
  }

  String _resolveDetailTitle(
    ShopOrderDetail detail,
    Map<String, ShopSchemaInfo> schemas,
  ) {
    final schema = _lookupSchema(
      schemas,
      detail.marketHashName,
      detail.schemaId,
    );
    return detail.marketName ?? schema?.marketName ?? '-';
  }

  List<String> _buildMultiDetailTitleLines({
    required List<ShopOrderDetail> details,
    required Map<String, ShopSchemaInfo> schemas,
    int maxVisibleNames = 3,
  }) {
    if (details.isEmpty) {
      return const ['-'];
    }
    final names = details
        .map((detail) => _resolveDetailTitle(detail, schemas))
        .toList(growable: false);
    final visible = names.take(maxVisibleNames).toList(growable: false);
    final hasOverflow = names.length > maxVisibleNames;
    final lines = <String>[];
    for (var i = 0; i < visible.length; i++) {
      final name = visible[i];
      final isLastVisible = i == visible.length - 1;
      final suffix = hasOverflow && isLastVisible ? '...' : '';
      lines.add('. $name$suffix');
    }
    return lines;
  }

  Widget _buildSellRecordDetailImage({
    required ShopOrderDetail detail,
    required Map<String, ShopSchemaInfo> schemas,
  }) {
    final schema = _lookupSchema(
      schemas,
      detail.marketHashName,
      detail.schemaId,
    );
    final appId = _resolveDetailAppId(detail, schema);
    final imageUrl = detail.imageUrl ?? schema?.imageUrl ?? '';
    final rarity = _schemaTag(schema, 'rarity');
    final quality = _schemaTag(schema, 'quality');
    final phase = _detailText(detail, ['phase']);
    final percentage = _detailText(detail, ['percentage']);
    final rawAsset = detail.raw['asset'];
    final rawCsgoAsset = detail.raw['csgoAsset'];
    final stickerRaw =
        detail.raw['stickers'] ??
        (rawAsset is Map ? rawAsset['stickers'] : null) ??
        (rawCsgoAsset is Map ? rawCsgoAsset['stickers'] : null);
    final stickers = parseStickerList(
      stickerRaw,
      schemaMap: schemas,
      stickerMap: salesController.stickers,
    );
    final count = detail.count ?? 1;
    return SizedBox(
      width: 72,
      height: 43,
      child: GameItemImage(
        imageUrl: imageUrl,
        appId: appId,
        rarity: rarity,
        quality: quality,
        phase: phase,
        percentage: percentage,
        count: count > 1 ? count : null,
        stickers: stickers,
      ),
    );
  }

  Widget _buildSellRecordDetailOverflowHint(int hiddenCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 43,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text('+$hiddenCount', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  String _buildRecordStatusText(ShopOrderItem record) {
    final status = record.status;
    if (status == 6) {
      return 'app.trade.sale.success'.tr;
    }
    final statusName = record.statusName?.trim();
    if ([2, 3, 4].contains(status)) {
      return (statusName == null || statusName.isEmpty) ? '-' : statusName;
    }
    final cancelDesc = record.cancelDesc?.trim();
    if (![2, 3, 4, 5, 6].contains(status) &&
        cancelDesc != null &&
        cancelDesc.isNotEmpty) {
      return cancelDesc;
    }
    if (statusName != null && statusName.isNotEmpty) {
      return statusName;
    }
    return '-';
  }

  ({Color bg, Color fg}) _recordStatusPalette(int? status) {
    if ([5, 6].contains(status)) {
      return (bg: const Color(0xFFE8F5E9), fg: const Color(0xFF008000));
    }
    if ([2, 3, 4].contains(status)) {
      return (bg: const Color(0xFFFDECEC), fg: const Color(0xFFC22121));
    }
    return (bg: const Color(0xFFF5F5F5), fg: const Color(0xFF888888));
  }

  Widget _buildRecordStatusBadge(
    ShopOrderItem record, {
    double maxWidth = 160,
  }) {
    final palette = _recordStatusPalette(record.status);
    final statusText = _buildRecordStatusText(record);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          statusText,
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

  Widget _buildRecordInfoChip({required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _showRecordCountdown(ShopOrderItem record) {
    final protectionTime = record.protectionTime;
    return protectionTime != null && protectionTime > 0 && record.status == 5;
  }

  Future<void> _openOnSaleFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.price', field: 'price'),
        SortOption(labelKey: 'app.market.filter.hot', field: 'hot'),
      ],
      initial: MarketFilterResult(
        sortField: salesController.onSaleSortField.value,
        sortAsc: salesController.onSaleSortAsc.value,
        priceMin: salesController.onSalePriceMin.value,
        priceMax: salesController.onSalePriceMax.value,
        tags: Map<String, dynamic>.from(salesController.onSaleTags),
        itemName: salesController.onSaleItemName.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _searchController.clear();
      }
      await salesController.applyOnSaleFilter(
        sortField: result.sortField,
        sortAsc: result.sortAsc,
        minPrice: result.priceMin,
        maxPrice: result.priceMax,
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  Future<void> _openPendingFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      showSort: false,
      showPriceRange: false,
      initial: MarketFilterResult(
        sortField: orderController.pendingSortField.value,
        sortAsc: orderController.pendingSortAsc.value,
        tags: Map<String, dynamic>.from(orderController.pendingTags),
        itemName: orderController.pendingItemName.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _pendingSearchController.clear();
      }
      await orderController.applyPendingFilter(
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  Future<void> _openSellRecordFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      showSort: false,
      showPriceRange: false,
      showStatus: true,
      showDateRange: true,
      statusOptions: _statusOptions,
      initial: MarketFilterResult(
        sortField: salesController.recordSortField.value,
        sortAsc: salesController.recordSortAsc.value,
        tags: Map<String, dynamic>.from(salesController.recordTags),
        itemName: salesController.recordItemName.value,
        statusList: salesController.recordStatusList.toList(),
        startDate: salesController.recordStartDate.value,
        endDate: salesController.recordEndDate.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _recordSearchController.clear();
      }
      await salesController.applyRecordFilter(
        statusList: result.statusList,
        startDate: result.startDate,
        endDate: result.endDate,
        sortAsc: result.sortAsc,
        sortField: result.sortField,
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  _ShopTabFilter _currentShopTabFilter() {
    switch (_activeTab) {
      case 1:
        return _ShopTabFilter.pending;
      case 2:
        return _ShopTabFilter.saleRecord;
      case 0:
      default:
        return _ShopTabFilter.onSale;
    }
  }

  String _shopTabLabelKey(_ShopTabFilter filter) {
    switch (filter) {
      case _ShopTabFilter.onSale:
        return 'app.trade.onSale.text';
      case _ShopTabFilter.pending:
        return 'app.market.product.wait_for_sending';
      case _ShopTabFilter.saleRecord:
        return 'app.user.menu.sale';
    }
  }

  IconData _shopTabIcon(_ShopTabFilter filter) {
    switch (filter) {
      case _ShopTabFilter.onSale:
        return Icons.storefront_outlined;
      case _ShopTabFilter.pending:
        return Icons.local_shipping_outlined;
      case _ShopTabFilter.saleRecord:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _openShopTabSwitchMenu(BuildContext iconContext) async {
    final currentFilter = _currentShopTabFilter();
    final currentAppId = GameStorage.getGameType();
    final pendingTotal = shippingNoticeController.pendingCount(currentAppId);
    final selected = await _showShopTabSwitchMenu(
      iconContext: iconContext,
      currentFilter: currentFilter,
      pendingTotal: pendingTotal,
    );
    if (selected == null || selected == currentFilter) {
      return;
    }

    final targetIndex = switch (selected) {
      _ShopTabFilter.onSale => 0,
      _ShopTabFilter.pending => 1,
      _ShopTabFilter.saleRecord => 2,
    };
    if (targetIndex != _tabController.index) {
      _tabController.animateTo(targetIndex);
    }
  }

  Widget _buildShopTabSwitcher() {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final filter = _currentShopTabFilter();
    final label = _shopTabLabelKey(filter).tr;
    return Builder(
      builder: (iconContext) {
        return Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openShopTabSwitchMenu(iconContext),
              child: Obx(() {
                final currentAppId = GameStorage.getGameType();
                final hasPendingInCurrentGame =
                    shippingNoticeController.pendingCount(currentAppId) > 0;
                final content = SizedBox(
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _shopTabIcon(filter),
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 72),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return _buildTopActionWithDot(
                  visible: hasPendingInCurrentGame,
                  dotColor: Colors.orange.shade600,
                  child: content,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopIconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionWithDot({
    required Widget child,
    required Color dotColor,
    required bool visible,
  }) {
    if (!visible) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopSummaryBar(CurrencyController currency) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseStart = isDark ? colors.surfaceContainerHigh : Colors.white;
    final baseEnd = isDark
        ? colors.surfaceContainer
        : colors.primary.withValues(alpha: 0.05);
    final borderColor = colors.outline.withValues(alpha: 0.18);

    return Obx(() {
      final count = salesController.totalOnSale.value;
      final totalValue = salesController.totalOnSalePrice.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseStart, baseEnd],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildShopSummaryMetric(
                label: 'app.inventory.count'.tr,
                value: '$count',
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            Expanded(
              child: _buildShopSummaryMetric(
                label: 'app.inventory.total_value'.tr,
                value: currency.format(totalValue),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShopSummaryMetric({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnSaleSelectAllToggle({
    required bool selected,
    required bool enabled,
  }) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = colors.outline.withValues(alpha: 0.45);
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Tooltip(
        message: selected
            ? 'app.common.deselect_all'.tr
            : 'app.common.select_all'.tr,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? _toggleSelectAll : null,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: borderColor),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: colors.primary, size: 14)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Obx(() {
        if (!userController.isLoggedIn.value) {
          return _buildLoginPrompt();
        }
        final isShopOnline = shopController.shop.value?.isOnline ?? false;
        return SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outline.withValues(alpha: 0.08),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'app.user.menu.shop'.tr,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildShopTabSwitcher(),
                          const SizedBox(width: 6),
                          _buildTopActionWithDot(
                            visible: true,
                            dotColor: isShopOnline
                                ? const Color(0xFF22C55E)
                                : colors.outlineVariant,
                            child: _buildTopIconAction(
                              icon: Icons.settings,
                              tooltip: 'app.user.shop.setting'.tr,
                              onTap: () => Get.toNamed(Routers.SHOP_SETTING),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (iconContext) {
                              return Obx(() {
                                final currentAppId = GameStorage.getGameType();
                                final hasPendingInAnyGame =
                                    shippingNoticeController.hasAnyPending;
                                return _buildTopActionWithDot(
                                  visible: hasPendingInAnyGame,
                                  dotColor: Colors.orange.shade600,
                                  child: GameIconButton(
                                    appId: currentAppId,
                                    size: 34,
                                    onTap: () async {
                                      final selected = await showGameSwitchMenu(
                                        iconContext: iconContext,
                                        currentAppId: currentAppId,
                                        pendingTotalsByAppId:
                                            shippingNoticeController
                                                .snapshotTotals(),
                                      );
                                      if (selected == null) {
                                        return;
                                      }
                                      await GameStorage.setGameType(selected);
                                      salesController.refreshOnSale();
                                      orderController.refreshPending();
                                      salesController.refreshSellRecords();
                                      shippingNoticeController
                                          .refreshPendingTotals();
                                      setState(() {});
                                    },
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildSharedTabSearchBar(),
                    const SizedBox(height: 6),
                    if (_activeTab == 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildShopSummaryBar(currency),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              _buildShopStatusBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOnSaleTab(),
                    _buildPendingShipmentTab(currency),
                    _buildSellRecordTab(currency),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: _activeTab == 0 && _selectedIds.isNotEmpty
          ? _buildOnSaleActions()
          : null,
    );
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
            child: Text('app.user.login.nologin'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusBanner() {
    return Obx(() {
      final shop = shopController.shop.value;
      if (shop == null || shop.isOnline == true) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'app.user.shop.message.offline'.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(Routers.SHOP_SETTING),
                  child: Text('app.user.shop.setting'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabSearchBar({
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onSearch,
    required IconData filterIcon,
    required VoidCallback onFilter,
    String filterTooltipKey = 'app.market.filter.text',
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceVariant;
    final hintColor = isDark
        ? Colors.white38
        : colors.onSurface.withValues(alpha: 0.4);
    final hasKeyword = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  onChanged: (_) {
                    if (mounted) {
                      setState(() {});
                    }
                  },
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
                              if (mounted) {
                                setState(() {});
                              }
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
            tooltip: filterTooltipKey.tr,
            icon: filterIcon,
            onTap: onFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceVariant;
    final iconColor = colors.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: baseColor,
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

  Widget _buildListFooter({
    required bool showLoading,
    required bool showNoMore,
  }) {
    if (showLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (showNoMore) {
      return const ListEndTip();
    }
    return const SizedBox.shrink();
  }

  Widget _buildSharedTabSearchBar() {
    switch (_activeTab) {
      case 0:
        return _buildTabSearchBar(
          controller: _searchController,
          onSubmitted: salesController.searchOnSale,
          onSearch: () => salesController.searchOnSale(_searchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openOnSaleFilterSheet,
        );
      case 1:
        return _buildTabSearchBar(
          controller: _pendingSearchController,
          onSubmitted: orderController.searchPending,
          onSearch: () =>
              orderController.searchPending(_pendingSearchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openPendingFilterSheet,
        );
      case 2:
        return _buildTabSearchBar(
          controller: _recordSearchController,
          onSubmitted: salesController.searchSellRecords,
          onSearch: () =>
              salesController.searchSellRecords(_recordSearchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openSellRecordFilterSheet,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOnSaleTab() {
    return Obx(() {
      if (salesController.onSaleItems.isEmpty &&
          salesController.isLoadingOnSale.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (salesController.onSaleItems.isEmpty) {
        return Center(child: Text('app.common.no_data'.tr));
      }
      final showLoadingFooter =
          salesController.isLoadingOnSale.value &&
          salesController.onSaleItems.isNotEmpty;
      final showNoMoreFooter =
          salesController.onSaleItems.isNotEmpty &&
          !salesController.isLoadingOnSale.value &&
          !salesController.onSaleHasMore;
      return RefreshIndicator(
        onRefresh: salesController.refreshOnSale,
        child: CustomScrollView(
          controller: _onSaleScroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: salesController.onSaleItems.length,
                itemBuilder: (context, index) {
                  final item = salesController.onSaleItems[index];
                  final schema = _lookupSchema(
                    salesController.schemas,
                    item.marketHashName,
                    item.schemaId,
                  );
                  final selected = _selectedIds.contains(item.id ?? -1);
                  return ShopSaleItemCard(
                    item: item,
                    schema: schema,
                    schemaMap: salesController.schemas,
                    stickerMap: salesController.stickers,
                    selected: selected,
                    onTap: () => _toggleSelection(item),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _buildListFooter(
                showLoading: showLoadingFooter,
                showNoMore: showNoMoreFooter,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPendingShipmentTab(CurrencyController currency) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (orderController.pendingShipments.isEmpty &&
                orderController.isLoadingPending.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (orderController.pendingShipments.isEmpty) {
              return Center(child: Text('app.common.no_data'.tr));
            }
            final pendingShipments = orderController.pendingShipments;
            final showLoadingFooter =
                orderController.isLoadingPending.value &&
                pendingShipments.isNotEmpty;
            final showNoMoreFooter =
                pendingShipments.isNotEmpty &&
                !orderController.isLoadingPending.value &&
                !orderController.pendingHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return RefreshIndicator(
              onRefresh: orderController.refreshPending,
              child: ListView.separated(
                controller: _pendingScroll,
                padding: const EdgeInsets.all(12),
                itemCount: pendingShipments.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= pendingShipments.length) {
                    return _buildListFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final order = pendingShipments[index];
                  final totalPrice = _sumOrderPrice(order);
                  final totalCount = _sumOrderCount(order);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${'app.trade.order.number'.tr}: '
                                  '${order.id ?? '-'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                order.statusName ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (order.details.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('app.common.no_data'.tr),
                            )
                          else
                            ...order.details.map((detail) {
                              final schema = _lookupSchema(
                                orderController.schemas,
                                detail.marketHashName,
                                detail.schemaId,
                              );
                              final appId = _resolveDetailAppId(detail, schema);
                              final imageUrl =
                                  detail.imageUrl ?? schema?.imageUrl ?? '';
                              final title =
                                  detail.marketName ??
                                  schema?.marketName ??
                                  detail.marketHashName ??
                                  '-';
                              final count = detail.count ?? 1;
                              final rarity = _schemaTag(schema, 'rarity');
                              final quality = _schemaTag(schema, 'quality');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 72,
                                      height: 43,
                                      child: GameItemImage(
                                        imageUrl: imageUrl,
                                        appId: appId,
                                        rarity: rarity,
                                        quality: quality,
                                        count: count > 1 ? count : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (count > 1)
                                      Text(
                                        'x$count',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          Row(
                            children: [
                              Text(
                                '${'app.inventory.count'.tr}: $totalCount',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Obx(
                                () => Text(
                                  currency.format(totalPrice),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if ((order.user?.nickname ?? '').isNotEmpty)
                                Expanded(
                                  child: Text(
                                    order.user?.nickname ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              if (order.status == 2)
                                FilledButton(
                                  onPressed: () => _openDeliverSheet(order),
                                  child: Text('app.market.product.deliver'.tr),
                                )
                              else
                                Text(
                                  'app.trade.deliver.message.go_steam'.tr,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
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

  Widget _buildSellRecordTab(CurrencyController currency) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (salesController.sellRecords.isEmpty &&
                salesController.isLoadingRecords.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (salesController.sellRecords.isEmpty) {
              return Center(child: Text('app.common.no_data'.tr));
            }
            final sellRecords = salesController.sellRecords;
            final showLoadingFooter =
                salesController.isLoadingRecords.value &&
                sellRecords.isNotEmpty;
            final showNoMoreFooter =
                sellRecords.isNotEmpty &&
                !salesController.isLoadingRecords.value &&
                !salesController.recordHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return RefreshIndicator(
              onRefresh: salesController.refreshSellRecords,
              child: ListView.separated(
                controller: _recordScroll,
                padding: const EdgeInsets.all(12),
                itemCount: sellRecords.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= sellRecords.length) {
                    return _buildListFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final record = sellRecords[index];
                  final primary = record.details.isNotEmpty
                      ? record.details.first
                      : null;
                  final schema = primary == null
                      ? null
                      : _lookupSchema(
                          salesController.schemas,
                          primary.marketHashName,
                          primary.schemaId,
                        );
                  final title =
                      primary?.marketName ?? schema?.marketName ?? '-';
                  final totalPrice = _sumOrderPrice(record);
                  final wearValue =
                      primary?.paintWear ??
                      (primary == null
                          ? null
                          : _detailDouble(primary, [
                              'paint_wear',
                              'paintWear',
                            ]));
                  final wearText = primary == null
                      ? null
                      : _detailText(primary, ['paint_wear', 'paintWear']) ??
                            wearValue?.toString();
                  final hasMultipleDetails = record.details.length > 1;
                  final showCountdown = _showRecordCountdown(record);
                  const maxVisibleDetails = 3;
                  final visibleDetailItems = record.details
                      .take(maxVisibleDetails)
                      .toList(growable: false);
                  final hiddenDetailCount =
                      record.details.length - visibleDetailItems.length;
                  final colorScheme = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;
                  final statusText = _buildRecordStatusText(record);
                  final statusColor = [5, 6].contains(record.status)
                      ? const Color(0xFF008000)
                      : [2, 3, 4].contains(record.status)
                      ? const Color(0xFFC22121)
                      : colorScheme.onSurfaceVariant;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openSellRecordDetail(record),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatTime(record.createTime),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!hasMultipleDetails)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (primary != null)
                                    _buildSellRecordDetailImage(
                                      detail: primary,
                                      schemas: salesController.schemas,
                                    )
                                  else
                                    Container(
                                      width: 72,
                                      height: 43,
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 18,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              if (wearValue != null &&
                                                  wearText != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${'app.market.csgo.abradability'.tr}: $wearText',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                WearProgressBar(
                                                  paintWear: wearValue,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (showCountdown) ...[
                                              _RecordProtectionCountdownText(
                                                endTimeSeconds:
                                                    record.protectionTime!,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors
                                                          .orange
                                                          .shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Obx(
                                              () => Text(
                                                currency.format(totalPrice),
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ...visibleDetailItems.map(
                                          (detail) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: _buildSellRecordDetailImage(
                                              detail: detail,
                                              schemas: salesController.schemas,
                                            ),
                                          ),
                                        ),
                                        if (hiddenDetailCount > 0)
                                          Text(
                                            '+$hiddenDetailCount',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showCountdown) ...[
                                        _RecordProtectionCountdownText(
                                          endTimeSeconds:
                                              record.protectionTime!,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.orange.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Obx(
                                        () => Text(
                                          currency.format(totalPrice),
                                          style: textTheme.titleSmall?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildOnSaleActions() {
    final selectableIds = salesController.onSaleItems
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    final selectableTotal = selectableIds.length;
    final allSelected =
        selectableTotal > 0 && selectableIds.every(_selectedIds.contains);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildOnSaleSelectAllToggle(
              selected: allSelected,
              enabled: selectableTotal > 0,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 64,
              child: Text(
                '${_selectedIds.length}/$selectableTotal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 42,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _selectedIds.clear());
                          },
                          child: Text('app.common.cancel'.tr),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _selectedIds.isEmpty
                              ? null
                              : () async {
                                  final selectedItems = salesController
                                      .onSaleItems
                                      .where(
                                        (item) => _selectedIds.contains(
                                          item.id ?? -1,
                                        ),
                                      )
                                      .toList();
                                  if (selectedItems.isEmpty) {
                                    return;
                                  }
                                  await Get.toNamed(
                                    Routers.SHOP_PRICE_CHANGE,
                                    arguments: {
                                      'items': selectedItems,
                                      'schemas': salesController.schemas,
                                      'appId': GameStorage.getGameType(),
                                    },
                                  );
                                  await salesController.refreshOnSale();
                                  setState(_selectedIds.clear);
                                },
                          child: Text('app.inventory.price_change'.tr),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _confirmDelist,
                          child: Text('app.inventory.delist'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeliverSheet(ShopOrderItem order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _DeliverSheet(
          order: order,
          schemas: orderController.schemas,
          onDelivered: () => orderController.refreshPending(),
        );
      },
    );
  }

  Future<void> _openSellRecordDetail(ShopOrderItem record) async {
    await Get.toNamed(
      Routers.SHOP_ORDER_DETAIL,
      arguments: {
        'order': record,
        'schemas': Map<String, ShopSchemaInfo>.from(salesController.schemas),
        'users': Map<String, ShopUserInfo>.from(salesController.users),
        'stickers': Map<String, dynamic>.from(salesController.stickers),
      },
    );
  }
}

Future<_ShopTabFilter?> _showShopTabSwitchMenu({
  required BuildContext iconContext,
  required _ShopTabFilter currentFilter,
  required int pendingTotal,
}) {
  final overlay =
      Overlay.of(iconContext).context.findRenderObject() as RenderBox;
  final box = iconContext.findRenderObject() as RenderBox;
  final iconRect = box.localToGlobal(Offset.zero) & box.size;
  final screenSize = overlay.size;
  final alignX = ((iconRect.center.dx / screenSize.width) * 2 - 1).clamp(
    -1.0,
    1.0,
  );
  final alignment = Alignment(alignX.toDouble(), -1);
  final panelTop = (iconRect.bottom + 8)
      .clamp(0.0, screenSize.height)
      .toDouble();

  return showGeneralDialog<_ShopTabFilter>(
    context: iconContext,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(
      iconContext,
    ).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, __, ___) {
      return _ShopTabSwitchOverlay(
        animation: animation,
        alignment: alignment,
        top: panelTop,
        currentFilter: currentFilter,
        pendingTotal: pendingTotal,
      );
    },
  );
}

class _ShopTabSwitchOverlay extends StatelessWidget {
  const _ShopTabSwitchOverlay({
    required this.animation,
    required this.alignment,
    required this.top,
    required this.currentFilter,
    required this.pendingTotal,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final _ShopTabFilter currentFilter;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                alignment: alignment,
                scale: Tween<double>(begin: 0.2, end: 1).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: _ShopTabSwitchPanel(
                    currentFilter: currentFilter,
                    pendingTotal: pendingTotal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTabSwitchPanel extends StatelessWidget {
  const _ShopTabSwitchPanel({
    required this.currentFilter,
    required this.pendingTotal,
  });

  final _ShopTabFilter currentFilter;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor;
    return Material(
      color: surface,
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.onSale,
            icon: Icons.storefront_outlined,
            labelKey: 'app.trade.onSale.text',
            selected: currentFilter == _ShopTabFilter.onSale,
          ),
          Divider(height: 1, color: divider),
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.pending,
            icon: Icons.local_shipping_outlined,
            labelKey: 'app.market.product.wait_for_sending',
            selected: currentFilter == _ShopTabFilter.pending,
            pendingTotal: pendingTotal,
          ),
          Divider(height: 1, color: divider),
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.saleRecord,
            icon: Icons.receipt_long_outlined,
            labelKey: 'app.user.menu.sale',
            selected: currentFilter == _ShopTabFilter.saleRecord,
          ),
        ],
      ),
    );
  }
}

class _ShopTabSwitchOption extends StatelessWidget {
  const _ShopTabSwitchOption({
    required this.filter,
    required this.icon,
    required this.labelKey,
    required this.selected,
    this.pendingTotal = 0,
  });

  final _ShopTabFilter filter;
  final IconData icon;
  final String labelKey;
  final bool selected;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFFFB800);
    const pendingColor = Color(0xFFFF9800);
    final hasPendingHint = filter == _ShopTabFilter.pending && pendingTotal > 0;
    final dividerColor = Theme.of(context).dividerColor;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).pop(filter),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? selectedColor : null),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                labelKey.tr,
                style: TextStyle(
                  color: selected ? selectedColor : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (hasPendingHint)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: pendingColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: Text(
                        'app.system.tips.pending'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pendingColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pendingTotal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (selected)
              const Icon(Icons.check, color: selectedColor, size: 18),
          ],
        ),
      ),
    );
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
    final formattedMinutes = minutes.toString().padLeft(2, '0');
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
        return '$remainingHours${'app.common.hours'.tr}$formattedMinutes${'app.common.minutes'.tr}';
      }
      final hourKey = remainingHours > 1
          ? 'app.common.hours'
          : 'app.common.hour';
      final minuteKey = minutes > 1
          ? 'app.common.minutes'
          : 'app.common.minute';
      return '$remainingHours${hourKey.tr}$formattedMinutes${minuteKey.tr}';
    }

    if (minutes > 0) {
      if (isCjkLocale) {
        return '$formattedMinutes${'app.common.minutes'.tr}';
      }
      final minuteKey = minutes > 1
          ? 'app.common.minutes'
          : 'app.common.minute';
      return '$formattedMinutes ${minuteKey.tr}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_remainText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(_remainText, style: widget.style);
  }
}

class _DeliverSheet extends StatefulWidget {
  const _DeliverSheet({
    required this.order,
    required this.schemas,
    required this.onDelivered,
  });

  final ShopOrderItem order;
  final Map<String, ShopSchemaInfo> schemas;
  final VoidCallback onDelivered;

  @override
  State<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends State<_DeliverSheet> {
  bool _isSubmitting = false;

  ShopSchemaInfo? _lookupSchema(ShopOrderDetail detail) {
    final hash = detail.marketHashName;
    if (hash != null && widget.schemas.containsKey(hash)) {
      return widget.schemas[hash];
    }
    final schemaId = detail.schemaId?.toString();
    if (schemaId != null && widget.schemas.containsKey(schemaId)) {
      return widget.schemas[schemaId];
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (widget.order.id == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final steamStatus = await ApiSteamServer().steamOnlineState();
      if (steamStatus.datas != true) {
        await Get.dialog<void>(
          AlertDialog(
            title: Text('app.system.tips.title'.tr),
            content: Text('app.steam.session.expired'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('app.common.cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routers.STEAM_SESSION);
                },
                child: Text('app.common.confirm'.tr),
              ),
            ],
          ),
        );
        return;
      }

      final res = await ApiTradeOfferServer().createTradeOffer(
        params: {'id': widget.order.id},
      );
      if (res.success) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.trade.deliver.message.steam_trade_url_success'.tr,
        );
        widget.onDelivered();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.trade.order.details'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if ((order.user?.nickname ?? '').isNotEmpty)
              Text(order.user?.nickname ?? ''),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: order.details.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final detail = order.details[index];
                  final schema = _lookupSchema(detail);
                  final imageUrl = detail.imageUrl ?? schema?.imageUrl ?? '';
                  final title = detail.marketName ?? schema?.marketName ?? '-';
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => const SizedBox(
                            width: 48,
                            height: 48,
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
                        '${'app.inventory.count'.tr}: ${detail.count ?? 1}',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: order.status == 2 && !_isSubmitting ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        order.status == 2
                            ? 'app.market.product.deliver'.tr
                            : 'app.trade.deliver.message.go_steam'.tr,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
