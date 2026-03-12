import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/filter/order_filter_sheet.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
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
  static const double _loadMoreThreshold = 200;
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

  bool _shouldLoadMore(ScrollController scrollController) {
    if (!scrollController.hasClients) {
      return false;
    }
    final position = scrollController.position;
    if (position.outOfRange) {
      return false;
    }
    return position.extentAfter <= _loadMoreThreshold;
  }

  void _handleMyBuyingScroll() {
    if (!_shouldLoadMore(_myBuyingScroll) ||
        controller.isLoadingMyBuying.value ||
        !controller.myBuyingHasMore) {
      return;
    }
    controller.loadMyBuying();
  }

  void _handleRecordScroll() {
    if (!_shouldLoadMore(_recordScroll) ||
        controller.isLoadingRecords.value ||
        !controller.recordHasMore) {
      return;
    }
    controller.loadBuyRecords();
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

  Future<void> _openBuyingPriceChange(
    BuyRequestItem item,
    ShopSchemaInfo? schema,
  ) async {
    if (!controller.purchaseOnline.value) {
      _showOfflineTips();
      return;
    }
    final result = await Get.toNamed(
      Routers.BUYING_UPDATE_PRICE,
      arguments: {'item': item.raw, 'schema': schema?.raw},
    );
    if (result == true) {
      await controller.refreshMyBuying();
    }
  }

  Future<void> _confirmTerminateBuying(BuyRequestItem item) async {
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
        content: Text('app.trade.purchase.message.confirm_terminate'.tr),
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
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.success'.tr);
    }
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
                      Tab(height: 30, text: 'app.user.menu.purchase'.tr),
                      Tab(height: 30, text: 'app.trade.purchase.record'.tr),
                    ],
                  ),
                );
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.received ?? 0}/${item.nums ?? 0}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildRecordStatusText(BuyRequestItem item) {
    final colors = Theme.of(context).colorScheme;
    final isSuccess = item.status == 1;
    const buyingOrange = Color(0xFFFFA500);
    final text = item.statusName?.trim().isNotEmpty == true
        ? item.statusName!.trim()
        : '-';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isSuccess ? buyingOrange : colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
  }

  Widget _buildSummaryMetaText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBuyRequestSummary(BuyRequestItem item, ShopSchemaInfo? schema) {
    final currency = Get.find<CurrencyController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const imageHeight = 62.0;
    const imageAspectRatio = 72 / 43;
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
    final metaLines = <String>[
      if (wearMin != null && wearMax != null)
        '${'app.market.csgo.wear'.tr}: $wearMin - $wearMax',
      if (item.phase?.isNotEmpty == true)
        '${'app.market.csgo.phase'.tr}: ${item.phase}',
    ];
    final metaText = metaLines.join('  ·  ');
    final imageWidth = imageHeight * imageAspectRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: imageWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(9),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: GameItemImage(
              imageUrl: schema?.imageUrl,
              appId: item.appId,
              rarity: _schemaTag(schema, 'rarity'),
              quality: _schemaTag(schema, 'quality'),
              exterior: _schemaTag(schema, 'exterior'),
              count: (item.count ?? 1) > 1 ? item.count : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (metaText.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildSummaryMetaText(metaText),
              ],
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  currency.format(item.price ?? 0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionLabel(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  ButtonStyle _buildPrimaryActionButtonStyle() {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    return OutlinedButton.styleFrom(
      minimumSize: const Size(84, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      foregroundColor: colors.primary,
      side: BorderSide(color: colors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: textStyle,
    );
  }

  ButtonStyle _buildDangerActionButtonStyle() {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    return OutlinedButton.styleFrom(
      minimumSize: const Size(84, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: colors.error),
      foregroundColor: colors.error,
      textStyle: textStyle,
    );
  }

  Widget _buildMyBuyingTrailingActions(
    BuyRequestItem item,
    ShopSchemaInfo? schema,
  ) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openBuyingPriceChange(item, schema),
              style: _buildPrimaryActionButtonStyle(),
              child: _buildCompactActionLabel('app.inventory.price_change'.tr),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmTerminateBuying(item),
              style: _buildDangerActionButtonStyle(),
              child: _buildCompactActionLabel(
                'app.trade.purchase.terminate'.tr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTrailingInfo(BuyRequestItem item) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 74,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildRecordStatusText(item),
                const SizedBox(height: 6),
                Text(
                  '${item.received ?? 0}/${item.nums ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTimestamp(int? time) {
    return Text(
      _formatTime(time),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.1,
      ),
    );
  }

  Widget _buildMyBuyingItem(BuyRequestItem item) {
    final schema = _lookupSchema(item);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildItemTimestamp(item.upTime ?? item.createTime),
                ),
                _buildProgressBadge(item),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildBuyRequestSummary(item, schema)),
                const SizedBox(width: 10),
                _buildMyBuyingTrailingActions(item, schema),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(BuyRequestItem item) {
    final schema = _lookupSchema(item);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemTimestamp(item.upTime ?? item.createTime),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildBuyRequestSummary(item, schema)),
                const SizedBox(width: 10),
                _buildRecordTrailingInfo(item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = UserStorage.getUserInfo() != null;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.menu.purchase'.tr),
        actions: [
          if (isLoggedIn)
            Obx(() {
              final isOnline = controller.purchaseOnline.value;
              return _buildTopActionWithDot(
                visible: true,
                dotColor: isOnline
                    ? const Color(0xFF22C55E)
                    : colors.outlineVariant,
                child: _buildTopIconAction(
                  icon: Icons.settings,
                  tooltip: 'app.trade.purchase.setting'.tr,
                  onTap: () => Get.toNamed(Routers.PURCHASE_SETTING),
                ),
              );
            }),
          if (isLoggedIn) const SizedBox(width: 6),
          Builder(
            builder: (iconContext) {
              return GameIconButton(
                appId: _currentAppId,
                size: 34,
                onTap: () async {
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
          const SizedBox(width: 6),
        ],
      ),
      body: BackToTopScope(
        enabled: false,
        child: Column(
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
      ),
    );
  }

  Widget _buildMyBuyingTab() {
    return Obx(() {
      if (controller.isLoadingMyBuying.value && controller.myBuying.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.myBuying.isEmpty) {
        return _buildPullToRefreshEmpty(onRefresh: controller.refreshMyBuying);
      }
      final showLoadingFooter =
          controller.isLoadingMyBuying.value && controller.myBuying.isNotEmpty;
      final showNoMoreFooter =
          controller.myBuying.isNotEmpty &&
          !controller.isLoadingMyBuying.value &&
          !controller.myBuyingHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;

      return BackToTopScope(
        enabled: true,
        child: RefreshIndicator(
          onRefresh: controller.refreshMyBuying,
          child: ListView.separated(
            controller: _myBuyingScroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: controller.myBuying.length + (showFooter ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= controller.myBuying.length) {
                return _buildLoadMoreFooter(
                  showLoading: showLoadingFooter,
                  showNoMore: showNoMoreFooter,
                );
              }
              final item = controller.myBuying[index];
              return _buildMyBuyingItem(item);
            },
          ),
        ),
      );
    });
  }

  Widget _buildRecordTab() {
    return Obx(() {
      if (controller.isLoadingRecords.value && controller.buyRecords.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.buyRecords.isEmpty) {
        return _buildPullToRefreshEmpty(
          onRefresh: controller.refreshBuyRecords,
        );
      }
      final showLoadingFooter =
          controller.isLoadingRecords.value && controller.buyRecords.isNotEmpty;
      final showNoMoreFooter =
          controller.buyRecords.isNotEmpty &&
          !controller.isLoadingRecords.value &&
          !controller.recordHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;

      return BackToTopScope(
        enabled: true,
        child: RefreshIndicator(
          onRefresh: controller.refreshBuyRecords,
          child: ListView.separated(
            controller: _recordScroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: controller.buyRecords.length + (showFooter ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= controller.buyRecords.length) {
                return _buildLoadMoreFooter(
                  showLoading: showLoadingFooter,
                  showNoMore: showNoMoreFooter,
                );
              }
              final item = controller.buyRecords[index];
              return _buildRecordItem(item);
            },
          ),
        ),
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
