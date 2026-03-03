import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/market/market_item_card.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/market/market_search_sheet.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/home/home_controller.dart';
import 'package:tronskins_app/controllers/market/market_list_controller.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final HomeController controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());
  late final TabController _tabController;
  final ScrollController _latestScroll = ScrollController();
  final ScrollController _hotScroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _tabDragDx = 0;
  String _sortField = 'price';
  bool _sortAsc = false;
  double? _priceMin;
  double? _priceMax;
  Map<String, dynamic>? _tags;
  String? _itemName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarketFilterSheet.preload(appId: controller.appId.value);
    });
    _latestScroll.addListener(() {
      if (_latestScroll.position.pixels >
          _latestScroll.position.maxScrollExtent - 200) {
        controller.fetchLatest();
      }
    });
    _hotScroll.addListener(() {
      if (_hotScroll.position.pixels >
          _hotScroll.position.maxScrollExtent - 200) {
        controller.fetchHot();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latestScroll.dispose();
    _hotScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: controller.appId.value,
      sortOptions: [
        SortOption(labelKey: 'app.market.filter.price', field: 'price'),
        SortOption(labelKey: 'app.market.filter.hot', field: 'hot'),
      ],
      initial: MarketFilterResult(
        sortField: _sortField,
        sortAsc: _sortAsc,
        priceMin: _priceMin,
        priceMax: _priceMax,
        tags: _tags,
        itemName: _itemName,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        setState(() => _searchController.clear());
      }
      setState(() {
        _sortField = result.sortField;
        _sortAsc = result.sortAsc;
        _priceMin = result.priceMin;
        _priceMax = result.priceMax;
        _tags = result.tags == null || result.tags!.isEmpty
            ? null
            : result.tags;
        _itemName = (result.itemName == null || result.itemName!.isEmpty)
            ? null
            : result.itemName;
      });
      _switchToMarketWithArgs({
        'keyword': _searchController.text.trim(),
        'sortField': result.sortField,
        'sortAsc': result.sortAsc,
        'minPrice': result.priceMin,
        'maxPrice': result.priceMax,
        'tags': result.tags,
        'itemName': result.itemName,
      });
    }
  }

  void _submitSearch() {
    _switchToMarketWithArgs({
      'keyword': _searchController.text.trim(),
      'sortField': _sortField,
      'sortAsc': _sortAsc,
      'minPrice': _priceMin,
      'maxPrice': _priceMax,
      'tags': _tags,
      'itemName': _itemName,
    });
  }

  void _switchToMarketWithArgs(Map<String, dynamic> args) {
    args['appId'] = controller.appId.value;
    final marketCtrl = Get.isRegistered<MarketListController>()
        ? Get.find<MarketListController>()
        : Get.put(MarketListController());
    marketCtrl.applyInitialArgs(args);
    marketCtrl.refresh(reset: true);
    final navCtrl = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    navCtrl.switchTo(1);
  }

  Future<void> _openSearchSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MarketSearchSheet(
        appId: controller.appId.value,
        initialKeyword: _searchController.text,
      ),
    );
    if (result != null) {
      setState(() => _searchController.text = result);
      _submitSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
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
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final scale = (maxWidth / 375)
                            .clamp(0.85, 1.0)
                            .toDouble();
                        final gameIconSize = 34 * scale;
                        final sidePadding = 10 * scale;

                        return Row(
                          children: [
                            SizedBox(width: sidePadding),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    _tabDragDx += details.delta.dx;
                                  },
                                  onHorizontalDragEnd: (_) {
                                    if (_tabDragDx.abs() < 16) {
                                      _tabDragDx = 0;
                                      return;
                                    }
                                    final nextIndex = _tabDragDx < 0
                                        ? _tabController.index + 1
                                        : _tabController.index - 1;
                                    if (nextIndex >= 0 &&
                                        nextIndex < _tabController.length) {
                                      _tabController.animateTo(nextIndex);
                                    }
                                    _tabDragDx = 0;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: false,
                                      padding: EdgeInsets.zero,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: BoxDecoration(
                                        color: colors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      labelColor: colors.primary,
                                      unselectedLabelColor: colors.onSurface
                                          .withValues(alpha: 0.6),
                                      labelStyle: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1,
                                          ),
                                      unselectedLabelStyle: theme
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            height: 1,
                                          ),
                                      labelPadding: EdgeInsets.zero,
                                      dividerColor: Colors.transparent,
                                      splashBorderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                      tabs: [
                                        Tab(
                                          height: 30,
                                          text: 'app.market.latest'.tr,
                                        ),
                                        Tab(
                                          height: 30,
                                          text: 'app.market.popular'.tr,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Obx(() {
                              final appId = controller.appId.value;
                              return Builder(
                                builder: (iconContext) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: 12 * scale,
                                      left: 6 * scale,
                                    ),
                                    child: GameIconButton(
                                      appId: appId,
                                      size: gameIconSize,
                                      onTap: () async {
                                        final selected =
                                            await showGameSwitchMenu(
                                              iconContext: iconContext,
                                              currentAppId:
                                                  controller.appId.value,
                                            );
                                        if (selected == null) {
                                          return;
                                        }
                                        await controller.changeGame(selected);
                                        MarketFilterSheet.preload(
                                          appId: selected,
                                        );
                                        if (!mounted) {
                                          return;
                                        }
                                        setState(() {
                                          _sortField = 'price';
                                          _sortAsc = false;
                                          _priceMin = null;
                                          _priceMax = null;
                                          _tags = null;
                                          _itemName = null;
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildSearchBar(),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Obx(
                    () => _buildGrid(
                      controller.latestItems,
                      controller.isLoadingLatest.value,
                      controller.latestHasMore,
                      _latestScroll,
                      onRefresh: () => controller.fetchLatest(reset: true),
                    ),
                  ),
                  Obx(
                    () => _buildGrid(
                      controller.hotItems,
                      controller.isLoadingHot.value,
                      controller.hotHasMore,
                      _hotScroll,
                      onRefresh: () => controller.fetchHot(reset: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  readOnly: true,
                  onTap: _openSearchSheet,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'app.market.filter.search'.tr,
                    hintStyle: TextStyle(color: hintColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: hintColor, size: 18),
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() => _searchController.clear());
                            },
                          ),
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
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceVariant;
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

  Widget _buildGrid(
    List<MarketItemEntity> items,
    bool isLoading,
    bool hasMore,
    ScrollController scrollController, {
    required Future<void> Function() onRefresh,
  }) {
    if (items.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('app.common.no_data'.tr)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MarketItemCard(
                    item: item,
                    onTap: () =>
                        Get.toNamed(Routers.MARKET_DETAIL, arguments: item),
                  );
                },
              ),
            ),
          if (isLoading && hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (items.isNotEmpty && !isLoading && !hasMore)
            const SliverToBoxAdapter(child: ListEndTip()),
        ],
      ),
    );
  }
}
