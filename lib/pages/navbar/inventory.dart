import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/inventory_item_card.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/price_sort_filter_sheet.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/controllers/inventory/inventory_controller.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

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
    final result = await showModalBottomSheet<PriceSortFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PriceSortFilterSheet(
        sortOptions: const [
          SortOption(labelKey: 'app.market.filter.price', field: 'price'),
          SortOption(labelKey: 'app.market.filter.time', field: 'time'),
        ],
        showInventoryStateFilters: controller.currentAppId.value != 440,
        initial: PriceSortFilterResult(
          sortField: controller.sortField.value,
          sortAsc: controller.sortAsc.value,
          priceMin: controller.priceMin.value,
          priceMax: controller.priceMax.value,
          sellableOnly: controller.sellableOnly.value,
          coolingOnly: controller.coolingOnly.value,
        ),
      ),
    );
    if (result != null) {
      await controller.applyFilter(
        field: result.sortField,
        asc: result.sortAsc,
        minPrice: result.priceMin,
        maxPrice: result.priceMax,
        sellableOnlyFlag: result.sellableOnly,
        coolingOnlyFlag: result.coolingOnly,
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
                  color: Theme.of(context).scaffoldBackgroundColor,
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
                          Row(children: [_buildGameIcon()]),
                        ],
                      ),
                    ),
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(
                                  '${'app.inventory.count'.tr}: ${controller.total.value}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${'app.inventory.total_value'.tr}: ${currency.format(controller.totalPrice.value)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

  Widget _buildGameIcon() {
    return Obx(() {
      final appId = controller.currentAppId.value;
      return Builder(
        builder: (iconContext) {
          return GestureDetector(
            onTap: () async {
              final selected = await showGameSwitchMenu(
                iconContext: iconContext,
                currentAppId: controller.currentAppId.value,
              );
              if (selected == null) {
                return;
              }
              controller.changeGame(selected);
            },
            child: Image.asset(
              'assets/images/game/icon/$appId.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.videogame_asset);
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white38 : Colors.grey[400];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'app.market.filter.search'.tr,
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
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
            icon: const Icon(Icons.send),
            onPressed: _search,
          ),
          IconButton(
            tooltip: 'app.market.filter.text'.tr,
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _openFilterSheet,
          ),
        ],
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
