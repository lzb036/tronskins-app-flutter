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
  final ScrollController _scrollController = ScrollController();
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

  Future<void> _toSteamBind() async {
    try {
      final tokenRes = await _steamApi.getTemporaryToken();
      final token = tokenRes.datas;
      if (!tokenRes.success || token == null || token.isEmpty) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.login.message.error'.tr,
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
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarketFilterSheet.preload(appId: controller.currentAppId.value);
    });
    if (userController.isLoggedIn.value) {
      controller.refreshIfStale();
      Future.microtask(_checkSteamSessionIfNeeded);
    }
    _scrollController.addListener(_handleScroll);
    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        controller.refreshIfStale();
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
          controller.refreshIfStale();
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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _loginWorker?.dispose();
    _tabWorker?.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 240) {
      controller.loadMore();
    }
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
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'app.inventory.title'.tr,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _buildTopRightActions(),
                        ],
                      ),
                    ),
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInventorySummaryBar(currency),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.items.isEmpty && controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        if (controller.items.isEmpty)
                          SliverFillRemaining(
                            child: Center(child: Text('app.common.no_data'.tr)),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.74,
                                  ),
                              itemCount: controller.items.length,
                              itemBuilder: (context, index) {
                                final item = controller.items[index];
                                final schema = _lookupSchema(
                                  controller.schemas,
                                  item,
                                );
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
                                  final selected = controller.selectedIds
                                      .contains(item.id ?? -1);
                                  return InventoryItemCard(
                                    item: item,
                                    schema: schema,
                                    schemaMap: controller.schemas,
                                    stickerMap: controller.stickers,
                                    selected: selected,
                                    disabledLabel: disabled
                                        ? disabledLabel
                                        : null,
                                    onTap: () {
                                      if (item.id == null) {
                                        return;
                                      }
                                      if (disabled) {
                                        Get.snackbar(
                                          'app.system.tips.title'.tr,
                                          !isTradable
                                              ? 'app.inventory.message.non_tradable'
                                                    .tr
                                              : isCooling
                                              ? 'app.market.product.cooling'.tr
                                              : isOnSale
                                              ? 'app.inventory.on_sale'.tr
                                              : 'app.inventory.in_supply'.tr,
                                        );
                                        return;
                                      }
                                      final changed = controller
                                          .toggleSelection(
                                            item.id!,
                                            maxSelection: InventoryController
                                                .maxUpShopSelection,
                                          );
                                      if (!changed) {
                                        Get.snackbar(
                                          'app.system.tips.title'.tr,
                                          '${'app.trade.supply.message.more_than_needed'.tr}'
                                          ' (${InventoryController.maxUpShopSelection})',
                                        );
                                      }
                                    },
                                  );
                                });
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: AnimatedOpacity(
                            opacity: controller.isLoading.value ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: controller.isLoading.value
                                    ? const CircularProgressIndicator()
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${'app.inventory.count'.tr}: '
                  '${controller.selectedIds.length}/'
                  '${InventoryController.maxUpShopSelection}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: controller.clearSelection,
                  child: Text('app.common.cancel'.tr),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    if (controller.selectedIds.isEmpty) {
                      return;
                    }
                    if (controller.selectedIds.length >
                        InventoryController.maxUpShopSelection) {
                      Get.snackbar(
                        'app.system.tips.title'.tr,
                        '${'app.trade.supply.message.more_than_needed'.tr}'
                        ' (${InventoryController.maxUpShopSelection})',
                      );
                      return;
                    }
                    final selectedItems = controller.items
                        .where(
                          (item) =>
                              controller.selectedIds.contains(item.id ?? -1),
                        )
                        .toList();
                    if (selectedItems.isEmpty) {
                      return;
                    }
                    Get.toNamed(
                      Routers.INVENTORY_UPSHOP,
                      arguments: {
                        'items': selectedItems,
                        'schemas': controller.schemas,
                        'appId': controller.appId,
                      },
                    );
                  },
                  child: Text('app.inventory.upshop.text'.tr),
                ),
              ],
            ),
          ),
        );
      }),
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
            const SizedBox(width: 8),
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

  Widget _buildInventoryStateSwitcher() {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final loading = controller.isLoading.value;
      final filter = _currentInventoryStateFilter();
      final iconColor = colors.onSurfaceVariant;
      final opacity = loading ? 0.45 : 1.0;

      return Builder(
        builder: (iconContext) {
          return Opacity(
            opacity: opacity,
            child: Tooltip(
              message: _inventoryStateLabelKey(filter).tr,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _openInventoryStateSwitchMenu(iconContext),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      _inventoryStateIcon(filter),
                      size: 22,
                      color: iconColor,
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
            onTap: () async {
              final selected = await showGameSwitchMenu(
                iconContext: iconContext,
                currentAppId: controller.currentAppId.value,
              );
              if (selected == null) {
                return;
              }
              MarketFilterSheet.preload(appId: selected);
              controller.changeGame(selected);
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseStart, baseEnd],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildInventorySummaryMetric(
                icon: Icons.inventory_2_outlined,
                iconColor: colors.primary,
                label: 'app.inventory.count'.tr,
                value: '${controller.total.value}',
              ),
            ),
            Container(
              width: 1,
              height: 34,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            Expanded(
              child: _buildInventorySummaryMetric(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFFE2A400),
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
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: Material(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
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
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
                    suffixIcon: hasKeyword
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
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
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            tooltip: 'app.market.filter.search'.tr,
            icon: Icons.send,
            onTap: _search,
          ),
          const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: iconColor, size: 20),
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
                  child: Align(
                    alignment: alignment,
                    child: _InventoryStateSwitchPanel(
                      currentFilter: currentFilter,
                    ),
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
