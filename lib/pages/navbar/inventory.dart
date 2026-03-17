import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/inventory_item_card.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/controllers/inventory/inventory_controller.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

enum _InventoryStateFilter { all, sellable, cooling }

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryController controller = Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());
  final UserController userController = Get.find<UserController>();
  final ApiSteamServer _steamApi = ApiSteamServer();
  late final PageController _inventoryStatePageController;
  final TextEditingController _searchController = TextEditingController();
  Worker? _loginWorker;
  Worker? _tabWorker;
  bool _steamSessionDialogShowing = false;

  String _steamIdFromProfile() {
    final steamId = userController.user.value?.config?.steamId;
    if (steamId == null) {
      return '';
    }
    return steamId.trim();
  }

  Future<bool> _hasBoundSteam() async {
    if (_steamIdFromProfile().isNotEmpty) {
      return true;
    }
    await userController.fetchUserData(showLoading: false);
    return _steamIdFromProfile().isNotEmpty;
  }

  Future<void> _refreshInventoryAndPreloadIfNeeded() async {
    await controller.refreshIfStale();
    await controller.preloadStateBucketsIfNeeded();
  }

  Future<void> _toSteamBind() async {
    try {
      final tokenRes = await _steamApi.getTemporaryToken();
      final token = tokenRes.datas;
      if (!tokenRes.success || token == null || token.isEmpty) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.login.message.error'.tr,

          titleText: const SizedBox.shrink(),
        );
        return;
      }
      if (!Get.isRegistered<SteamController>()) {
        Get.put(SteamController());
      }
      Get.toNamed(Routers.STEAM_BIND, arguments: token);
    } catch (_) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.login.message.error'.tr,

        titleText: const SizedBox.shrink(),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _inventoryStatePageController = PageController(
      initialPage: _inventoryFilterToPage(_currentInventoryStateFilter()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarketFilterSheet.preload(appId: controller.currentAppId.value);
    });
    if (userController.isLoggedIn.value) {
      Future.microtask(_refreshInventoryAndPreloadIfNeeded);
      Future.microtask(_checkSteamSessionIfNeeded);
    }
    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        Future.microtask(_refreshInventoryAndPreloadIfNeeded);
        Future.microtask(_checkSteamSessionIfNeeded);
      } else {
        controller.items.clear();
        controller.schemas.clear();
        controller.total.value = 0;
        controller.totalPrice.value = 0;
        controller.clearSelection();
      }
    });

    if (Get.isRegistered<NavController>()) {
      final navController = Get.find<NavController>();
      _tabWorker = ever<int>(navController.currentIndex, (index) {
        if (index == 2 && userController.isLoggedIn.value) {
          Future.microtask(_refreshInventoryAndPreloadIfNeeded);
          Future.microtask(_checkSteamSessionIfNeeded);
        }
      });
    }
  }

  Future<bool> _checkSteamSessionIfNeeded() async {
    if (!mounted ||
        !userController.isLoggedIn.value ||
        _steamSessionDialogShowing) {
      return true;
    }

    try {
      final hasBoundSteam = await _hasBoundSteam();
      if (!mounted || !userController.isLoggedIn.value) {
        return true;
      }
      if (!hasBoundSteam) {
        _steamSessionDialogShowing = true;
        await Get.dialog<void>(
          AlertDialog(
            title: Text('app.system.tips.title'.tr),
            content: Text('app.steam.message.unbind'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('app.common.cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  _toSteamBind();
                },
                child: Text('app.common.confirm'.tr),
              ),
            ],
          ),
        );
        return false;
      }

      final sessionState = await _steamApi.steamOnlineState();
      if (!mounted || !userController.isLoggedIn.value) {
        return true;
      }
      if (sessionState.datas == true) {
        return true;
      }

      _steamSessionDialogShowing = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _InventorySteamSessionExpiredDialog(
          onCancel: () => Navigator.of(dialogContext).pop(),
          onVerify: () {
            Navigator.of(dialogContext).pop();
            Get.toNamed(Routers.STEAM_SESSION);
          },
        ),
      );
      return false;
    } catch (_) {
      // ignore network errors for passive session check
      return true;
    } finally {
      _steamSessionDialogShowing = false;
    }
  }

  @override
  void dispose() {
    _inventoryStatePageController.dispose();
    _searchController.dispose();
    _loginWorker?.dispose();
    _tabWorker?.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final canContinue = await _checkSteamSessionIfNeeded();
    if (!canContinue) {
      return;
    }
    await controller.refreshByPullDown();
  }

  void _search() {
    controller.search(_searchController.text);
  }

  bool _isItemSelectable(InventoryItem item) {
    final isTradable = item.tradable ?? true;
    final isCooling = item.coolingDown ?? false;
    final isOnSale = item.status == 1;
    final isInSupply = item.status == 2;
    return isTradable && !isCooling && !isOnSale && !isInSupply;
  }

  Future<void> _openSelectedItemsUpshop() async {
    if (controller.selectedIds.isEmpty) {
      return;
    }
    final selectedItems = controller.items
        .where((item) => controller.selectedIds.contains(item.id ?? -1))
        .toList();
    if (selectedItems.isEmpty) {
      return;
    }
    await Get.toNamed(
      Routers.INVENTORY_UPSHOP,
      arguments: {
        'items': selectedItems,
        'schemas': controller.schemas,
        'appId': controller.appId,
      },
    );
  }

  void _toggleSelectAllSellable(Set<int> sellableIds) {
    if (sellableIds.isEmpty) {
      return;
    }
    final selectedIds = controller.selectedIds;
    final isAllSelected = sellableIds.every(selectedIds.contains);
    if (isAllSelected) {
      selectedIds.removeAll(sellableIds);
    } else {
      selectedIds.addAll(sellableIds);
    }
    selectedIds.refresh();
  }

  Future<void> _openFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: controller.currentAppId.value,
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.price', field: 'price'),
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      initial: MarketFilterResult(
        sortField: controller.sortField.value,
        sortAsc: controller.sortAsc.value,
        priceMin: controller.priceMin.value,
        priceMax: controller.priceMax.value,
        tags: Map<String, dynamic>.from(controller.tags),
        itemName: controller.itemName.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _searchController.clear();
      }
      await controller.applyFilter(
        field: result.sortField,
        asc: result.sortAsc,
        minPrice: result.priceMin,
        maxPrice: result.priceMax,
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  ShopSchemaInfo? _lookupSchema(
    Map<String, ShopSchemaInfo> schemas,
    InventoryItem item,
  ) {
    final hash = item.marketHashName;
    if (hash != null && schemas.containsKey(hash)) {
      return schemas[hash];
    }
    final schemaId = item.schemaId?.toString();
    if (schemaId != null && schemas.containsKey(schemaId)) {
      return schemas[schemaId];
    }
    return null;
  }

  int _inventoryFilterToPage(_InventoryStateFilter filter) {
    switch (filter) {
      case _InventoryStateFilter.all:
        return 0;
      case _InventoryStateFilter.sellable:
        return 1;
      case _InventoryStateFilter.cooling:
        return 2;
    }
  }

  _InventoryStateFilter _inventoryFilterFromPage(int page) {
    switch (page) {
      case 1:
        return _InventoryStateFilter.sellable;
      case 2:
        return _InventoryStateFilter.cooling;
      default:
        return _InventoryStateFilter.all;
    }
  }

  Future<void> _applyInventoryStateFilter(
    _InventoryStateFilter selected,
  ) async {
    switch (selected) {
      case _InventoryStateFilter.all:
        if (controller.sellableOnly.value) {
          await controller.toggleSellable();
          return;
        }
        if (controller.coolingOnly.value) {
          await controller.toggleCooling();
        }
        return;
      case _InventoryStateFilter.sellable:
        if (!controller.sellableOnly.value) {
          await controller.toggleSellable();
        }
        return;
      case _InventoryStateFilter.cooling:
        if (!controller.coolingOnly.value) {
          await controller.toggleCooling();
        }
        return;
    }
  }

  Future<void> _animateToInventoryStatePage(
    _InventoryStateFilter filter,
  ) async {
    if (!_inventoryStatePageController.hasClients) {
      await _applyInventoryStateFilter(filter);
      return;
    }
    final targetPage = _inventoryFilterToPage(filter);
    final currentPage =
        (_inventoryStatePageController.page ??
                _inventoryStatePageController.initialPage.toDouble())
            .round();
    if (currentPage == targetPage) {
      return;
    }
    await _inventoryStatePageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onInventoryStatePageChanged(int page) async {
    if (controller.isLoading.value) {
      await _animateToInventoryStatePage(_currentInventoryStateFilter());
      return;
    }
    final selected = _inventoryFilterFromPage(page);
    if (selected == _currentInventoryStateFilter()) {
      return;
    }
    await _applyInventoryStateFilter(selected);
  }

  bool _onInventoryScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0) {
      return false;
    }
    if (metrics.pixels >= metrics.maxScrollExtent - 240) {
      controller.loadMore();
    }
    return false;
  }

  Widget _buildInventoryListView({required Key scrollViewKey}) {
    return Obx(() {
      if (controller.items.isEmpty && controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onInventoryScrollNotification,
          child: CustomScrollView(
            key: scrollViewKey,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (controller.items.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Text('app.common.no_data'.tr)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      final schema = _lookupSchema(controller.schemas, item);
                      final isTradable = item.tradable ?? true;
                      final isCooling = item.coolingDown ?? false;
                      final isOnSale = item.status == 1;
                      final isInSupply = item.status == 2;
                      final disabled = !_isItemSelectable(item);
                      final disabledLabel = !isTradable
                          ? 'app.trade.non_tradable'.tr
                          : isCooling
                          ? 'app.market.product.cooling'.tr
                          : isOnSale
                          ? 'app.inventory.on_sale'.tr
                          : isInSupply
                          ? 'app.inventory.in_supply'.tr
                          : null;
                      return Obx(() {
                        final selected = controller.selectedIds.contains(
                          item.id ?? -1,
                        );
                        return InventoryItemCard(
                          item: item,
                          schema: schema,
                          schemaMap: controller.schemas,
                          stickerMap: controller.stickers,
                          selected: selected,
                          disabledLabel: disabled ? disabledLabel : null,
                          onTap: () {
                            if (item.id == null) {
                              return;
                            }
                            if (disabled) {
                              Get.snackbar(
                                'app.system.tips.title'.tr,
                                !isTradable
                                    ? 'app.inventory.message.non_tradable'.tr
                                    : isCooling
                                    ? 'app.market.product.cooling'.tr
                                    : isOnSale
                                    ? 'app.inventory.on_sale'.tr
                                    : 'app.inventory.in_supply'.tr,

                                titleText: const SizedBox.shrink(),
                              );
                              return;
                            }
                            controller.toggleSelection(item.id!);
                          },
                        );
                      });
                    },
                  ),
                ),
              if (controller.isLoading.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (controller.items.isNotEmpty &&
                  !controller.isLoading.value &&
                  !controller.hasMore)
                const SliverToBoxAdapter(child: ListEndTip()),
            ],
          ),
        ),
      );
    });
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'app.inventory.title'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _buildTopRightActions(),
                        ],
                      ),
                    ),
                    _buildSearchBar(),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildInventorySummaryBar(currency),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.currentAppId.value == 440) {
                    return _buildInventoryListView(
                      scrollViewKey: const PageStorageKey(
                        'inventory_scroll_single',
                      ),
                    );
                  }
                  return PageView(
                    controller: _inventoryStatePageController,
                    onPageChanged: (page) {
                      _onInventoryStatePageChanged(page);
                    },
                    children: [
                      _buildInventoryListView(
                        scrollViewKey: const PageStorageKey(
                          'inventory_scroll_all',
                        ),
                      ),
                      _buildInventoryListView(
                        scrollViewKey: const PageStorageKey(
                          'inventory_scroll_sellable',
                        ),
                      ),
                      _buildInventoryListView(
                        scrollViewKey: const PageStorageKey(
                          'inventory_scroll_cooling',
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!userController.isLoggedIn.value ||
            controller.selectedIds.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildInventorySelectionBar();
      }),
    );
  }

  Widget _buildInventorySelectionBar() {
    final sellableTotal = controller.items.where(_isItemSelectable).length;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          final selectedCount = controller.selectedIds.length;
          final isAllSelected =
              sellableTotal > 0 && selectedCount >= sellableTotal;
          final toggleMessage = isAllSelected
              ? 'app.common.deselect_all'.tr
              : 'app.common.select_all'.tr;
          final showCompactCount = constraints.maxWidth < 350;
          final summaryBackground = isDark
              ? colors.surfaceContainerHigh
              : colors.surfaceContainerHighest.withValues(alpha: 0.82);
          final summaryBorder = colors.outline.withValues(alpha: 0.16);

          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outline.withValues(alpha: 0.10)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                Tooltip(
                  message: toggleMessage,
                  child: Material(
                    color: summaryBackground,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _toggleSelectAllSellable(
                        controller.items
                            .where(_isItemSelectable)
                            .map((item) => item.id)
                            .whereType<int>()
                            .toSet(),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: showCompactCount ? 82 : 94,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: showCompactCount ? 10 : 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: summaryBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(
                                  alpha: isAllSelected
                                      ? (isDark ? 0.34 : 0.22)
                                      : (isDark ? 0.10 : 0.05),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.primary.withValues(
                                    alpha: isAllSelected
                                        ? (isDark ? 0.42 : 0.30)
                                        : (isDark ? 0.22 : 0.14),
                                  ),
                                ),
                              ),
                              child: isAllSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: colors.primary,
                                      size: 16,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                showCompactCount
                                    ? '$selectedCount/$sellableTotal'
                                    : '($selectedCount/$sellableTotal)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInventorySelectionActionButton(
                    label: 'app.inventory.upshop.text'.tr,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    onTap: _openSelectedItemsUpshop,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventorySelectionActionButton({
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        Color.lerp(
          backgroundColor,
          colors.primaryContainer,
          isDark ? 0.26 : 0.18,
        ) ??
        backgroundColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, backgroundColor],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 54,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightActions() {
    return Obx(() {
      final showStateFilters = controller.currentAppId.value != 440;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStateFilters) ...[
            _buildInventoryStateSwitcher(),
            const SizedBox(width: 6),
          ],
          _buildGameIcon(),
        ],
      );
    });
  }

  _InventoryStateFilter _currentInventoryStateFilter() {
    if (controller.sellableOnly.value) {
      return _InventoryStateFilter.sellable;
    }
    if (controller.coolingOnly.value) {
      return _InventoryStateFilter.cooling;
    }
    return _InventoryStateFilter.all;
  }

  String _inventoryStateLabelKey(_InventoryStateFilter filter) {
    switch (filter) {
      case _InventoryStateFilter.sellable:
        return 'app.market.product.sellable';
      case _InventoryStateFilter.cooling:
        return 'app.market.product.cooling';
      case _InventoryStateFilter.all:
        return 'app.market.filter.all';
    }
  }

  IconData _inventoryStateIcon(_InventoryStateFilter filter) {
    switch (filter) {
      case _InventoryStateFilter.sellable:
        return Icons.sell_outlined;
      case _InventoryStateFilter.cooling:
        return Icons.timer_outlined;
      case _InventoryStateFilter.all:
        return Icons.apps_outlined;
    }
  }

  Future<void> _openInventoryStateSwitchMenu(BuildContext iconContext) async {
    if (controller.isLoading.value) {
      return;
    }
    final currentFilter = _currentInventoryStateFilter();
    final selected = await _showInventoryStateSwitchMenu(
      iconContext: iconContext,
      currentFilter: currentFilter,
    );
    if (selected == null || selected == currentFilter) {
      return;
    }
    await _animateToInventoryStatePage(selected);
  }

  Widget _buildInventoryStateSwitcher() {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final loading = controller.isLoading.value;
      final filter = _currentInventoryStateFilter();
      final iconColor = colors.onSurfaceVariant;
      final opacity = loading ? 0.45 : 1.0;
      final label = _inventoryStateLabelKey(filter).tr;

      return Builder(
        builder: (iconContext) {
          return Opacity(
            opacity: opacity,
            child: Tooltip(
              message: label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openInventoryStateSwitchMenu(iconContext),
                  child: SizedBox(
                    height: 34,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _inventoryStateIcon(filter),
                            size: 18,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 72),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildGameIcon() {
    return Obx(() {
      final appId = controller.currentAppId.value;
      return Builder(
        builder: (iconContext) {
          return GameIconButton(
            appId: appId,
            size: 34,
            onTap: () async {
              final selected = await showGameSwitchMenu(
                iconContext: iconContext,
                currentAppId: controller.currentAppId.value,
              );
              if (selected == null) {
                return;
              }
              MarketFilterSheet.preload(appId: selected);
              await controller.changeGame(selected);
              await controller.preloadStateBucketsIfNeeded();
            },
          );
        },
      );
    });
  }

  Widget _buildInventorySummaryBar(CurrencyController currency) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseStart = isDark ? colors.surfaceContainerHigh : Colors.white;
    final baseEnd = isDark
        ? colors.surfaceContainer
        : colors.primary.withValues(alpha: 0.05);
    final borderColor = colors.outline.withValues(alpha: 0.18);

    return Obx(() {
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
              child: _buildInventorySummaryMetric(
                label: 'app.inventory.count'.tr,
                value: '${controller.total.value}',
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            Expanded(
              child: _buildInventorySummaryMetric(
                label: 'app.inventory.total_value'.tr,
                value: currency.format(controller.totalPrice.value),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInventorySummaryMetric({
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

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceVariant;
    final hintColor = isDark
        ? Colors.white38
        : colors.onSurface.withValues(alpha: 0.4);
    final hasKeyword = _searchController.text.trim().isNotEmpty;

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
                  controller: _searchController,
                  onSubmitted: (_) => _search(),
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
                              _searchController.clear();
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
          _buildActionButton(
            tooltip: 'app.market.filter.search'.tr,
            icon: Icons.send,
            onTap: _search,
          ),
          const SizedBox(width: 6),
          _buildActionButton(
            tooltip: 'app.market.filter.text'.tr,
            icon: Icons.filter_alt_outlined,
            onTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
}

class _InventorySteamSessionExpiredDialog extends StatelessWidget {
  const _InventorySteamSessionExpiredDialog({
    required this.onCancel,
    required this.onVerify,
  });

  final VoidCallback onCancel;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final verifyLabel = Get.locale?.languageCode == 'en'
        ? 'Verification'
        : 'app.steam.verification'.tr;
    final borderColor = colors.error.withValues(alpha: isDark ? 0.24 : 0.12);
    final iconBackground = colors.error.withValues(alpha: isDark ? 0.24 : 0.10);
    final dialogColor = colors.errorContainer.withValues(
      alpha: isDark ? 0.44 : 0.92,
    );
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onErrorContainer,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      color: colors.onErrorContainer.withValues(alpha: 0.86),
    );

    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dialogColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: colors.onErrorContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('app.steam.verification'.tr, style: titleStyle),
                          const SizedBox(height: 4),
                          Text(
                            'app.steam.session.expired'.tr,
                            style: bodyStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: Text('app.common.cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onVerify,
                        child: Text(verifyLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<_InventoryStateFilter?> _showInventoryStateSwitchMenu({
  required BuildContext iconContext,
  required _InventoryStateFilter currentFilter,
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

  return showGeneralDialog<_InventoryStateFilter>(
    context: iconContext,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(
      iconContext,
    ).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, __, ___) {
      return _InventoryStateSwitchOverlay(
        animation: animation,
        alignment: alignment,
        top: panelTop,
        currentFilter: currentFilter,
      );
    },
  );
}

class _InventoryStateSwitchOverlay extends StatelessWidget {
  const _InventoryStateSwitchOverlay({
    required this.animation,
    required this.alignment,
    required this.top,
    required this.currentFilter,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final _InventoryStateFilter currentFilter;

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
                  child: _InventoryStateSwitchPanel(
                    currentFilter: currentFilter,
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

class _InventoryStateSwitchPanel extends StatelessWidget {
  const _InventoryStateSwitchPanel({required this.currentFilter});

  final _InventoryStateFilter currentFilter;

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
          _InventoryStateOption(
            filter: _InventoryStateFilter.all,
            icon: Icons.apps_outlined,
            labelKey: 'app.market.filter.all',
            selected: currentFilter == _InventoryStateFilter.all,
          ),
          Divider(height: 1, color: divider),
          _InventoryStateOption(
            filter: _InventoryStateFilter.sellable,
            icon: Icons.sell_outlined,
            labelKey: 'app.market.product.sellable',
            selected: currentFilter == _InventoryStateFilter.sellable,
          ),
          Divider(height: 1, color: divider),
          _InventoryStateOption(
            filter: _InventoryStateFilter.cooling,
            icon: Icons.timer_outlined,
            labelKey: 'app.market.product.cooling',
            selected: currentFilter == _InventoryStateFilter.cooling,
          ),
        ],
      ),
    );
  }
}

class _InventoryStateOption extends StatelessWidget {
  const _InventoryStateOption({
    required this.filter,
    required this.icon,
    required this.labelKey,
    required this.selected,
  });

  final _InventoryStateFilter filter;
  final IconData icon;
  final String labelKey;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFFFB800);
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
            if (selected)
              const Icon(Icons.check, color: selectedColor, size: 18),
          ],
        ),
      ),
    );
  }
}
