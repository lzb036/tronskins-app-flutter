import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/user/collection_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class MyCollectionPage extends StatefulWidget {
  const MyCollectionPage({super.key});

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _MyCollectionPageState extends State<MyCollectionPage>
    with SingleTickerProviderStateMixin {
  final UserController _userController = Get.find<UserController>();
  late final TabController _tabController;
  final _categoryTabKey = GlobalKey<_CollectionCategoryTabState>();
  final _favoriteTabKey = GlobalKey<_CollectionFavoriteTabState>();
  final _categoryControls = _CollectionTabControls();
  final _favoriteControls = _CollectionTabControls();
  int _appId = GameStorage.getGameType();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _categoryControls.searchController.addListener(_handleTopBarChanged);
    _favoriteControls.searchController.addListener(_handleTopBarChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _categoryControls.searchController.removeListener(_handleTopBarChanged);
    _favoriteControls.searchController.removeListener(_handleTopBarChanged);
    _categoryControls.dispose();
    _favoriteControls.dispose();
    super.dispose();
  }

  bool get _isCategoryTab => _currentTabIndex == 0;

  _CollectionTabControls get _activeControls =>
      _isCategoryTab ? _categoryControls : _favoriteControls;

  _CollectionTabHandle? get _activeTabHandle => _isCategoryTab
      ? _categoryTabKey.currentState
      : _favoriteTabKey.currentState;

  void _handleTabChange() {
    final nextIndex = _tabController.index;
    if (!mounted || _currentTabIndex == nextIndex) {
      return;
    }
    setState(() => _currentTabIndex = nextIndex);
  }

  void _handleTopBarChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitActiveSearch([String? value]) async {
    await _activeTabHandle?.submitSearch(value);
    _handleTopBarChanged();
  }

  Future<void> _openActiveFilterSheet() async {
    await _activeTabHandle?.openFilter(_appId);
    _handleTopBarChanged();
  }

  Future<void> _showGameMenu(BuildContext iconContext) async {
    final result = await showGameSwitchMenu(
      iconContext: iconContext,
      currentAppId: _appId,
    );
    if (result == null || result == _appId) {
      return;
    }
    await GameStorage.setGameType(result);
    if (!mounted) {
      return;
    }
    setState(() => _appId = result);
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

  Widget _buildTopSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
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
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dragWidth = constraints.maxWidth;
                final maxIndex = (_tabController.length - 1).toDouble();

                void settleToClosestTab() {
                  if (_tabController.indexIsChanging) {
                    return;
                  }
                  final value =
                      _tabController.animation?.value ??
                      _tabController.index.toDouble();
                  final targetIndex = value.round().clamp(
                    0,
                    _tabController.length - 1,
                  );
                  if (targetIndex == _tabController.index) {
                    _tabController.offset = 0;
                    return;
                  }
                  _tabController.animateTo(
                    targetIndex,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                  );
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    if (_tabController.indexIsChanging || dragWidth <= 0) {
                      return;
                    }
                    final currentValue =
                        _tabController.animation?.value ??
                        _tabController.index.toDouble();
                    final nextValue =
                        (currentValue - (details.delta.dx / dragWidth))
                            .clamp(0.0, maxIndex)
                            .toDouble();
                    final nextOffset = (nextValue - _tabController.index)
                        .clamp(-1.0, 1.0)
                        .toDouble();
                    if (nextOffset >= 0.98 &&
                        _tabController.index < _tabController.length - 1) {
                      _tabController.index = _tabController.index + 1;
                      _tabController.offset = 0;
                      return;
                    }
                    if (nextOffset <= -0.98 && _tabController.index > 0) {
                      _tabController.index = _tabController.index - 1;
                      _tabController.offset = 0;
                      return;
                    }
                    _tabController.offset = nextOffset;
                  },
                  onHorizontalDragEnd: (_) => settleToClosestTab(),
                  onHorizontalDragCancel: settleToClosestTab,
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
                    unselectedLabelColor: colors.onSurface.withValues(
                      alpha: 0.6,
                    ),
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
                    splashBorderRadius: BorderRadius.circular(16),
                    tabs: [
                      Tab(height: 30, text: 'app.user.collection.category'.tr),
                      Tab(height: 30, text: 'app.user.collection.single'.tr),
                    ],
                  ),
                );
              },
            ),
          ),
          _CollectionSearchBar(
            controller: _activeControls.searchController,
            onSubmitted: _submitActiveSearch,
            onSearch: _submitActiveSearch,
            onFilter: _openActiveFilterSheet,
            filterActive: _activeControls.hasActiveFilter,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = _userController.isLoggedIn.value;
      return BackToTopScope(
        enabled: false,
        child: Scaffold(
          appBar: AppBar(
            title: Text('app.user.menu.collection'.tr),
            actions: [
              Builder(
                builder: (iconContext) => IconButton(
                  onPressed: () => _showGameMenu(iconContext),
                  icon: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset(
                      'assets/images/game/icon/$_appId.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, _, __) => const Icon(Icons.games),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: loggedIn
              ? Column(
                  children: [
                    _buildTopSection(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _CollectionCategoryTab(
                            key: _categoryTabKey,
                            appId: _appId,
                            controls: _categoryControls,
                            onControlsChanged: _handleTopBarChanged,
                          ),
                          _CollectionFavoriteTab(
                            key: _favoriteTabKey,
                            appId: _appId,
                            controls: _favoriteControls,
                            onControlsChanged: _handleTopBarChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _buildLoginPrompt(),
        ),
      );
    });
  }
}

class _CollectionTabControls {
  final TextEditingController searchController = TextEditingController();
  MarketFilterResult filter = const MarketFilterResult(
    sortField: 'price',
    sortAsc: false,
  );
  String keyword = '';

  bool get hasActiveFilter {
    return keyword.trim().isNotEmpty ||
        (filter.tags?.isNotEmpty ?? false) ||
        (filter.itemName?.isNotEmpty ?? false) ||
        filter.priceMin != null ||
        filter.priceMax != null ||
        filter.sortAsc;
  }

  void dispose() {
    searchController.dispose();
  }
}

abstract class _CollectionTabHandle {
  TextEditingController get searchController;
  bool get hasActiveFilter;
  Future<void> submitSearch([String? value]);
  Future<void> clearSearch();
  Future<void> openFilter(int appId);
}

abstract class _BaseCollectionTabState<T extends StatefulWidget>
    extends State<T>
    with AutomaticKeepAliveClientMixin
    implements _CollectionTabHandle {
  final ScrollController scrollController = ScrollController();
  final List<SortOption> sortOptions = const <SortOption>[
    SortOption(labelKey: 'app.market.filter.price', field: 'price'),
  ];
  bool loading = false;
  bool loadingMore = false;
  int page = 1;
  int total = 0;

  _CollectionTabControls get controls;

  VoidCallback? get onControlsChangedCallback;

  bool get hasMore => itemsLength < total;

  int get itemsLength;

  @override
  TextEditingController get searchController => controls.searchController;

  MarketFilterResult get filter => controls.filter;

  set filter(MarketFilterResult value) => controls.filter = value;

  String get keyword => controls.keyword;

  set keyword(String value) => controls.keyword = value;

  @override
  bool get hasActiveFilter => controls.hasActiveFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(handleScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void handleScroll() {
    if (!scrollController.hasClients || loading || loadingMore) {
      return;
    }
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160 && hasMore) {
      loadData();
    }
  }

  Future<void> loadData({bool refresh = false});

  void notifyControlsChanged() {
    onControlsChangedCallback?.call();
  }

  @override
  Future<void> submitSearch([String? value]) async {
    final nextKeyword = (value ?? searchController.text).trim();
    keyword = nextKeyword;
    notifyControlsChanged();
    await loadData(refresh: true);
  }

  @override
  Future<void> clearSearch() => submitSearch('');

  @override
  Future<void> openFilter(int appId) async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: appId,
      sortOptions: sortOptions,
      initial: filter,
      showPriceRange: true,
      showSort: true,
    );
    if (result == null) {
      return;
    }
    filter = result;
    if (result.clearKeyword) {
      searchController.clear();
      keyword = '';
    }
    notifyControlsChanged();
    await loadData(refresh: true);
  }
}

class _CollectionCategoryTab extends StatefulWidget {
  const _CollectionCategoryTab({
    super.key,
    required this.appId,
    required this.controls,
    this.onControlsChanged,
  });

  final int appId;
  final _CollectionTabControls controls;
  final VoidCallback? onControlsChanged;

  @override
  State<_CollectionCategoryTab> createState() => _CollectionCategoryTabState();
}

class _CollectionFavoriteTab extends StatefulWidget {
  const _CollectionFavoriteTab({
    super.key,
    required this.appId,
    required this.controls,
    this.onControlsChanged,
  });

  final int appId;
  final _CollectionTabControls controls;
  final VoidCallback? onControlsChanged;

  @override
  State<_CollectionFavoriteTab> createState() => _CollectionFavoriteTabState();
}

class _CollectionCategoryTabState
    extends _BaseCollectionTabState<_CollectionCategoryTab> {
  final ApiShopProductServer _api = ApiShopProductServer();
  final List<CollectionTemplateItem> _items = <CollectionTemplateItem>[];

  @override
  _CollectionTabControls get controls => widget.controls;

  @override
  VoidCallback? get onControlsChangedCallback => widget.onControlsChanged;

  @override
  int get itemsLength => _items.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(refresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant _CollectionCategoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appId != widget.appId) {
      filter = const MarketFilterResult(sortField: 'price', sortAsc: false);
      keyword = '';
      searchController.clear();
      notifyControlsChanged();
      loadData(refresh: true);
    }
  }

  @override
  Future<void> loadData({bool refresh = false}) async {
    if (loading || loadingMore) {
      return;
    }
    final nextPage = refresh ? 1 : page + 1;
    if (!refresh && !hasMore) {
      return;
    }
    setState(() {
      if (refresh) {
        loading = true;
      } else {
        loadingMore = true;
      }
    });
    try {
      final res = await _api.productCollectList(
        params:
            <String, dynamic>{
              'appId': widget.appId,
              'page': nextPage,
              'pageSize': 20,
              'field': filter.sortField,
              'asc': filter.sortAsc,
              'keywords': keyword.trim(),
              'tags': filter.tags,
              'itemName': filter.itemName,
              'minPrice': filter.priceMin,
              'maxPrice': filter.priceMax,
            }..removeWhere(
              (key, value) =>
                  value == null ||
                  value == '' ||
                  (value is Map && value.isEmpty),
            ),
      );
      if (!mounted) {
        return;
      }
      if (!res.success || res.datas == null) {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      final payload = res.datas!;
      setState(() {
        page = nextPage;
        total = payload.pager?.total ?? payload.items.length;
        if (refresh) {
          _items
            ..clear()
            ..addAll(payload.items);
        } else {
          _items.addAll(payload.items);
        }
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.error('app.trade.filter.failed'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  Future<void> _openDetail(CollectionTemplateItem item) async {
    await Get.toNamed(
      Routers.MARKET_DETAIL,
      arguments: item.toMarketItemEntity(),
    );
    if (!mounted) {
      return;
    }
    await loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currency = Get.find<CurrencyController>();
    return BackToTopScope(
      enabled: true,
      child: RefreshIndicator(
        onRefresh: () => loadData(refresh: true),
        child: loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const _CollectionEmptyState()
            : ListView.separated(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return _CollectionFooter(
                      showLoading: loadingMore,
                      showNoMore: !hasMore,
                    );
                  }
                  final item = _items[index];
                  final rarity = TagInfo.fromMarketTag(item.tags?.rarity);
                  final quality = TagInfo.fromMarketTag(item.tags?.quality);
                  final exterior = TagInfo.fromMarketTag(item.tags?.exterior);
                  final saleLabel = Get.locale?.languageCode == 'en'
                      ? 'Sale'
                      : 'app.trade.sale.text'.tr;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openDetail(item),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 84,
                              height: 52,
                              child: GameItemImage(
                                imageUrl: item.imageUrl,
                                appId: item.appId,
                                rarity: rarity,
                                quality: quality,
                                exterior: exterior,
                                avoidTopLeftBadgeOverlap: true,
                                compactTopLeftBadges: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.marketName ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 9,
                                        child: _CollectionInlinePrice(
                                          label: saleLabel,
                                          valueBuilder: () => currency.format(
                                            item.sellMinPrice ?? 0,
                                          ),
                                          valueColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 10,
                                        child: _CollectionInlinePrice(
                                          label: 'app.trade.purchase.text'.tr,
                                          valueBuilder: () => currency.format(
                                            item.buyMaxPrice ?? 0,
                                          ),
                                          valueColor: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CollectionFavoriteTabState
    extends _BaseCollectionTabState<_CollectionFavoriteTab> {
  final ApiMarketServer _marketApi = ApiMarketServer();
  final ApiShopProductServer _api = ApiShopProductServer();
  final List<CollectionFavoriteItem> _items = <CollectionFavoriteItem>[];

  @override
  _CollectionTabControls get controls => widget.controls;

  @override
  VoidCallback? get onControlsChangedCallback => widget.onControlsChanged;

  @override
  int get itemsLength => _items.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(refresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant _CollectionFavoriteTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appId != widget.appId) {
      filter = const MarketFilterResult(sortField: 'price', sortAsc: false);
      keyword = '';
      searchController.clear();
      notifyControlsChanged();
      loadData(refresh: true);
    }
  }

  @override
  Future<void> loadData({bool refresh = false}) async {
    if (loading || loadingMore) {
      return;
    }
    final nextPage = refresh ? 1 : page + 1;
    if (!refresh && !hasMore) {
      return;
    }
    setState(() {
      if (refresh) {
        loading = true;
      } else {
        loadingMore = true;
      }
    });
    try {
      final res = await _api.productFavoriteList(
        params:
            <String, dynamic>{
              'appId': widget.appId,
              'page': nextPage,
              'pageSize': 20,
              'field': filter.sortField,
              'asc': filter.sortAsc,
              'keywords': keyword.trim(),
              'tags': filter.tags,
              'itemName': filter.itemName,
              'minPrice': filter.priceMin,
              'maxPrice': filter.priceMax,
            }..removeWhere(
              (key, value) =>
                  value == null ||
                  value == '' ||
                  (value is Map && value.isEmpty),
            ),
      );
      if (!mounted) {
        return;
      }
      if (!res.success || res.datas == null) {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      final payload = res.datas!;
      setState(() {
        page = nextPage;
        total = payload.pager?.total ?? payload.items.length;
        if (refresh) {
          _items
            ..clear()
            ..addAll(payload.items);
        } else {
          _items.addAll(payload.items);
        }
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.error('app.trade.filter.failed'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  Future<void> _openDetail(CollectionFavoriteItem item) async {
    await Get.toNamed(
      Routers.MARKET_DETAIL,
      arguments: item.toMarketItemEntity(),
    );
    if (!mounted) {
      return;
    }
    await loadData(refresh: true);
  }

  Future<void> _cancelFavorite(CollectionFavoriteItem item) async {
    final itemId = item.itemId;
    if (itemId == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        content: Text('app.user.collection.uncollect_tips'.tr),
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
      final res = await _marketApi.removeFavorite(itemId: itemId);
      if (!res.success) {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      AppSnackbar.success('app.user.collection.uncollect_success'.tr);
      await loadData(refresh: true);
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currency = Get.find<CurrencyController>();
    return BackToTopScope(
      enabled: true,
      child: RefreshIndicator(
        onRefresh: () => loadData(refresh: true),
        child: loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const _CollectionEmptyState()
            : ListView.separated(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return _CollectionFooter(
                      showLoading: loadingMore,
                      showNoMore: !hasMore,
                    );
                  }
                  final item = _items[index];
                  final rarity = TagInfo.fromMarketTag(item.tags?.rarity);
                  final quality = TagInfo.fromMarketTag(item.tags?.quality);
                  final exterior = TagInfo.fromMarketTag(item.tags?.exterior);
                  final stickers = parseStickerList(item.stickerRaw);
                  final keychains = parseStickerList(item.keychainRaw);
                  final gems = parseGemList(item.gemRaw);
                  final paintWearValue = double.tryParse(item.paintWear ?? '');
                  final rawStatusName =
                      (item.raw['statusName'] ?? item.raw['status_name'])
                          ?.toString()
                          .trim() ??
                      '';
                  final showStatus = item.hasStatusTag;
                  final hasAccessories =
                      stickers.isNotEmpty ||
                      keychains.isNotEmpty ||
                      gems.isNotEmpty;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openDetail(item),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 84,
                                  height: 52,
                                  child: GameItemImage(
                                    imageUrl: item.imageUrl,
                                    appId: item.appId,
                                    rarity: rarity,
                                    quality: quality,
                                    exterior: exterior,
                                    percentage: item.percentage,
                                    phase: item.phase,
                                    avoidTopLeftBadgeOverlap: true,
                                    compactTopLeftBadges: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.marketName ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.15,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _CollectionInlineActionChip(
                                            label:
                                                'app.user.collection.uncollect'
                                                    .tr,
                                            onPressed: () =>
                                                _cancelFavorite(item),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (showStatus &&
                                              rawStatusName.isNotEmpty) ...[
                                            _CollectionStatusBadge(
                                              text: rawStatusName,
                                              status: item.status,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Expanded(
                                            child: Obx(
                                              () => Text(
                                                currency.format(
                                                  item.price ?? 0,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.1,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if ((item.paintWear?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${'app.market.csgo.abradability'.tr}: '
                                '${item.paintWear}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      height: 1.1,
                                    ),
                              ),
                            ],
                            if (paintWearValue != null || hasAccessories) ...[
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wearWidth = math.min(
                                    176.0,
                                    constraints.maxWidth * 0.5,
                                  );
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (paintWearValue != null)
                                        SizedBox(
                                          width: wearWidth,
                                          child: WearProgressBar(
                                            paintWear: paintWearValue,
                                            height: 16,
                                          ),
                                        ),
                                      if (hasAccessories) ...[
                                        if (paintWearValue != null)
                                          const SizedBox(width: 10),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _CollectionAccessoryWrap(
                                              stickers: stickers,
                                              keychains: keychains,
                                              gems: gems,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CollectionSearchBar extends StatelessWidget {
  const _CollectionSearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onSearch,
    required this.onFilter,
    this.filterActive = false,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 8),
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final bool filterActive;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final hintColor = isDark ? Colors.white38 : colors.onSurfaceVariant;
    final hasKeyword = controller.text.trim().isNotEmpty;

    return Padding(
      padding: padding,
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
          _CollectionActionButton(
            tooltip: 'app.market.filter.search'.tr,
            icon: Icons.send,
            onTap: onSearch,
          ),
          const SizedBox(width: 6),
          _CollectionActionButton(
            tooltip: 'app.market.filter.text'.tr,
            icon: Icons.filter_alt_outlined,
            onTap: onFilter,
            active: filterActive,
          ),
        ],
      ),
    );
  }
}

class _CollectionActionButton extends StatelessWidget {
  const _CollectionActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
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
}

class _CollectionInlinePrice extends StatelessWidget {
  const _CollectionInlinePrice({
    required this.label,
    required this.valueBuilder,
    required this.valueColor,
  });

  final String label;
  final String Function() valueBuilder;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Obx(
            () => Text(
              valueBuilder(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionInlineActionChip extends StatelessWidget {
  const _CollectionInlineActionChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 28),
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 60),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CollectionAccessoryWrap extends StatelessWidget {
  const _CollectionAccessoryWrap({
    required this.stickers,
    required this.keychains,
    required this.gems,
  });

  final List<GameItemSticker> stickers;
  final List<GameItemSticker> keychains;
  final List<GameItemGem> gems;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (stickers.isNotEmpty) StickerRow(stickers: stickers, size: 20),
      if (keychains.isNotEmpty) StickerRow(stickers: keychains, size: 20),
      if (gems.isNotEmpty) GemRow(gems: gems, size: 20),
    ];
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: children,
    );
  }
}

class _CollectionStatusBadge extends StatelessWidget {
  const _CollectionStatusBadge({required this.text, this.status});

  final String text;
  final int? status;

  ({Color bg, Color fg, Color border, Color dot}) _palette(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if ([5, 6].contains(status)) {
      final accent = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
      return (
        bg: accent.withValues(alpha: isDark ? 0.16 : 0.08),
        fg: accent,
        border: accent.withValues(alpha: isDark ? 0.28 : 0.14),
        dot: accent,
      );
    }

    if ([2, 3, 4].contains(status)) {
      final accent = isDark ? const Color(0xFFFDA4AF) : const Color(0xFFB42318);
      return (
        bg: accent.withValues(alpha: isDark ? 0.16 : 0.07),
        fg: accent,
        border: accent.withValues(alpha: isDark ? 0.26 : 0.12),
        dot: accent,
      );
    }

    final accent = colors.onSurfaceVariant;
    return (
      bg: colors.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.66 : 0.82,
      ),
      fg: accent,
      border: colors.outline.withValues(alpha: isDark ? 0.22 : 0.08),
      dot: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = text.trim();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = _palette(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionEmptyState extends StatelessWidget {
  const _CollectionEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 28,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  'app.common.no_data'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionFooter extends StatelessWidget {
  const _CollectionFooter({
    required this.showLoading,
    required this.showNoMore,
  });

  final bool showLoading;
  final bool showNoMore;

  @override
  Widget build(BuildContext context) {
    if (showLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 6, 0, 12),
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
