import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/components/market/price_trend_chart.dart';
import 'package:tronskins_app/controllers/market/market_detail_controller.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/common/widgets/steam_style_confirm_dialog.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class MarketDetailPage extends StatefulWidget {
  const MarketDetailPage({super.key});

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage>
    with TickerProviderStateMixin {
  static const double _bottomActionButtonHeight = 42;
  static const double _bottomActionCompactBreakpoint = 390;
  static const double _topActionToolbarMaxHeight = 48;
  final MarketDetailController controller = Get.put(MarketDetailController());
  final ApiMarketServer _marketApi = ApiMarketServer();
  final ApiShopServer _shopServer = ApiShopServer();
  final ApiShopProductServer _shopProductApi = ApiShopProductServer();
  late final TabController _tabController;
  int _currentTabIndex = 0;
  int _selectedDays = 30;
  MarketTemplateDetail? _templateDetail;
  bool _loadingTemplate = false;
  bool _steamPriceResolved = false;
  List<_WearOption> _wearOptions = <_WearOption>[];
  List<String> _qualityKeys = <String>[];
  int _qualityIndex = 0;
  double? _onSaleMinPrice;
  double? _onSaleMaxPrice;
  String? _onSalePaintSeed;
  int? _onSalePaintIndex;
  double? _onSaleWearMin;
  double? _onSaleWearMax;
  String? _onSaleSortField;
  bool? _onSaleSortAsc;
  final Set<String> _onSalePurchasingIds = <String>{};
  bool _collectionSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.animation?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _tabController.addListener(() {
      final nextIndex = _tabController.index;
      if (nextIndex != _currentTabIndex && mounted) {
        setState(() => _currentTabIndex = nextIndex);
      }
    });
    Future.microtask(_loadTemplate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _onSalePurchaseKey(MarketListItem item) {
    final id = item.id?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final rawId = item.raw['id']?.toString();
    if (rawId != null && rawId.isNotEmpty) {
      return rawId;
    }
    return null;
  }

  MarketSchemaInfo? _lookupMarketSchema(MarketListItem item) {
    final key = item.schemaId?.toString();
    if (key != null && controller.schemas.containsKey(key)) {
      return controller.schemas[key];
    }
    final hash = item.marketHashName;
    if (hash != null && controller.schemas.containsKey(hash)) {
      return controller.schemas[hash];
    }
    return null;
  }

  String _resolveAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return '';
    }
    if (avatar.startsWith('http')) {
      return avatar;
    }
    return 'https://www.tronskins.com/fms/image$avatar';
  }

  Future<void> _openBuying() async {
    final user = UserStorage.getUserInfo();
    if (user == null) {
      AppSnackbar.info('app.system.message.nologin'.tr);
      return;
    }
    final uuid = user.uuid ?? user.shop?.uuid;
    if (uuid != null && uuid.isNotEmpty) {
      try {
        final res = await _shopServer.getUserShopInfo(params: {'uuid': uuid});
        if (res.success && res.datas != null) {
          if (res.datas?['signWanted'] != true) {
            AppSnackbar.info('app.trade.purchase.offline_tips'.tr);
            return;
          }
        }
      } catch (_) {}
    }
    final schemaId = controller.schemaId;
    if (schemaId == null) {
      return;
    }
    final result = await Get.toNamed(
      Routers.PRODUCT_BUYING,
      arguments: {'appId': controller.appId, 'schemaId': schemaId},
    );
    if (result == true) {
      await controller.loadBuyRequests(reset: true);
    }
  }

  Future<void> _openBulkBuying() async {
    final user = UserStorage.getUserInfo();
    if (user == null) {
      AppSnackbar.info('app.system.message.nologin'.tr);
      return;
    }
    final schemaId = controller.schemaId;
    if (schemaId == null) {
      return;
    }
    final result = await Get.toNamed(
      Routers.BULK_BUYING,
      arguments: {'appId': controller.appId, 'schemaId': schemaId},
    );
    if (result == true) {
      await controller.loadOnSale(reset: true);
      await controller.loadTransactions(reset: true);
    }
  }

  Future<void> _loadTemplate({int? schemaId}) async {
    if (_loadingTemplate) {
      return;
    }
    final appId = controller.appId;
    final targetId = schemaId ?? controller.schemaId;
    if (targetId == null) {
      if (mounted && !_steamPriceResolved) {
        setState(() => _steamPriceResolved = true);
      }
      return;
    }
    setState(() => _loadingTemplate = true);
    try {
      final useAuth = UserStorage.getUserInfo() != null;
      final res = await _marketApi.marketTemplateDetail(
        appId: appId,
        schemaId: targetId,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
      );
      final detail = res.datas;
      if (detail == null) {
        return;
      }
      _templateDetail = detail;
      _buildWearOptions(detail);
      final schema = detail.schema;
      if (schema != null) {
        final mappedItem = _mapTemplateToItem(schema);
        final mappedSchemaId = mappedItem.schemaId ?? mappedItem.id;
        final currentSchemaId = controller.schemaId;
        final mappedAppId = mappedItem.appId ?? controller.appId;
        final mappedHash =
            mappedItem.marketHashName ?? mappedItem.marketName ?? '';
        final currentHash = controller.marketHashName;
        final shouldRefreshList =
            mappedSchemaId != currentSchemaId ||
            mappedAppId != controller.appId ||
            (mappedHash.isNotEmpty && mappedHash != currentHash);
        if (shouldRefreshList) {
          controller.updateItem(mappedItem);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTemplate = false;
          _steamPriceResolved = true;
        });
      } else {
        _steamPriceResolved = true;
      }
    }
  }

  void _buildWearOptions(MarketTemplateDetail detail) {
    _wearOptions = <_WearOption>[];
    _qualityKeys = <String>[];
    _qualityIndex = 0;
    if (detail.schema?.appId != 730) {
      return;
    }
    final qualityMap = detail.qualityMap;
    if (qualityMap == null) {
      return;
    }
    final keys = qualityMap.keys.toList();
    if (keys.isEmpty) {
      return;
    }
    _qualityKeys = keys;
    final qualityName = detail.schema?.tags?.quality?.localizedName;
    final index = qualityName == null ? -1 : keys.indexOf(qualityName);
    _qualityIndex = index >= 0 ? index : 0;
    final selectedKey = _qualityKeys[_qualityIndex];
    _wearOptions = _parseWearOptions(qualityMap[selectedKey]);
  }

  Future<void> _cycleQualityKey() async {
    if (_loadingTemplate || _qualityKeys.length < 2) {
      return;
    }
    final qualityMap = _templateDetail?.qualityMap;
    if (qualityMap == null) {
      return;
    }
    final nextIndex = (_qualityIndex + 1) % _qualityKeys.length;
    final targetKey = _qualityKeys[nextIndex];
    final targetOptions = _parseWearOptions(qualityMap[targetKey]);
    if (targetOptions.isEmpty) {
      setState(() {
        _qualityIndex = nextIndex;
        _wearOptions = targetOptions;
      });
      return;
    }
    final currentExteriorLabel = _templateDetail
        ?.schema
        ?.tags
        ?.exterior
        ?.localizedName
        ?.trim();
    final matchedOption =
        _matchWearOptionByExterior(targetOptions, currentExteriorLabel) ??
        targetOptions.first;
    await _selectWear(matchedOption.id);
  }

  Widget _buildMarketCountSummary({
    required BuildContext context,
    required int? sellNum,
    required int? buyNum,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = sellNum != null || buyNum != null;
    if (!visible && !_loadingTemplate) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (child.key == const ValueKey('market_count_summary_visible')) {
          return ClipRect(
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.22, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        }
        return child;
      },
      child: visible
          ? Padding(
              key: const ValueKey('market_count_summary_visible'),
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.28,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMarketCountTile(
                        context: context,
                        icon: Icons.local_offer_outlined,
                        label: 'app.trade.onSale.text'.tr,
                        value: '${sellNum ?? 0}${'app.market.unit_qty'.tr}',
                        accent: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMarketCountTile(
                        context: context,
                        icon: Icons.shopping_bag_outlined,
                        label: 'app.trade.purchase.text'.tr,
                        value: '${buyNum ?? 0}${'app.market.unit_qty'.tr}',
                        accent: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              key: const ValueKey('market_count_summary_loading'),
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.28,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMarketCountTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSteamPrice({
    required BuildContext context,
    required CurrencyController currency,
    required double referencePrice,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steamLabel = 'app.market.detail.steam_price'.tr;
    if (!_steamPriceResolved) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 68,
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            steamLabel,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(
          () => Text(
            currency.format(referencePrice),
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          steamLabel,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _selectWear(int schemaId) async {
    await _loadTemplate(schemaId: schemaId);
  }

  Future<void> _toggleCollection() async {
    if (_collectionSubmitting) {
      return;
    }
    if (UserStorage.getUserInfo() == null) {
      await Get.toNamed(Routers.LOGIN);
      return;
    }
    final schemaId = controller.schemaId ?? _templateDetail?.schema?.schemaId;
    if (schemaId == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }
    final isCollected = _templateDetail?.isCollected == true;
    setState(() => _collectionSubmitting = true);
    try {
      final res = isCollected
          ? await _marketApi.removeCollection(schemaId: schemaId)
          : await _marketApi.addCollection(
              appId: controller.appId,
              schemaId: schemaId,
            );
      if (!res.success) {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      final detail = _templateDetail;
      if (detail != null) {
        _templateDetail = MarketTemplateDetail(
          schema: detail.schema,
          qualityMap: detail.qualityMap,
          paintKits: detail.paintKits,
          isCollected: !isCollected,
        );
      }
      if (mounted) {
        setState(() {});
      }
      AppSnackbar.success(
        (!isCollected
                ? 'app.user.collection.message.success'
                : 'app.user.collection.uncollect_success')
            .tr,
      );
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _collectionSubmitting = false);
      }
    }
  }

  List<_WearOption> _parseWearOptions(dynamic raw) {
    if (raw is! List) {
      return <_WearOption>[];
    }
    final options = <_WearOption>[];
    for (final item in raw) {
      if (item is Map) {
        final id = _asInt(item['id']);
        final label = item['label']?.toString();
        final price = item['price'];
        if (id != null && label != null) {
          options.add(_WearOption(id: id, label: label, price: price));
        }
      }
    }
    return options;
  }

  _WearOption? _matchWearOptionByExterior(
    List<_WearOption> options,
    String? exteriorLabel,
  ) {
    final normalizedExterior = _normalizeWearLabel(exteriorLabel);
    if (normalizedExterior == null) {
      return null;
    }
    for (final option in options) {
      final normalizedLabel = _normalizeWearLabel(option.label);
      if (normalizedLabel == null) {
        continue;
      }
      if (normalizedLabel.contains(normalizedExterior) ||
          normalizedExterior.contains(normalizedLabel)) {
        return option;
      }
    }
    return null;
  }

  String? _normalizeWearLabel(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  MarketItemEntity _mapTemplateToItem(MarketTemplateSchema schema) {
    return MarketItemEntity(
      id: schema.schemaId,
      schemaId: schema.schemaId,
      appId: schema.appId,
      marketName: schema.marketName,
      marketHashName: schema.marketHashName,
      imageUrl: schema.imageUrl,
      marketPrice: schema.referencePrice,
      sellNum: schema.sellNum,
      tags: schema.tags,
    );
  }

  Widget _buildTopNavButton({
    required Widget child,
    required VoidCallback? onPressed,
    required bool collapsed,
    required bool isDark,
    String? tooltip,
  }) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = collapsed
        ? (isDark
              ? const Color(0xFF2A2C31).withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.96))
        : Colors.black.withValues(alpha: isDark ? 0.24 : 0.18);
    final borderColor = collapsed
        ? colors.outline.withValues(alpha: isDark ? 0.18 : 0.12)
        : Colors.white.withValues(alpha: 0.12);
    final shadowColor = Colors.black.withValues(
      alpha: collapsed ? (isDark ? 0.24 : 0.10) : 0.14,
    );

    final button = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: collapsed ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );

    final wrapped = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: button,
    );
    if (tooltip == null || tooltip.isEmpty) {
      return wrapped;
    }
    return Tooltip(message: tooltip, child: wrapped);
  }

  @override
  Widget build(BuildContext context) {
    final item = controller.item;
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final templateSchema = _templateDetail?.schema;
    final displayTags = templateSchema?.tags ?? item.tags;
    final displayName = templateSchema?.marketName ?? item.marketName ?? '';
    final displayImage = templateSchema?.imageUrl ?? item.imageUrl ?? '';
    final referencePrice =
        templateSchema?.referencePrice ?? item.marketPrice ?? 0;
    final sellNum = templateSchema?.sellNum;
    final buyNum = templateSchema?.buyNum;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1B1C20)
          : const Color(0xFFF5F5F5),
      bottomNavigationBar: _buildBottomActionBar(
        currency: currency,
        referencePrice: referencePrice,
        isDark: isDark,
      ),
      body: BackToTopScope(
        enabled: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            final tabBar = TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'app.trade.onSale.text'.tr),
                Tab(text: 'app.trade.purchase.text'.tr),
                Tab(text: 'app.market.detail.price_trend.title'.tr),
                Tab(text: 'app.market.detail.trade_record'.tr),
              ],
            );
            final collapsed = innerBoxIsScrolled;
            final navIconColor = isDark
                ? Colors.white
                : (collapsed ? colorScheme.onSurface : Colors.white);
            final overlayStyle = isDark
                ? SystemUiOverlayStyle.light
                : (collapsed
                      ? SystemUiOverlayStyle.dark
                      : SystemUiOverlayStyle.light);
            return [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: isDark
                    ? const Color(0xFF1B1C20)
                    : Colors.white,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: collapsed ? (isDark ? 0 : 1) : 0,
                shadowColor: Colors.black.withValues(
                  alpha: collapsed && !isDark ? 0.08 : 0,
                ),
                systemOverlayStyle: overlayStyle,
                titleSpacing: 0,
                title: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Tronskins',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
                leadingWidth: 56,
                leading: _buildTopNavButton(
                  collapsed: collapsed,
                  isDark: isDark,
                  onPressed: () => Get.back(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  child: Icon(Icons.arrow_back, color: navIconColor, size: 20),
                ),
                actions: [
                  _buildTopNavButton(
                    collapsed: collapsed,
                    isDark: isDark,
                    onPressed: _collectionSubmitting ? null : _toggleCollection,
                    tooltip: _templateDetail?.isCollected == true
                        ? 'app.user.collection.uncollect'.tr
                        : null,
                    child: _collectionSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: navIconColor,
                            ),
                          )
                        : Icon(
                            _templateDetail?.isCollected == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: navIconColor,
                            size: 20,
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background based on rarity
                      Image.asset(
                        _rarityBgAsset(displayTags?.rarity?.color),
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Image.asset(
                          'assets/images/game/item/b0c3d9.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Main Image
                      Center(
                        child: Hero(
                          tag: 'market_item_${item.id}',
                          child: CachedNetworkImage(
                            imageUrl: displayImage,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF1B1C20) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildAttributeRows(item),
                      if (_wearOptions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildWearList(currency),
                      ],
                      _buildMarketCountSummary(
                        context: context,
                        sellNum: sellNum,
                        buyNum: buyNum,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  LayoutBuilder(
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
                          // Avoid getting stuck in an in-between offset state.
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
                          if (_tabController.indexIsChanging ||
                              dragWidth <= 0) {
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
                              _tabController.index <
                                  _tabController.length - 1) {
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
                        child: tabBar,
                      );
                    },
                  ),
                  height: tabBar.preferredSize.height,
                  backgroundColor: isDark
                      ? const Color(0xFF1B1C20)
                      : Colors.white,
                ),
                pinned: true,
              ),
              if (_topActionToolbarHeight > 0 || _showTopActionToolbar)
                SliverPersistentHeader(
                  delegate: _FixedHeightHeaderDelegate(
                    height: _topActionToolbarHeight,
                    backgroundColor: isDark
                        ? const Color(0xFF1B1C20)
                        : const Color(0xFFF5F5F5),
                    child: _buildTopActionToolbar(),
                  ),
                  pinned: true,
                ),
            ];
          },
          body: Container(
            color: isDark ? const Color(0xFF1B1C20) : const Color(0xFFF5F5F5),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOnSaleTab(currency),
                _buildBuyRequestTab(currency),
                _buildPriceTrendTab(),
                _buildTransactionTab(currency),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerScrollView({
    required BuildContext context,
    required String storageKey,
    required List<Widget> children,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return CustomScrollView(
      key: PageStorageKey<String>(storageKey),
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (children.isEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else
          SliverPadding(
            padding: padding,
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
      ],
    );
  }

  Widget _buildInnerFillRemaining({
    required BuildContext context,
    required String storageKey,
    required Widget child,
  }) {
    return CustomScrollView(
      key: PageStorageKey<String>(storageKey),
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
      ],
    );
  }

  Widget _buildBottomActionBar({
    required CurrencyController currency,
    required double referencePrice,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final releasePurchaseLabel = 'app.market.detail.release_purchase'.tr;
    final bulkBuyingLabel = 'app.market.detail.bulk_buying.title'.tr;
    final buttonTextStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    Widget buildActionButtons() {
      return SizedBox(
        height: _bottomActionButtonHeight,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openBuying,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: buttonTextStyle,
                ),
                child: Text(
                  releasePurchaseLabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _openBulkBuying,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: buttonTextStyle,
                ),
                child: Text(
                  bulkBuyingLabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26272B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useStackedLayout =
                constraints.maxWidth < _bottomActionCompactBreakpoint;
            final steamPrice = _buildBottomSteamPrice(
              context: context,
              currency: currency,
              referencePrice: referencePrice,
            );

            if (useStackedLayout) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  steamPrice,
                  const SizedBox(height: 6),
                  buildActionButtons(),
                ],
              );
            }

            return Row(
              children: [
                steamPrice,
                const SizedBox(width: 10),
                Expanded(child: buildActionButtons()),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget _buildInspectButton(IconData icon, String label) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withOpacity(0.15),
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, color: Colors.white, size: 16),
  //         const SizedBox(width: 4),
  //         Text(
  //           label,
  //           style: const TextStyle(color: Colors.white, fontSize: 12),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAttributeRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttributeRows(MarketItemEntity item) {
    final rows = <Widget>[];
    final paintSeed = _cleanText(item.paintSeed);
    final percentage = _cleanText(item.percentage);
    final paintIndex = _cleanText(item.paintIndex);
    final phase = _cleanText(item.phase);
    final tier = _cleanText(item.tier);
    final fireIce = _cleanText(item.fireIce);
    final paintWear = _cleanText(item.paintWear);

    final seedParts = <String>[];
    if (paintSeed != null) {
      seedParts.add(paintSeed);
    }
    if (percentage != null) {
      seedParts.add('(${_formatPercentage(percentage)})');
    }
    if (seedParts.isNotEmpty) {
      rows.add(
        _buildAttributeRow(
          'app.market.csgo.paint_index'.tr,
          seedParts.join(' '),
        ),
      );
    }

    final indexParts = <String>[];
    if (paintIndex != null) {
      indexParts.add(paintIndex);
    }
    if (phase != null) {
      indexParts.add('($phase)');
    }
    if (tier != null) {
      indexParts.add('($tier)');
    }
    if (fireIce != null) {
      indexParts.add('($fireIce)');
    }
    if (indexParts.isNotEmpty) {
      rows.add(
        _buildAttributeRow(
          'app.market.detail.skin_number'.tr,
          indexParts.join(' '),
        ),
      );
    }

    if (paintWear != null) {
      rows.add(
        _buildAttributeRow('app.market.csgo.abradability'.tr, paintWear),
      );
    }

    final attributeSection = _buildAttributeSection(item);
    if (attributeSection != null) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12));
      }
      rows.add(attributeSection);
    }

    return rows;
  }

  Widget? _buildAttributeSection(MarketItemEntity item) {
    final tags = item.tags;
    if (tags == null) {
      return null;
    }

    final exterior = _cleanText(tags.exterior?.localizedName);
    final itemSet = _cleanText(tags.itemSet?.localizedName);

    final tagList = _buildTagList(item);
    final hasTags = tagList.isNotEmpty;
    final hasExterior = exterior != null;
    final hasItemSet = itemSet != null;

    if (!hasTags && !hasExterior && !hasItemSet) {
      return null;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[300] : Colors.grey[700];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'app.market.detail.attribute'.tr,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (hasTags) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tagList
                .map((tag) => _buildTagChip(tag))
                .toList(growable: false),
          ),
        ],
        if (hasExterior) ...[
          const SizedBox(height: 8),
          Text(
            '${'app.market.filter.appearance'.tr}: $exterior',
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ],
        if (hasItemSet) ...[
          const SizedBox(height: 6),
          Text(itemSet, style: TextStyle(color: textColor, fontSize: 13)),
        ],
      ],
    );
  }

  List<_TagChipData> _buildTagList(MarketItemEntity item) {
    final tags = item.tags;
    if (tags == null) {
      return const [];
    }
    final isDota = item.appId == 570;
    final items = <_TagChipData>[];

    if (isDota) {
      _appendTag(items, tags.hero);
      _appendTag(items, tags.slot);
      _appendTag(items, tags.type);
    } else {
      _appendTag(items, tags.type);
      _appendTag(items, tags.rarity);
      _appendTag(items, tags.quality);
    }
    return items;
  }

  void _appendTag(List<_TagChipData> list, MarketItemTag? tag) {
    final name = _cleanText(tag?.localizedName);
    if (name == null) {
      return;
    }
    final color = _parseHex(tag?.color);
    list.add(_TagChipData(name, color));
  }

  Widget _buildTagChip(_TagChipData tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        tag.color ?? (isDark ? Colors.grey[300]! : Colors.grey[700]!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: baseColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        tag.text,
        style: TextStyle(
          color: baseColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) {
      return null;
    }
    final normalized = hex.replaceAll('#', '');
    if (normalized.length == 6) {
      return Color(int.parse('FF$normalized', radix: 16));
    }
    return null;
  }

  String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'null') {
      return null;
    }
    return trimmed;
  }

  String _formatPercentage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.endsWith('%') ? trimmed : '$trimmed%';
  }

  Widget _buildWearList(CurrencyController currency) {
    final exteriorLabel =
        _templateDetail?.schema?.tags?.exterior?.localizedName;
    final activeId = _templateDetail?.schema?.schemaId;
    final swapLabel = _qualityKeys.isNotEmpty
        ? _qualityKeys[(_qualityIndex + 1) % _qualityKeys.length]
        : null;

    final items = _wearOptions;
    final showSwap = _qualityKeys.length > 1;
    final totalCount = items.length + (showSwap ? 1 : 0);
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (showSwap && index == items.length) {
            return _buildWearChip(
              label: swapLabel ?? '',
              price: '',
              active: false,
              onTap: _cycleQualityKey,
              showSwap: true,
            );
          }
          final option = items[index];
          final isActive =
              option.label == exteriorLabel || option.id == activeId;
          return _buildWearChip(
            label: option.label,
            price: _formatWearPrice(option.price, currency),
            active: isActive,
            onTap: () => _selectWear(option.id),
          );
        },
      ),
    );
  }

  Widget _buildWearChip({
    required String label,
    required String price,
    required bool active,
    VoidCallback? onTap,
    bool showSwap = false,
  }) {
    final baseColor = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;
    final textColor = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyMedium?.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: baseColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (showSwap) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz, size: 14, color: textColor),
                ],
              ],
            ),
            if (price.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  price,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor?.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatWearPrice(dynamic price, CurrencyController currency) {
    if (price == null) {
      return '';
    }
    if (price is num) {
      return currency.format(price.toDouble());
    }
    final parsed = double.tryParse(price.toString());
    if (parsed != null) {
      return currency.format(parsed);
    }
    return '${currency.symbol} ${price.toString()}';
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

  String _formatI18nPlaceholder(String template, String value) {
    return template
        .replaceAll('{0}', value)
        .replaceAll('｛0｝', value)
        .replaceAll(r'${0}', value);
  }

  List<_OnSaleSortOption> _buildOnSaleSortOptions() {
    return const <_OnSaleSortOption>[
      _OnSaleSortOption(
        field: null,
        asc: null,
        labelKey: 'app.market.filter.sort',
      ),
      _OnSaleSortOption(
        field: 'hot',
        asc: true,
        labelKey: 'app.market.filter.hot_sorting',
        suffix: '↑',
      ),
      _OnSaleSortOption(
        field: 'hot',
        asc: false,
        labelKey: 'app.market.filter.hot_sorting',
        suffix: '↓',
      ),
      _OnSaleSortOption(
        field: 'price',
        asc: true,
        labelKey: 'app.market.filter.price_sorting',
        suffix: '↑',
      ),
      _OnSaleSortOption(
        field: 'price',
        asc: false,
        labelKey: 'app.market.filter.price_sorting',
        suffix: '↓',
      ),
    ];
  }

  String _formatOnSaleSortLabel(_OnSaleSortOption option) {
    final template = option.labelKey.tr;
    final suffix = option.suffix;
    if (suffix == null || suffix.isEmpty) {
      return template;
    }
    return _formatI18nPlaceholder(template, suffix);
  }

  Future<void> _applyOnSaleFilterWithCurrentState() {
    return controller.applyOnSaleFilter(
      sortField: _onSaleSortField,
      sortAsc: _onSaleSortAsc,
      minPrice: _onSaleMinPrice,
      maxPrice: _onSaleMaxPrice,
      paintSeed: _onSalePaintSeed,
      paintIndex: _onSalePaintIndex,
      paintWearMin: _onSaleWearMin,
      paintWearMax: _onSaleWearMax,
    );
  }

  Future<void> _refreshOnSaleList() async {
    if (controller.isLoadingOnSale.value) {
      return;
    }
    await _applyOnSaleFilterWithCurrentState();
  }

  Future<void> _refreshBuyRequestList() async {
    if (controller.isLoadingBuyRequests.value) {
      return;
    }
    await controller.loadBuyRequests(reset: true);
  }

  Future<void> _refreshTransactionList() async {
    if (controller.isLoadingTransactions.value) {
      return;
    }
    await controller.loadTransactions(reset: true);
  }

  Future<void> _refreshCurrentTabList() async {
    if (_currentTabIndex == 0) {
      await _refreshOnSaleList();
      return;
    }
    if (_currentTabIndex == 1) {
      await _refreshBuyRequestList();
      return;
    }
    if (_currentTabIndex == 3) {
      await _refreshTransactionList();
    }
  }

  double get _tabAnimationValue {
    final raw = _tabController.animation?.value ?? _currentTabIndex.toDouble();
    return raw.clamp(0.0, (_tabController.length - 1).toDouble()).toDouble();
  }

  double get _topActionToolbarProgress {
    final value = _tabAnimationValue;
    if (value <= 1.0) {
      return 1.0;
    }
    if (value <= 2.0) {
      return (2.0 - value).clamp(0.0, 1.0).toDouble();
    }
    return (value - 2.0).clamp(0.0, 1.0).toDouble();
  }

  double get _topActionToolbarHeight =>
      _topActionToolbarMaxHeight * _topActionToolbarProgress;

  bool get _showTopActionToolbar => _topActionToolbarHeight > 0.001;

  double get _topFilterButtonProgress {
    if (!_showOnSaleFilter) {
      return 0;
    }
    return (1.0 - _tabAnimationValue.abs()).clamp(0.0, 1.0).toDouble();
  }

  bool get _isToolbarInteractive => _topActionToolbarProgress > 0.98;

  bool get _isCurrentTabRefreshing {
    if (_currentTabIndex == 0) {
      return controller.isLoadingOnSale.value;
    }
    if (_currentTabIndex == 1) {
      return controller.isLoadingBuyRequests.value;
    }
    if (_currentTabIndex == 3) {
      return controller.isLoadingTransactions.value;
    }
    return false;
  }

  Widget _buildTopActionToolbar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final toolbarProgress = _topActionToolbarProgress;
    final barColor = isDark ? colors.surface : Colors.white;
    final baseButtonBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final filterButtonBackground = _hasOnSaleFilter
        ? colors.primary.withValues(alpha: 0.12)
        : baseButtonBackground;
    final iconColor = _hasOnSaleFilter
        ? colors.primary
        : colors.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      decoration: BoxDecoration(
        color: barColor,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: IgnorePointer(
        ignoring: !_isToolbarInteractive,
        child: Opacity(
          opacity: toolbarProgress,
          child: Row(
            children: [
              const Spacer(),
              Tooltip(
                message: 'app.common.refresh'.tr,
                child: Material(
                  color: baseButtonBackground,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      if (!_isToolbarInteractive || _isCurrentTabRefreshing) {
                        return;
                      }
                      _refreshCurrentTabList();
                    },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: colors.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: _topFilterButtonProgress,
                  child: IgnorePointer(
                    ignoring: _topFilterButtonProgress < 0.98,
                    child: Opacity(
                      opacity: _topFilterButtonProgress,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'app.market.filter.text'.tr,
                            child: Material(
                              color: filterButtonBackground,
                              borderRadius: BorderRadius.circular(9),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9),
                                onTap: () {
                                  if (controller.isLoadingOnSale.value) {
                                    return;
                                  }
                                  _openOnSaleFilterSheet();
                                },
                                onLongPress: () {
                                  if (controller.isLoadingOnSale.value ||
                                      !_hasOnSaleFilter) {
                                    return;
                                  }
                                  _clearOnSaleFilter();
                                },
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.filter_alt_outlined,
                                          color: iconColor,
                                          size: 18,
                                        ),
                                      ),
                                      if (_hasOnSaleFilter)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: colors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnSaleTab(CurrencyController currency) {
    return BackToTopScope(
      enabled: true,
      child: Obx(() {
        final isLoading = controller.isLoadingOnSale.value;
        final items = controller.onSaleItems.toList(growable: false);
        final users = Map<String, MarketUserInfo>.from(controller.users);
        final showLoadingFooter = isLoading && items.isNotEmpty;
        final showNoMoreFooter =
            items.isNotEmpty && !isLoading && !controller.onSaleHasMore;
        final showFooter = showLoadingFooter || showNoMoreFooter;

        return Builder(
          builder: (context) {
            if (isLoading && items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_on_sale_loading',
                child: const CircularProgressIndicator(),
              );
            }
            if (items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_on_sale_empty',
                child: Text('app.common.no_data'.tr),
              );
            }

            final children = <Widget>[];
            for (var index = 0; index < items.length; index++) {
              if (index > 0) {
                children.add(const SizedBox(height: 12));
              }
              final item = items[index];
              final user = users[item.userId?.toString() ?? ''];
              children.add(_buildItemCard(item, user, currency));
            }

            if (showFooter) {
              if (children.isNotEmpty) {
                children.add(const SizedBox(height: 12));
              }
              children.add(
                _buildLoadMoreFooter(
                  showLoading: showLoadingFooter,
                  showNoMore: showNoMoreFooter,
                ),
              );
            }

            return _buildInnerScrollView(
              context: context,
              storageKey: 'market_detail_on_sale',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: children,
            );
          },
        );
      }),
    );
  }

  bool get _showOnSaleFilter => controller.appId != 440;

  bool get _hasOnSaleFilter =>
      _onSaleSortField != null ||
      _onSaleMinPrice != null ||
      _onSaleMaxPrice != null ||
      (_onSalePaintSeed?.isNotEmpty ?? false) ||
      _onSalePaintIndex != null ||
      _onSaleWearMin != null ||
      _onSaleWearMax != null;

  Future<void> _clearOnSaleFilter() async {
    setState(() {
      _onSaleSortField = null;
      _onSaleSortAsc = null;
      _onSaleMinPrice = null;
      _onSaleMaxPrice = null;
      _onSalePaintSeed = null;
      _onSalePaintIndex = null;
      _onSaleWearMin = null;
      _onSaleWearMax = null;
    });
    await _applyOnSaleFilterWithCurrentState();
  }

  Future<void> _openOnSaleFilterSheet() async {
    final paintSeedController = TextEditingController(text: _onSalePaintSeed);
    final wearMinController = TextEditingController(
      text: _onSaleWearMin?.toString(),
    );
    final wearMaxController = TextEditingController(
      text: _onSaleWearMax?.toString(),
    );
    final minPriceController = TextEditingController(
      text: _onSaleMinPrice?.toString(),
    );
    final maxPriceController = TextEditingController(
      text: _onSaleMaxPrice?.toString(),
    );
    var selectedSortField = _onSaleSortField;
    var selectedSortAsc = _onSaleSortAsc;
    var selectedPaintIndex = _onSalePaintIndex;
    final sortOptions = _buildOnSaleSortOptions();
    final paintKits = _buildPaintKitOptions();
    final wearQuickOptions = _buildWearQuickOptions(
      _templateDetail?.schema?.tags?.exterior?.key,
    );
    final showCsgoFilter = controller.appId == 730;

    final barrierLabel = MaterialLocalizations.of(
      context,
    ).modalBarrierDismissLabel;
    final result = await showGeneralDialog<_OnSaleFilterValue>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final width = media.size.width;
        final height = media.size.height;
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            height: height,
            child: Material(
              color: Theme.of(dialogContext).scaffoldBackgroundColor,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final theme = Theme.of(context);
                  final colors = theme.colorScheme;
                  final isDark = theme.brightness == Brightness.dark;
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  final sectionTitleStyle = theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600);
                  final inputFillColor = isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : colors.surface;
                  final inputBorder = OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.outline.withValues(alpha: 0.12),
                    ),
                  );

                  void resetAndClose() {
                    Navigator.of(context).pop(const _OnSaleFilterValue());
                  }

                  void applyAndClose() {
                    Navigator.of(context).pop(
                      _OnSaleFilterValue(
                        sortField: selectedSortField,
                        sortAsc: selectedSortAsc,
                        minPrice: _parseOptionalDouble(minPriceController.text),
                        maxPrice: _parseOptionalDouble(maxPriceController.text),
                        paintSeed: _cleanText(paintSeedController.text),
                        paintIndex: selectedPaintIndex,
                        paintWearMin: _parseOptionalDouble(
                          wearMinController.text,
                        ),
                        paintWearMax: _parseOptionalDouble(
                          wearMaxController.text,
                        ),
                      ),
                    );
                  }

                  InputDecoration buildInputDecoration({
                    String? labelText,
                    String? hintText,
                  }) {
                    return InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      labelText: labelText,
                      hintText: hintText,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: bottomInset + 12,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'app.market.filter.text'.tr,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'app.market.filter.sort'.tr,
                                    style: sectionTitleStyle,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: sortOptions
                                        .map(
                                          (option) => _buildOnSaleFilterChip(
                                            context,
                                            label: _formatOnSaleSortLabel(
                                              option,
                                            ),
                                            selected:
                                                option.field ==
                                                    selectedSortField &&
                                                option.asc == selectedSortAsc,
                                            onSelected: (_) {
                                              setModalState(() {
                                                selectedSortField =
                                                    option.field;
                                                selectedSortAsc = option.asc;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                  if (showCsgoFilter) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'app.market.csgo.paint_index'.tr,
                                      style: sectionTitleStyle,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: paintSeedController,
                                      keyboardType: TextInputType.number,
                                      decoration: buildInputDecoration(
                                        hintText:
                                            'app.market.csgo.paint_index_placeholder'
                                                .tr,
                                      ),
                                    ),
                                    if (paintKits.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'app.market.filter.selection_phase'.tr,
                                        style: sectionTitleStyle,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildOnSaleFilterChip(
                                            context,
                                            label:
                                                'app.market.csgo.phase_unlimited'
                                                    .tr,
                                            selected:
                                                selectedPaintIndex == null,
                                            onSelected: (_) {
                                              setModalState(
                                                () => selectedPaintIndex = null,
                                              );
                                            },
                                          ),
                                          ...paintKits.map(
                                            (option) => _buildOnSaleFilterChip(
                                              context,
                                              label: option.label,
                                              selected:
                                                  selectedPaintIndex ==
                                                  option.id,
                                              onSelected: (_) {
                                                setModalState(
                                                  () => selectedPaintIndex =
                                                      option.id,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (wearQuickOptions.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'app.market.filter.csgo.wear_interval'
                                            .tr,
                                        style: sectionTitleStyle,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: wearMinController,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: buildInputDecoration(
                                                hintText: '0.00',
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text('~'),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: wearMaxController,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: buildInputDecoration(
                                                hintText: '1.00',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'app.market.filter.selection_quick'.tr,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: wearQuickOptions
                                            .map((option) {
                                              final selected =
                                                  wearMinController.text ==
                                                      option.minText &&
                                                  wearMaxController.text ==
                                                      option.maxText;
                                              return _buildOnSaleFilterChip(
                                                context,
                                                label: option.label,
                                                selected: selected,
                                                onSelected: (_) {
                                                  setModalState(() {
                                                    wearMinController.text =
                                                        option.minText;
                                                    wearMaxController.text =
                                                        option.maxText;
                                                  });
                                                },
                                              );
                                            })
                                            .toList(growable: false),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 16),
                                  Text(
                                    'app.market.filter.price_range'.tr,
                                    style: sectionTitleStyle,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: minPriceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: buildInputDecoration(
                                            labelText:
                                                'app.market.filter.price_lowest'
                                                    .tr,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text('~'),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: maxPriceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: buildInputDecoration(
                                            labelText:
                                                'app.market.filter.price_highest'
                                                    .tr,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: Text('app.common.cancel'.tr),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: resetAndClose,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: Text('app.market.filter.reset'.tr),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: applyAndClose,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  child: Text('app.market.filter.finish'.tr),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );

    if (result == null) {
      return;
    }
    setState(() {
      _onSaleSortField = result.sortField;
      _onSaleSortAsc = result.sortAsc;
      _onSaleMinPrice = result.minPrice;
      _onSaleMaxPrice = result.maxPrice;
      _onSalePaintSeed = result.paintSeed;
      _onSalePaintIndex = result.paintIndex;
      _onSaleWearMin = result.paintWearMin;
      _onSaleWearMax = result.paintWearMax;
    });
    await _applyOnSaleFilterWithCurrentState();
  }

  List<_PaintKitOption> _buildPaintKitOptions() {
    final paintKits = _templateDetail?.paintKits;
    if (paintKits == null || paintKits.isEmpty) {
      return const <_PaintKitOption>[];
    }
    final options = <int, _PaintKitOption>{};
    for (final raw in paintKits) {
      if (raw is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(raw);
      final id = _asInt(map['id']);
      if (id == null) {
        continue;
      }
      final label =
          _cleanText(map['phase']?.toString()) ??
          _cleanText(map['name']?.toString()) ??
          id.toString();
      options[id] = _PaintKitOption(id: id, label: label);
    }
    return options.values.toList(growable: false);
  }

  List<_WearQuickOption> _buildWearQuickOptions(String? exteriorKey) {
    switch (exteriorKey) {
      case 'WearCategory0':
        return const <_WearQuickOption>[
          _WearQuickOption('0.00-0.01', '0.00', '0.01'),
          _WearQuickOption('0.01-0.02', '0.01', '0.02'),
          _WearQuickOption('0.02-0.03', '0.02', '0.03'),
          _WearQuickOption('0.03-0.04', '0.03', '0.04'),
          _WearQuickOption('0.04-0.07', '0.04', '0.07'),
        ];
      case 'WearCategory1':
        return const <_WearQuickOption>[
          _WearQuickOption('0.07-0.08', '0.07', '0.08'),
          _WearQuickOption('0.08-0.09', '0.08', '0.09'),
          _WearQuickOption('0.09-0.10', '0.09', '0.10'),
          _WearQuickOption('0.10-0.11', '0.10', '0.11'),
          _WearQuickOption('0.11-0.15', '0.11', '0.15'),
        ];
      case 'WearCategory2':
        return const <_WearQuickOption>[
          _WearQuickOption('0.15-0.18', '0.15', '0.18'),
          _WearQuickOption('0.18-0.21', '0.18', '0.21'),
          _WearQuickOption('0.21-0.24', '0.21', '0.24'),
          _WearQuickOption('0.24-0.27', '0.24', '0.27'),
          _WearQuickOption('0.27-0.38', '0.27', '0.38'),
        ];
      case 'WearCategory3':
        return const <_WearQuickOption>[
          _WearQuickOption('0.38-0.39', '0.38', '0.39'),
          _WearQuickOption('0.39-0.40', '0.39', '0.40'),
          _WearQuickOption('0.40-0.41', '0.40', '0.41'),
          _WearQuickOption('0.41-0.42', '0.41', '0.42'),
          _WearQuickOption('0.42-0.45', '0.42', '0.45'),
        ];
      case 'WearCategory4':
        return const <_WearQuickOption>[
          _WearQuickOption('0.45-0.50', '0.45', '0.50'),
          _WearQuickOption('0.50-0.63', '0.50', '0.63'),
          _WearQuickOption('0.63-0.76', '0.63', '0.76'),
          _WearQuickOption('0.76-0.90', '0.76', '0.90'),
          _WearQuickOption('0.90-1.00', '0.90', '1.00'),
        ];
      default:
        return const <_WearQuickOption>[];
    }
  }

  Widget _buildOnSaleFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }

  double? _parseOptionalDouble(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  Widget _buildItemCard(
    MarketListItem item,
    MarketUserInfo? user,
    CurrencyController currency,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schema = _lookupMarketSchema(item);
    final appId = item.appId ?? controller.appId;
    final imageUrl =
        schema?.imageUrl ?? item.raw['image_url']?.toString() ?? '';
    final asset = _resolveAsset(item);
    final paintWearValue = _extractDouble(asset, ['paint_wear', 'paintWear']);
    final paintWearText =
        _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(item.raw, ['paint_wear', 'paintWear']) ??
        paintWearValue?.toString();
    final stickers = _parseStickers(
      asset: asset,
      raw: item.raw,
      schemas: controller.schemas,
      stickerMap: controller.stickers,
    );
    final gems = parseGemList(
      asset?['gemList'] ??
          asset?['gems'] ??
          item.raw['gemList'] ??
          item.raw['gems'],
    );
    final keychains = _parseKeychains(
      asset?['keychains'] ?? item.raw['keychains'],
      controller.schemas,
      controller.stickers,
    );
    final avatar = _resolveAvatar(user?.avatar);
    final canBuy = item.id != null && item.price != null;
    final purchaseKey = _onSalePurchaseKey(item);
    final isPurchasing =
        purchaseKey != null && _onSalePurchasingIds.contains(purchaseKey);
    final isOwn = _isOwnOnSaleItem(item);

    return Card(
      color: isDark ? const Color(0xFF26272B) : Colors.white,
      child: InkWell(
        onTap: () => _openItemDetail(item, schema, user),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 54,
                          child: GameItemImage(
                            imageUrl: imageUrl,
                            appId: appId,
                          ),
                        ),
                        if (stickers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: StickerRow(stickers: stickers, size: 16),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            currency.format(item.price ?? 0),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if ((user?.nickname ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: avatar.isNotEmpty
                                      ? CachedNetworkImageProvider(avatar)
                                      : null,
                                  child: avatar.isEmpty
                                      ? const Icon(Icons.person, size: 12)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user?.nickname ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isOwn)
                    FilledButton(
                      onPressed: canBuy && !isPurchasing
                          ? () => _purchaseItem(item)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(60, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: isPurchasing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text('app.trade.buy.text'.tr),
                    ),
                  if (isOwn)
                    Column(
                      children: [
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => _changePriceOnSaleItem(
                              item: item,
                              schema: schema,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(74, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              'app.inventory.price_change'.tr,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => _delistOnSaleItem(item),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(74, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            child: Text(
                              'app.inventory.delist'.tr,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (appId == 730 &&
                  paintWearValue != null &&
                  paintWearText != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${'app.market.csgo.wear'.tr}: $paintWearText',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                WearProgressBar(paintWear: paintWearValue),
              ],
              if (gems.isNotEmpty || keychains.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (gems.isNotEmpty) GemRow(gems: gems, size: 16),
                      if (gems.isNotEmpty) const SizedBox(width: 6),
                      if (keychains.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: StickerRow(stickers: keychains, size: 16),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOwnOnSaleItem(MarketListItem item) {
    if (item.own == true) {
      return true;
    }
    final currentUser = UserStorage.getUserInfo();
    final currentUserId = _asInt(currentUser?.id);
    final currentShopId = _asInt(currentUser?.shop?.id);
    final sellerId = item.userId;
    if (sellerId == null) {
      return false;
    }
    return sellerId == currentUserId || sellerId == currentShopId;
  }

  Future<void> _changePriceOnSaleItem({
    required MarketListItem item,
    required MarketSchemaInfo? schema,
  }) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    final raw = Map<String, dynamic>.from(item.raw);
    final shopItem = ShopItemAsset(
      raw: raw,
      id: id,
      appId: item.appId ?? controller.appId,
      schemaId: item.schemaId,
      marketName:
          schema?.marketName ??
          raw['market_name']?.toString() ??
          raw['marketName']?.toString(),
      marketHashName: schema?.marketHashName ?? item.marketHashName,
      imageUrl:
          schema?.imageUrl ??
          raw['image_url']?.toString() ??
          raw['imageUrl']?.toString(),
      price: item.price,
      count: _asInt(raw['count']) ?? 1,
      userId: item.userId,
      status: _asInt(raw['status']),
      statusName:
          raw['statusName']?.toString() ?? raw['status_name']?.toString(),
      createTime: _asInt(raw['create_time'] ?? raw['createTime']),
    );

    final schemaMap = <String, ShopSchemaInfo>{};
    if (schema != null && schema.raw.isNotEmpty) {
      try {
        final mappedSchema = ShopSchemaInfo.fromJson(
          Map<String, dynamic>.from(schema.raw),
        );
        final hash = mappedSchema.marketHashName;
        if (hash != null && hash.isNotEmpty) {
          schemaMap[hash] = mappedSchema;
        }
        final schemaId = item.schemaId;
        if (schemaId != null) {
          schemaMap[schemaId.toString()] = mappedSchema;
        }
      } catch (_) {}
    }

    await Get.toNamed(
      Routers.SHOP_PRICE_CHANGE,
      arguments: <String, dynamic>{
        'items': <ShopItemAsset>[shopItem],
        'schemas': schemaMap,
        'appId': item.appId ?? controller.appId,
      },
    );
    await controller.loadOnSale(reset: true);
  }

  Future<void> _delistOnSaleItem(MarketListItem item) async {
    final id = item.id;
    if (id == null) {
      return;
    }

    final confirm = await Get.dialog<bool>(
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
    if (confirm != true) {
      return;
    }

    try {
      final res = await _shopProductApi.orderItemRemoved(ids: <int>[id]);
      if (res.success) {
        AppSnackbar.success('app.system.message.success'.tr);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    }

    await controller.loadOnSale(reset: true);
    await controller.loadTransactions(reset: true);
  }

  Widget _buildPriceTrendTab() {
    return BackToTopScope(
      enabled: true,
      child: Obx(() {
        final isLoading = controller.isLoadingTrend.value;
        final points = controller.pricePoints.toList(growable: false);

        return Builder(
          builder: (context) => _buildInnerScrollView(
            context: context,
            storageKey: 'market_detail_price_trend',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip(
                    7,
                    'app.market.detail.price_trend.seven_days'.tr,
                  ),
                  _buildDayChip(
                    30,
                    'app.market.detail.price_trend.last_one_month'.tr,
                  ),
                  _buildDayChip(
                    180,
                    'app.market.detail.price_trend.last_half_year'.tr,
                  ),
                  _buildDayChip(
                    365,
                    'app.market.detail.price_trend.last_year'.tr,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PriceTrendChart(points: points),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBuyRequestTab(CurrencyController currency) {
    final colorScheme = Theme.of(context).colorScheme;
    return BackToTopScope(
      enabled: true,
      child: Obx(() {
        final isLoading = controller.isLoadingBuyRequests.value;
        final items = controller.buyRequests.toList(growable: false);
        final users = Map<String, ShopUserInfo>.from(controller.buyUsers);
        final schemas = Map<String, ShopSchemaInfo>.from(controller.buySchemas);
        final showLoadingFooter = isLoading && items.isNotEmpty;
        final showNoMoreFooter =
            items.isNotEmpty && !isLoading && !controller.buyRequestHasMore;
        final showFooter = showLoadingFooter || showNoMoreFooter;

        return Builder(
          builder: (context) {
            if (isLoading && items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_buy_request_loading',
                child: const CircularProgressIndicator(),
              );
            }
            if (items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_buy_request_empty',
                child: Text('app.common.no_data'.tr),
              );
            }

            final children = <Widget>[];

            for (var index = 0; index < items.length; index++) {
              if (index > 0) {
                children.add(const SizedBox(height: 12));
              }
              final item = items[index];
              final schemaKey = item.schemaId?.toString();
              final schema = schemaKey == null ? null : schemas[schemaKey];
              final userKey = item.userId?.toString();
              final user = userKey == null ? null : users[userKey];
              final avatar = _resolveAvatar(user?.avatar);
              final imageUrl = schema?.imageUrl ?? '';
              final schemaTags = schema?.raw['tags'];
              final rarity = TagInfo.fromRaw(
                schemaTags is Map ? schemaTags['rarity'] : null,
              );
              final quality = TagInfo.fromRaw(
                schemaTags is Map ? schemaTags['quality'] : null,
              );
              final exterior = TagInfo.fromRaw(
                schemaTags is Map ? schemaTags['exterior'] : null,
              );
              final wearMinText =
                  item.raw['paint_wear_min']?.toString() ??
                  item.raw['paintWearMin']?.toString() ??
                  item.paintWearMin?.toString();
              final wearMaxText =
                  item.raw['paint_wear_max']?.toString() ??
                  item.raw['paintWearMax']?.toString() ??
                  item.paintWearMax?.toString();
              final need = item.need ?? item.nums ?? 0;
              final isOwn = item.own == true;
              final canSupply = need > 0;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              const buyRequestImageWidth = 108.0;
              const buyRequestImageHeight = 64.8;

              children.add(
                Card(
                  color: isDark ? const Color(0xFF26272B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: buyRequestImageWidth,
                          height: buyRequestImageHeight,
                          child: GameItemImage(
                            imageUrl: imageUrl,
                            appId: item.appId,
                            rarity: rarity,
                            quality: quality,
                            exterior: exterior,
                            phase: item.phase,
                            count: need > 0 ? need : null,
                            alwaysShowCount: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  currency.format(item.price ?? 0),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (wearMinText != null && wearMaxText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${'app.market.csgo.wear'.tr}: '
                                    '$wearMinText - $wearMaxText',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              if ((user?.nickname ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundImage: avatar.isNotEmpty
                                            ? CachedNetworkImageProvider(avatar)
                                            : null,
                                        child: avatar.isEmpty
                                            ? const Icon(Icons.person, size: 12)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          user?.nickname ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            if (!isOwn)
                              FilledButton(
                                onPressed: canSupply
                                    ? () async {
                                        final user = UserStorage.getUserInfo();
                                        if (user == null) {
                                          AppSnackbar.info(
                                            'app.system.message.nologin'.tr,
                                          );
                                          return;
                                        }
                                        final result = await Get.toNamed(
                                          Routers.BUYING_SUPPLY,
                                          arguments: {
                                            'item': item,
                                            'schema': schema,
                                          },
                                        );
                                        if (result == true) {
                                          await controller.loadBuyRequests(
                                            reset: true,
                                          );
                                          await Get.dialog<void>(
                                            AlertDialog(
                                              title: Text(
                                                'app.system.tips.title'.tr,
                                              ),
                                              content: Text(
                                                'app.trade.supply.message.confirm'
                                                    .tr,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Get.back(),
                                                  child: Text(
                                                    'app.common.confirm'.tr,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                child: Text('app.trade.supply.text'.tr),
                              ),
                            if (isOwn) ...[
                              SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final result = await Get.toNamed(
                                      Routers.BUYING_UPDATE_PRICE,
                                      arguments: {
                                        'item': item,
                                        'schema': schema,
                                      },
                                    );
                                    if (result == true) {
                                      await controller.loadBuyRequests(
                                        reset: true,
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(74, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  child: Text(
                                    'app.inventory.price_change'.tr,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: () async {
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
                                            onPressed: () =>
                                                Get.back(result: false),
                                            child: Text('app.common.cancel'.tr),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: true),
                                            child: Text(
                                              'app.common.confirm'.tr,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) {
                                      return;
                                    }
                                    try {
                                      final res = await _shopProductApi
                                          .orderItemCancelBuy(id: id);
                                      if (res.success) {
                                        AppSnackbar.success(
                                          'app.system.message.success'.tr,
                                        );
                                      } else {
                                        AppSnackbar.error(
                                          res.message.isNotEmpty
                                              ? res.message
                                              : 'app.trade.filter.failed'.tr,
                                        );
                                      }
                                    } catch (_) {
                                      AppSnackbar.error(
                                        'app.trade.filter.failed'.tr,
                                      );
                                    }
                                    await controller.loadBuyRequests(
                                      reset: true,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(74, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  child: Text(
                                    'app.common.delete'.tr,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (showFooter) {
              if (children.isNotEmpty) {
                children.add(const SizedBox(height: 12));
              }
              children.add(
                _buildLoadMoreFooter(
                  showLoading: showLoadingFooter,
                  showNoMore: showNoMoreFooter,
                ),
              );
            }

            return _buildInnerScrollView(
              context: context,
              storageKey: 'market_detail_buy_request',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: children,
            );
          },
        );
      }),
    );
  }

  Widget _buildTransactionTab(CurrencyController currency) {
    final colorScheme = Theme.of(context).colorScheme;
    return BackToTopScope(
      enabled: true,
      child: Obx(() {
        final isLoading = controller.isLoadingTransactions.value;
        final items = controller.transactionItems.toList(growable: false);
        final users = Map<String, MarketUserInfo>.from(controller.users);
        final schemas = Map<String, MarketSchemaInfo>.from(controller.schemas);
        final showLoadingFooter = isLoading && items.isNotEmpty;
        final showNoMoreFooter =
            items.isNotEmpty && !isLoading && !controller.transactionHasMore;
        final showFooter = showLoadingFooter || showNoMoreFooter;

        return Builder(
          builder: (context) {
            if (isLoading && items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_transaction_loading',
                child: const CircularProgressIndicator(),
              );
            }
            if (items.isEmpty) {
              return _buildInnerFillRemaining(
                context: context,
                storageKey: 'market_detail_transaction_empty',
                child: Text('app.common.no_data'.tr),
              );
            }

            final children = <Widget>[];
            for (var index = 0; index < items.length; index++) {
              if (index > 0) {
                children.add(const SizedBox(height: 12));
              }
              final item = items[index];
              final user = users[item.userId?.toString() ?? ''];
              final schemaKey = item.schemaId?.toString();
              final hash = item.marketHashName;
              final schema = schemaKey != null
                  ? schemas[schemaKey]
                  : (hash != null ? schemas[hash] : null);
              final imageUrl = schema?.imageUrl ?? '';
              final appId = item.appId ?? controller.appId;
              final count =
                  _asInt(
                    item.raw['count'] ?? item.raw['nums'] ?? item.raw['num'],
                  ) ??
                  1;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              children.add(
                Card(
                  color: isDark ? const Color(0xFF26272B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: SizedBox(
                            width: 90,
                            height: 54,
                            child: GameItemImage(
                              imageUrl: imageUrl,
                              appId: appId,
                              count: count > 1 ? count : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  currency.format(item.price ?? 0),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if ((user?.nickname ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundImage: user?.avatar != null
                                            ? CachedNetworkImageProvider(
                                                _resolveAvatar(user!.avatar),
                                              )
                                            : null,
                                        child: user?.avatar == null
                                            ? const Icon(Icons.person, size: 12)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          user?.nickname ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.typeName ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(item.createTime),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (showFooter) {
              if (children.isNotEmpty) {
                children.add(const SizedBox(height: 12));
              }
              children.add(
                _buildLoadMoreFooter(
                  showLoading: showLoadingFooter,
                  showNoMore: showNoMoreFooter,
                ),
              );
            }

            return _buildInnerScrollView(
              context: context,
              storageKey: 'market_detail_transaction',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: children,
            );
          },
        );
      }),
    );
  }

  Future<void> _openItemDetail(
    MarketListItem item,
    MarketSchemaInfo? schema,
    MarketUserInfo? user,
  ) async {
    final result = await Get.toNamed(
      Routers.MARKET_ITEM_DETAIL,
      arguments: {
        'item': item,
        'schema': schema,
        'user': user,
        'schemas': Map<String, MarketSchemaInfo>.from(controller.schemas),
        'stickers': Map<String, dynamic>.from(controller.stickers),
      },
    );
    if (result == true) {
      AppSnackbar.success('app.trade.buy.message.success'.tr);
      await controller.loadOnSale(reset: true);
      await controller.loadTransactions(reset: true);
    }
  }

  Future<void> _purchaseItem(MarketListItem item) async {
    final purchaseKey = _onSalePurchaseKey(item);
    if (purchaseKey != null && _onSalePurchasingIds.contains(purchaseKey)) {
      return;
    }
    final user = UserStorage.getUserInfo();
    if (user == null) {
      AppSnackbar.info('app.system.message.nologin'.tr);
      return;
    }
    final id = item.id?.toString();
    final price = item.price;
    final appId = item.appId ?? controller.appId;
    if (id == null || price == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }
    final currency = Get.find<CurrencyController>();
    final amountText = currency.format(price);
    final confirmed = await showSteamStyleAmountConfirmDialog(
      context,
      title: 'app.trade.buy.pay_text'.tr,
      amount: amountText,
      message:
          '${'app.trade.buy.pay_text_2'.tr} ${price.floor()}\n${'app.trade.buy.pay_text_3'.tr}',
      confirmText: 'app.common.confirm'.tr,
      cancelText: 'app.common.cancel'.tr,
    );
    if (confirmed != true) {
      return;
    }
    if (purchaseKey != null && mounted) {
      setState(() => _onSalePurchasingIds.add(purchaseKey));
    }
    try {
      final res = await _shopProductApi.orderItemPurchase(
        appId: appId,
        id: id,
        price: price,
      );
      final datas = res.datas;
      if (datas is String) {
        if (datas.contains('Steam issue')) {
          await Get.dialog<void>(
            AlertDialog(
              title: Text('app.system.tips.title'.tr),
              content: Text('app.steam.message.trading_restrictions'.tr),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('app.common.confirm'.tr),
                ),
              ],
            ),
          );
          return;
        }
        if (datas.contains('Inventory privacy')) {
          final nickname = user.config?.nickname ?? user.nickname ?? '';
          await Get.dialog<void>(
            AlertDialog(
              title: Text('app.system.tips.title'.tr),
              content: Text('${'app.inventory.message.privacy'.tr}$nickname'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('app.common.confirm'.tr),
                ),
              ],
            ),
          );
          return;
        }
      }
      if (res.success) {
        AppSnackbar.success('app.trade.buy.message.success'.tr);
        await controller.loadOnSale(reset: true);
        await controller.loadTransactions(reset: true);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (purchaseKey != null && mounted) {
        setState(() => _onSalePurchasingIds.remove(purchaseKey));
      }
    }
  }

  Map<String, dynamic>? _resolveAsset(MarketListItem item) {
    final raw = item.raw;
    if (item.appId == 730 && raw['csgoAsset'] is Map<String, dynamic>) {
      return raw['csgoAsset'] as Map<String, dynamic>;
    }
    if (item.appId == 440 && raw['tf2Asset'] is Map<String, dynamic>) {
      return raw['tf2Asset'] as Map<String, dynamic>;
    }
    if (item.appId == 570 && raw['dota2Asset'] is Map<String, dynamic>) {
      return raw['dota2Asset'] as Map<String, dynamic>;
    }
    return raw;
  }

  String? _extractText(dynamic raw, List<String> keys) {
    if (raw is Map) {
      for (final key in keys) {
        final value = raw[key];
        if (value != null) {
          return value.toString();
        }
      }
    }
    return null;
  }

  double? _extractDouble(dynamic raw, List<String> keys) {
    if (raw is Map) {
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
    }
    return null;
  }

  List<GameItemSticker> _parseKeychains(
    dynamic raw,
    Map<String, MarketSchemaInfo> schemas,
    Map<String, dynamic> stickerMap,
  ) {
    final fromRaw = parseStickerList(
      raw,
      schemaMap: schemas,
      stickerMap: stickerMap,
    );
    if (fromRaw.isNotEmpty) {
      return fromRaw;
    }
    if (raw is! List) {
      return const [];
    }
    final list = <GameItemSticker>[];
    for (final entry in raw) {
      if (entry is Map) {
        final image =
            entry['image_url']?.toString() ??
            entry['imageUrl']?.toString() ??
            entry['image']?.toString();
        if (image != null && image.isNotEmpty) {
          list.add(GameItemSticker(image));
          continue;
        }
        final schemaId = entry['schema_id'] ?? entry['schemaId'] ?? entry['id'];
        if (schemaId != null) {
          final schema = schemas[schemaId.toString()];
          final url = schema?.imageUrl;
          if (url != null && url.isNotEmpty) {
            list.add(GameItemSticker(url));
          }
        }
      } else if (entry is num || entry is String) {
        final schema = schemas[entry.toString()];
        final url = schema?.imageUrl;
        if (url != null && url.isNotEmpty) {
          list.add(GameItemSticker(url));
        }
      }
    }
    return list;
  }

  List<GameItemSticker> _parseStickers({
    required Map<String, dynamic>? asset,
    required Map<String, dynamic> raw,
    required Map<String, MarketSchemaInfo> schemas,
    required Map<String, dynamic> stickerMap,
  }) {
    final rawAsset = _asMap(raw['asset']) ?? _asMap(raw['itemAsset']);
    final rawCsgoAsset = _asMap(raw['csgoAsset']) ?? _asMap(raw['csgo_asset']);
    final rawTf2Asset = _asMap(raw['tf2Asset']) ?? _asMap(raw['tf2_asset']);
    final rawDotaAsset =
        _asMap(raw['dota2Asset']) ?? _asMap(raw['dota2_asset']);
    final candidates = <dynamic>[
      asset?['stickers'],
      asset?['stickerList'],
      asset?['sticker_list'],
      asset?['sticker'],
      rawAsset?['stickers'],
      rawAsset?['stickerList'],
      rawAsset?['sticker_list'],
      rawCsgoAsset?['stickers'],
      rawCsgoAsset?['stickerList'],
      rawCsgoAsset?['sticker_list'],
      rawTf2Asset?['stickers'],
      rawTf2Asset?['stickerList'],
      rawTf2Asset?['sticker_list'],
      rawDotaAsset?['stickers'],
      rawDotaAsset?['stickerList'],
      rawDotaAsset?['sticker_list'],
      raw['stickers'],
      raw['stickerList'],
      raw['sticker_list'],
      raw['sticker'],
    ];
    for (final candidate in candidates) {
      final parsed = parseStickerList(
        _normalizeStickerRaw(candidate),
        schemaMap: schemas,
        stickerMap: stickerMap,
      );
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return const [];
  }

  dynamic _normalizeStickerRaw(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      if (raw.containsKey('image_url') ||
          raw.containsKey('imageUrl') ||
          raw.containsKey('image') ||
          raw.containsKey('id') ||
          raw.containsKey('sticker_id') ||
          raw.containsKey('schema_id')) {
        return <dynamic>[raw];
      }
      final values = raw.values.toList(growable: false);
      if (values.isNotEmpty) {
        return values;
      }
    }
    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty || value == 'null') {
        return const <dynamic>[];
      }
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded;
          }
        } catch (_) {}
      }
      if (value.contains(',')) {
        final values = value
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
        if (values.isNotEmpty) {
          return values;
        }
      }
    }
    if (raw is Iterable) {
      return raw.toList(growable: false);
    }
    return raw;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final mapped = <String, dynamic>{};
      value.forEach((key, mapValue) {
        mapped[key.toString()] = mapValue;
      });
      return mapped;
    }
    return null;
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

  Widget _buildDayChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) {
          return;
        }
        setState(() => _selectedDays = days);
        controller.loadTrend(reset: true, days: days);
      },
    );
  }

  String _formatTime(int? value) {
    if (value == null) {
      return '-';
    }
    var timestamp = value;
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  String _rarityBgAsset(String? color) {
    final normalized = (color ?? 'b0c3d9').replaceAll('#', '').toLowerCase();
    return 'assets/images/game/item/$normalized.png';
  }
}

class _TagChipData {
  const _TagChipData(this.text, this.color);

  final String text;
  final Color? color;
}

class _WearOption {
  const _WearOption({required this.id, required this.label, this.price});

  final int id;
  final String label;
  final dynamic price;
}

class _OnSaleSortOption {
  const _OnSaleSortOption({
    required this.field,
    required this.asc,
    required this.labelKey,
    this.suffix,
  });

  final String? field;
  final bool? asc;
  final String labelKey;
  final String? suffix;
}

class _OnSaleFilterValue {
  const _OnSaleFilterValue({
    this.sortField,
    this.sortAsc,
    this.minPrice,
    this.maxPrice,
    this.paintSeed,
    this.paintIndex,
    this.paintWearMin,
    this.paintWearMax,
  });

  final String? sortField;
  final bool? sortAsc;
  final double? minPrice;
  final double? maxPrice;
  final String? paintSeed;
  final int? paintIndex;
  final double? paintWearMin;
  final double? paintWearMax;
}

class _PaintKitOption {
  const _PaintKitOption({required this.id, required this.label});

  final int id;
  final String label;
}

class _WearQuickOption {
  const _WearQuickOption(this.label, this.minText, this.maxText);

  final String label;
  final String minText;
  final String maxText;
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(
    this._child, {
    required this.height,
    this.backgroundColor,
  });

  final Widget _child;
  final double height;
  final Color? backgroundColor;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _child,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate._child != _child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _FixedHeightHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeightHeaderDelegate({
    required this.height,
    required this.child,
    this.backgroundColor,
  });

  final double height;
  final Widget child;
  final Color? backgroundColor;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FixedHeightHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
