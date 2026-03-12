import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/filter/order_filter_sheet.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/shop/buy_request_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class BuyingPage extends StatefulWidget {
  const BuyingPage({super.key});

  @override
  State<BuyingPage> createState() => _BuyingPageState();
}

class _BuyingPageState extends State<BuyingPage>
    with SingleTickerProviderStateMixin {
  final BuyRequestController controller =
      Get.isRegistered<BuyRequestController>()
      ? Get.find<BuyRequestController>()
      : Get.put(BuyRequestController());

  late final TabController _tabController;
  late int _currentAppId;
  int _currentTabIndex = 0;
  final ScrollController _myBuyingScroll = ScrollController();
  final ScrollController _recordScroll = ScrollController();
  final TextEditingController _mySearchController = TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _currentAppId = GameStorage.getGameType();
    MarketFilterSheet.preload(appId: _currentAppId);
    _myBuyingScroll.addListener(_handleMyBuyingScroll);
    _recordScroll.addListener(_handleRecordScroll);
    _mySearchController.addListener(_handleSearchTextChange);
    _recordSearchController.addListener(_handleSearchTextChange);
    controller.refreshMyBuying();
    controller.refreshBuyRecords();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _myBuyingScroll
      ..removeListener(_handleMyBuyingScroll)
      ..dispose();
    _recordScroll
      ..removeListener(_handleRecordScroll)
      ..dispose();
    _mySearchController.removeListener(_handleSearchTextChange);
    _recordSearchController.removeListener(_handleSearchTextChange);
    _mySearchController.dispose();
    _recordSearchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    final nextIndex = _tabController.index;
    if (!mounted || _currentTabIndex == nextIndex) {
      return;
    }
    setState(() => _currentTabIndex = nextIndex);
  }

  void _handleSearchTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMyBuyingScroll() {
    if (_myBuyingScroll.position.pixels >
        _myBuyingScroll.position.maxScrollExtent - 200) {
      controller.loadMyBuying();
    }
  }

  void _handleRecordScroll() {
    if (_recordScroll.position.pixels >
        _recordScroll.position.maxScrollExtent - 200) {
      controller.loadBuyRecords();
    }
  }

  ShopSchemaInfo? _lookupSchema(BuyRequestItem item) {
    final key = item.schemaId?.toString();
    if (key != null && controller.schemas.containsKey(key)) {
      return controller.schemas[key];
    }
    return null;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '-';
    }
    var ts = timestamp;
    if (ts < 10000000000) {
      ts *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  Future<void> _switchGame(int appId) async {
    if (appId == GameStorage.getGameType()) {
      return;
    }
    await GameStorage.setGameType(appId);
    if (mounted) {
      setState(() => _currentAppId = appId);
    }
    await MarketFilterSheet.preload(appId: appId);
    controller.refreshMyBuying();
    controller.refreshBuyRecords();
  }

  void _showOfflineTips() {
    Get.snackbar(
      'app.system.tips.title'.tr,
      'app.trade.purchase.offline_tips'.tr,
    );
  }

  bool get _isMyBuyingTab => _currentTabIndex == 0;

  TextEditingController get _activeSearchController =>
      _isMyBuyingTab ? _mySearchController : _recordSearchController;

  ValueChanged<String> get _activeSearchSubmit =>
      _isMyBuyingTab ? controller.searchMyBuying : controller.searchRecords;

  Future<void> _submitActiveSearch() {
    if (_isMyBuyingTab) {
      return controller.searchMyBuying(_mySearchController.text);
    }
    return controller.searchRecords(_recordSearchController.text);
  }

  double? _parseFilterPrice(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  String _formatFilterPrice(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Map<String, dynamic> _normalizeFilterTags(Map<String, dynamic> source) {
    final tags = Map<String, dynamic>.from(source)
      ..removeWhere((key, value) => value == null || value.toString().isEmpty);
    return tags;
  }

  Map<String, dynamic> _attributeFilterTags(Map<String, dynamic> source) {
    final tags = _normalizeFilterTags(source);
    tags.remove('priceMin');
    tags.remove('priceMax');
    return tags;
  }

  Map<String, dynamic> _mergePriceRangeIntoTags({
    required Map<String, dynamic>? tags,
    double? priceMin,
    double? priceMax,
  }) {
    final merged = _normalizeFilterTags(tags ?? const {});
    if (priceMin == null) {
      merged.remove('priceMin');
    } else {
      merged['priceMin'] = _formatFilterPrice(priceMin);
    }
    if (priceMax == null) {
      merged.remove('priceMax');
    } else {
      merged['priceMax'] = _formatFilterPrice(priceMax);
    }
    return merged;
  }

  bool _hasMyBuyingFilter() {
    if (controller.buyingSortAsc.value || controller.isBuyingSortByPrice) {
      return true;
    }
    if (controller.buyingItemName.value?.isNotEmpty == true) {
      return true;
    }
    return controller.buyingTags.isNotEmpty;
  }

  bool _hasRecordFilter() {
    if (controller.recordSortAsc.value) {
      return true;
    }
    if (controller.recordItemName.value?.isNotEmpty == true) {
      return true;
    }
    return controller.recordTags.isNotEmpty;
  }

  Future<void> _openMyBuyingFilterSheet() async {
    final currentTags = _normalizeFilterTags(controller.buyingTags);
    final result = await OrderFilterSheet.showFromRight(
      context: context,
      initial: OrderFilterResult(
        sortAsc: controller.buyingSortAsc.value,
        sortField: controller.buyingSortField,
        priceMin: _parseFilterPrice(currentTags['priceMin']),
        priceMax: _parseFilterPrice(currentTags['priceMax']),
        tags: _attributeFilterTags(currentTags),
        itemName: controller.buyingItemName.value,
      ),
      statusOptions: const [],
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'upTime'),
        SortOption(labelKey: 'app.market.filter.price', field: 'price'),
      ],
      showSort: true,
      showStatus: false,
      showDateRange: false,
      enableAttributeFilter: true,
      attributeShowPriceRange: true,
      appId: _currentAppId,
      sectionOrder: const [
        OrderFilterSectionCategory.sort,
        OrderFilterSectionCategory.price,
        OrderFilterSectionCategory.attribute,
      ],
    );
    if (result != null) {
      final mergedTags = _mergePriceRangeIntoTags(
        tags: result.tags,
        priceMin: result.priceMin,
        priceMax: result.priceMax,
      );
      await controller.applyMyBuyingFilter(
        sortAsc: result.reset ? false : result.sortAsc,
        sortField: result.reset ? 'upTime' : result.sortField,
        tags: result.reset ? const <String, dynamic>{} : mergedTags,
        itemName: result.reset ? '' : result.itemName,
      );
    }
  }

  Future<void> _openRecordFilterSheet() async {
    final currentTags = _normalizeFilterTags(controller.recordTags);
    final result = await OrderFilterSheet.showFromRight(
      context: context,
      initial: OrderFilterResult(
        sortAsc: controller.recordSortAsc.value,
        sortField: 'time',
        tags: currentTags,
        itemName: controller.recordItemName.value,
      ),
      statusOptions: const [],
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      showSort: true,
      showStatus: false,
      showDateRange: false,
      enableAttributeFilter: true,
      appId: _currentAppId,
      sectionOrder: const [
        OrderFilterSectionCategory.sort,
        OrderFilterSectionCategory.attribute,
      ],
    );
    if (result != null) {
      await controller.applyRecordFilter(
        sortAsc: result.reset ? false : result.sortAsc,
        tags: result.reset ? const <String, dynamic>{} : result.tags,
        itemName: result.reset ? '' : result.itemName,
      );
    }
  }

  Widget _buildActiveFilterButton() {
    if (_isMyBuyingTab) {
      return _buildSearchActionButton(
        tooltip: 'app.market.filter.text'.tr,
        icon: Icons.filter_alt_outlined,
        onTap: _openMyBuyingFilterSheet,
        active: _hasMyBuyingFilter(),
      );
    }
    return _buildSearchActionButton(
      tooltip: 'app.market.filter.text'.tr,
      icon: Icons.filter_alt_outlined,
      onTap: _openRecordFilterSheet,
      active: _hasRecordFilter(),
    );
  }

  String? _rawText(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null) {
        return value.toString();
      }
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

  Widget _buildSearchActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final background = active
        ? colors.primary.withValues(alpha: 0.12)
        : baseBackground;
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

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final hintColor = isDark ? Colors.white38 : colors.onSurfaceVariant;
    final controller = _activeSearchController;
    final hasKeyword = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                  onSubmitted: _activeSearchSubmit,
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
                              _activeSearchSubmit('');
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
            onTap: _submitActiveSearch,
          ),
          const SizedBox(width: 6),
          _buildActiveFilterButton(),
        ],
      ),
    );
  }

  Widget _buildSharedTopSection() {
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
              splashBorderRadius: BorderRadius.circular(16),
              tabs: [
                Tab(height: 30, text: 'app.user.menu.purchase'.tr),
                Tab(height: 30, text: 'app.trade.purchase.record'.tr),
              ],
            ),
          ),
          Obx(() => _buildSearchBar()),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(BuyRequestItem item) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.received ?? 0}/${item.nums ?? 0}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecordStatusBadge(BuyRequestItem item) {
    final colors = Theme.of(context).colorScheme;
    final isSuccess = item.status == 1;
    final bgColor = isSuccess
        ? colors.tertiary.withValues(alpha: 0.14)
        : colors.surfaceContainerHighest;
    final fgColor = isSuccess ? colors.tertiary : colors.onSurfaceVariant;
    final text = item.statusName?.trim().isNotEmpty == true
        ? item.statusName!.trim()
        : '-';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyRequestSummary(BuyRequestItem item, ShopSchemaInfo? schema) {
    final currency = Get.find<CurrencyController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title =
        schema?.marketName ??
        schema?.marketHashName ??
        item.raw['market_name']?.toString() ??
        '-';
    final wearMin =
        _rawText(item.raw, const ['paint_wear_min', 'paintWearMin']) ??
        item.paintWearMin?.toString();
    final wearMax =
        _rawText(item.raw, const ['paint_wear_max', 'paintWearMax']) ??
        item.paintWearMax?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          height: 43,
          child: GameItemImage(
            imageUrl: schema?.imageUrl,
            appId: item.appId,
            rarity: _schemaTag(schema, 'rarity'),
            quality: _schemaTag(schema, 'quality'),
            exterior: _schemaTag(schema, 'exterior'),
            count: (item.count ?? 1) > 1 ? item.count : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (wearMin != null && wearMax != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${'app.market.csgo.wear'.tr}: $wearMin - $wearMax',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (item.phase?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${'app.market.csgo.phase'.tr}: ${item.phase}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Obx(
                  () => Text(
                    currency.format(item.price ?? 0),
                    textAlign: TextAlign.end,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _buildActionButtonStyle({required bool outlined}) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600);
    if (outlined) {
      return OutlinedButton.styleFrom(
        minimumSize: const Size(92, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: textStyle,
      );
    }
    return FilledButton.styleFrom(
      minimumSize: const Size(92, 34),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = UserStorage.getUserInfo() != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('app.trade.purchase.text'.tr),
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
          if (isLoggedIn)
            Obx(() {
              final isOnline = controller.purchaseOnline.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: () => Get.toNamed(Routers.PURCHASE_SETTING),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
      body: Column(
        children: [
          _buildSharedTopSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMyBuyingTab(), _buildRecordTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBuyingTab() {
    return Obx(() {
      if (controller.isLoadingMyBuying.value && controller.myBuying.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.myBuying.isEmpty) {
        return Center(child: Text('app.common.no_data'.tr));
      }
      final showLoadingFooter =
          controller.isLoadingMyBuying.value && controller.myBuying.isNotEmpty;
      final showNoMoreFooter =
          controller.myBuying.isNotEmpty &&
          !controller.isLoadingMyBuying.value &&
          !controller.myBuyingHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;

      return ListView.separated(
        controller: _myBuyingScroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: controller.myBuying.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= controller.myBuying.length) {
            return _buildLoadMoreFooter(
              showLoading: showLoadingFooter,
              showNoMore: showNoMoreFooter,
            );
          }
          final item = controller.myBuying[index];
          final schema = _lookupSchema(item);
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTime(item.upTime ?? item.createTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      _buildProgressBadge(item),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBuyRequestSummary(item, schema),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 34,
                        child: FilledButton.tonal(
                          onPressed: () async {
                            if (!controller.purchaseOnline.value) {
                              _showOfflineTips();
                              return;
                            }
                            final result = await Get.toNamed(
                              Routers.BUYING_UPDATE_PRICE,
                              arguments: {
                                'item': item.raw,
                                'schema': schema?.raw,
                              },
                            );
                            if (result == true) {
                              await controller.refreshMyBuying();
                            }
                          },
                          style: _buildActionButtonStyle(outlined: false),
                          child: Text('app.inventory.price_change'.tr),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () async {
                            if (!controller.purchaseOnline.value) {
                              _showOfflineTips();
                              return;
                            }
                            final id = item.id?.toString();
                            if (id == null) {
                              return;
                            }
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: Text('app.system.tips.title'.tr),
                                content: Text(
                                  'app.trade.purchase.message.confirm_terminate'
                                      .tr,
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
                            if (confirm == true) {
                              await controller.cancelBuy(id);
                              Get.snackbar(
                                'app.system.tips.title'.tr,
                                'app.system.message.success'.tr,
                              );
                            }
                          },
                          style: _buildActionButtonStyle(outlined: true),
                          child: Text('app.trade.purchase.terminate'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildRecordTab() {
    return Obx(() {
      if (controller.isLoadingRecords.value && controller.buyRecords.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.buyRecords.isEmpty) {
        return Center(child: Text('app.common.no_data'.tr));
      }
      final showLoadingFooter =
          controller.isLoadingRecords.value && controller.buyRecords.isNotEmpty;
      final showNoMoreFooter =
          controller.buyRecords.isNotEmpty &&
          !controller.isLoadingRecords.value &&
          !controller.recordHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;

      return ListView.separated(
        controller: _recordScroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: controller.buyRecords.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= controller.buyRecords.length) {
            return _buildLoadMoreFooter(
              showLoading: showLoadingFooter,
              showNoMore: showNoMoreFooter,
            );
          }
          final item = controller.buyRecords[index];
          final schema = _lookupSchema(item);
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTime(item.upTime ?? item.createTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      _buildRecordStatusBadge(item),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBuyRequestSummary(item, schema),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${item.received ?? 0}/${item.nums ?? 0}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
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
