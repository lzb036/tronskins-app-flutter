import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/tradeoffer.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/filter/order_filter_sheet.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/shop_sale_item_card.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/shop/shop_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_order_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_sales_controller.dart';
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

    if (userController.isLoggedIn.value) {
      salesController.refreshOnSale();
      orderController.refreshPending();
      salesController.refreshSellRecords();
    }

    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        salesController.refreshOnSale();
        orderController.refreshPending();
        salesController.refreshSellRecords();
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
    super.dispose();
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
    await salesController.delistItems(_selectedIds.toList());
    setState(_selectedIds.clear);
    Get.snackbar('app.system.tips.title'.tr, 'app.system.message.success'.tr);
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
    return DateFormat('MM-dd HH:mm').format(date);
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
    final result = await OrderFilterSheet.showFromRight(
      context: context,
      initial: OrderFilterResult(
        statusList: salesController.recordStatusList.toList(),
        startDate: salesController.recordStartDate.value,
        endDate: salesController.recordEndDate.value,
        sortField: salesController.recordSortField.value,
        sortAsc: salesController.recordSortAsc.value,
        tags: Map<String, dynamic>.from(salesController.recordTags),
        itemName: salesController.recordItemName.value,
      ),
      statusOptions: _statusOptions,
      showSort: false,
      showStatus: true,
      showDateRange: true,
      enableAttributeFilter: true,
      appId: GameStorage.getGameType(),
      attributeShowSort: false,
      attributeShowPriceRange: false,
      attributeSortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
    );
    if (result != null) {
      await salesController.applyRecordFilter(
        statusList: result.statusList,
        startDate: result.startDate,
        endDate: result.endDate,
        sortAsc: result.sortAsc,
        sortField: result.sortField,
        tags: result.tags,
        itemName: result.itemName,
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
    final selected = await _showShopTabSwitchMenu(
      iconContext: iconContext,
      currentFilter: currentFilter,
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
    final colors = Theme.of(context).colorScheme;
    final filter = _currentShopTabFilter();
    return Builder(
      builder: (iconContext) {
        return Tooltip(
          message: _shopTabLabelKey(filter).tr,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openShopTabSwitchMenu(iconContext),
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  _shopTabIcon(filter),
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: colors.primary, size: 16)
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
                          _buildTopIconAction(
                            icon: Icons.settings,
                            tooltip: 'app.user.shop.setting'.tr,
                            onTap: () => Get.toNamed(Routers.SHOP_SETTING),
                          ),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (iconContext) {
                              return GameIconButton(
                                appId: GameStorage.getGameType(),
                                size: 34,
                                onTap: () async {
                                  final selected = await showGameSwitchMenu(
                                    iconContext: iconContext,
                                    currentAppId: GameStorage.getGameType(),
                                  );
                                  if (selected == null) {
                                    return;
                                  }
                                  await GameStorage.setGameType(selected);
                                  salesController.refreshOnSale();
                                  orderController.refreshPending();
                                  salesController.refreshSellRecords();
                                  setState(() {});
                                },
                              );
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
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
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
                  final imageUrl = primary?.imageUrl ?? schema?.imageUrl ?? '';
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
                  final extraCount = record.details.length > 1
                      ? record.details.length - 1
                      : 0;
                  final appId = primary == null
                      ? GameStorage.getGameType()
                      : _resolveDetailAppId(primary, schema);
                  final rarity = _schemaTag(schema, 'rarity');
                  final quality = _schemaTag(schema, 'quality');
                  final phase = primary == null
                      ? null
                      : _detailText(primary, ['phase']);
                  final percentage = primary == null
                      ? null
                      : _detailText(primary, ['percentage']);
                  final count = primary?.count ?? 1;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
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
                                ),
                              ),
                              if (extraCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+$extraCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, maxLines: 2),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(record.createTime),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (wearValue != null && wearText != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${'app.market.csgo.abradability'.tr}: $wearText',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  WearProgressBar(paintWear: wearValue),
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
                              const SizedBox(height: 4),
                              Text(
                                record.statusName ?? '',
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
            const SizedBox(width: 8),
            Text(
              '${'app.inventory.count'.tr}: ${_selectedIds.length}/$selectableTotal',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () async {
                      final selectedItems = salesController.onSaleItems
                          .where((item) => _selectedIds.contains(item.id ?? -1))
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
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: _confirmDelist,
              child: Text('app.inventory.delist'.tr),
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
}

Future<_ShopTabFilter?> _showShopTabSwitchMenu({
  required BuildContext iconContext,
  required _ShopTabFilter currentFilter,
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
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final _ShopTabFilter currentFilter;

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
                  child: Align(
                    alignment: alignment,
                    child: _ShopTabSwitchPanel(currentFilter: currentFilter),
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
  const _ShopTabSwitchPanel({required this.currentFilter});

  final _ShopTabFilter currentFilter;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 168),
      child: Material(
        color: surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
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
  });

  final _ShopTabFilter filter;
  final IconData icon;
  final String labelKey;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFFFB800);
    return InkWell(
      onTap: () => Navigator.of(context).pop(filter),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            if (selected)
              const Icon(Icons.check, color: selectedColor, size: 18),
          ],
        ),
      ),
    );
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
