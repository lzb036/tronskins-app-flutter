import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
import 'package:tronskins_app/routes/app_routes.dart';

class MarketDetailPage extends StatefulWidget {
  const MarketDetailPage({super.key});

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage>
    with SingleTickerProviderStateMixin {
  final MarketDetailController controller = Get.put(MarketDetailController());
  final ApiMarketServer _marketApi = ApiMarketServer();
  final ApiShopServer _shopServer = ApiShopServer();
  final ApiShopProductServer _shopProductApi = ApiShopProductServer();
  late final TabController _tabController;
  final ScrollController _onSaleScroll = ScrollController();
  final ScrollController _transactionScroll = ScrollController();
  final ScrollController _buyRequestScroll = ScrollController();
  int _selectedDays = 30;
  MarketTemplateDetail? _templateDetail;
  bool _loadingTemplate = false;
  List<_WearOption> _wearOptions = <_WearOption>[];
  List<String> _qualityKeys = <String>[];
  int _qualityIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _onSaleScroll.addListener(() {
      if (_onSaleScroll.position.pixels >
          _onSaleScroll.position.maxScrollExtent - 200) {
        controller.loadOnSale();
      }
    });
    _buyRequestScroll.addListener(() {
      if (_buyRequestScroll.position.pixels >
          _buyRequestScroll.position.maxScrollExtent - 200) {
        controller.loadBuyRequests();
      }
    });
    _transactionScroll.addListener(() {
      if (_transactionScroll.position.pixels >
          _transactionScroll.position.maxScrollExtent - 200) {
        controller.loadTransactions();
      }
    });
    Future.microtask(_loadTemplate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _onSaleScroll.dispose();
    _buyRequestScroll.dispose();
    _transactionScroll.dispose();
    super.dispose();
  }

  ShopSchemaInfo? _lookupBuySchema(BuyRequestItem item) {
    final key = item.schemaId?.toString();
    if (key != null && controller.buySchemas.containsKey(key)) {
      return controller.buySchemas[key];
    }
    return null;
  }

  ShopUserInfo? _lookupBuyUser(BuyRequestItem item) {
    final key = item.userId?.toString();
    if (key != null && controller.buyUsers.containsKey(key)) {
      return controller.buyUsers[key];
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
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.nologin'.tr);
      return;
    }
    final uuid = user.uuid ?? user.shop?.uuid;
    if (uuid != null && uuid.isNotEmpty) {
      try {
        final res = await _shopServer.getUserShopInfo(params: {'uuid': uuid});
        if (res.success && res.datas != null) {
          if (res.datas?['signWanted'] != true) {
            Get.snackbar(
              'app.system.tips.title'.tr,
              'app.trade.purchase.offline_tips'.tr,
            );
            return;
          }
        }
      } catch (_) {}
    }
    final schemaId = controller.schemaId;
    if (schemaId == null) {
      return;
    }
    Get.toNamed(
      Routers.PRODUCT_BUYING,
      arguments: {'appId': controller.appId, 'schemaId': schemaId},
    );
  }

  Future<void> _openBulkBuying() async {
    final user = UserStorage.getUserInfo();
    if (user == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.nologin'.tr);
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
      return;
    }
    setState(() => _loadingTemplate = true);
    try {
      final useAuth = UserStorage.getUserInfo() != null;
      var res = await _marketApi.marketTemplateDetail(
        appId: appId,
        schemaId: targetId,
        useAuth: useAuth,
      );
      if (!res.success && useAuth) {
        res = await _marketApi.marketTemplateDetail(
          appId: appId,
          schemaId: targetId,
          useAuth: false,
        );
      }
      final detail = res.datas;
      if (detail == null) {
        return;
      }
      _templateDetail = detail;
      _buildWearOptions(detail);
      final schema = detail.schema;
      if (schema != null) {
        controller.updateItem(_mapTemplateToItem(schema));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTemplate = false);
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

  void _cycleQualityKey() {
    if (_qualityKeys.length < 2) {
      return;
    }
    _qualityIndex = (_qualityIndex + 1) % _qualityKeys.length;
    final qualityMap = _templateDetail?.qualityMap;
    if (qualityMap == null) {
      return;
    }
    final selectedKey = _qualityKeys[_qualityIndex];
    _wearOptions = _parseWearOptions(qualityMap[selectedKey]);
    setState(() {});
  }

  Future<void> _selectWear(int schemaId) async {
    await _loadTemplate(schemaId: schemaId);
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

  @override
  Widget build(BuildContext context) {
    final item = controller.item;
    final currency = Get.find<CurrencyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: isDark
                      ? const Color(0xFF1B1C20)
                      : Colors.white,
                  elevation: 0,
                  titleSpacing: 0,
                  title: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
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
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () {},
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${'app.market.detail.steam_price'.tr}: ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Obx(
                              () => Text(
                                currency.format(referencePrice),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (displayTags?.rarity?.localizedName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRarityColor(
                                displayTags?.rarity?.color,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getRarityColor(
                                  displayTags?.rarity?.color,
                                ).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              displayTags?.rarity?.localizedName ?? '',
                              style: TextStyle(
                                color: _getRarityColor(
                                  displayTags?.rarity?.color,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ..._buildAttributeRows(item),
                        if (_wearOptions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildWearList(currency),
                        ],
                        if (sellNum != null || buyNum != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${sellNum ?? 0}${'app.market.unit_qty'.tr}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'app.trade.onSale.text'.tr,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${buyNum ?? 0}${'app.market.unit_qty'.tr}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'app.trade.purchase.text'.tr,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(
                    TabBar(
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
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF1B1C20)
                        : Colors.white,
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
                  Obx(() => _buildOnSaleTab(currency)),
                  Obx(() => _buildBuyRequestTab(currency)),
                  Obx(() => _buildPriceTrendTab()),
                  Obx(() => _buildTransactionTab(currency)),
                ],
              ),
            ),
          ),
          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26272B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            currency.format(referencePrice),
                            style: const TextStyle(
                              color: Color(0xFFFFB800), // Gold color
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'app.market.price_reference'.tr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _openBuying,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  'app.market.detail.release_purchase'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _openBulkBuying,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4C81E7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'app.market.detail.bulk_buying.title'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: baseColor.withOpacity(0.4)),
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
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
                    color: textColor?.withOpacity(0.8),
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

  Color _getRarityColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return Colors.grey;
    }
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

  Widget _buildOnSaleTab(CurrencyController currency) {
    if (controller.isLoadingOnSale.value && controller.onSaleItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.onSaleItems.isEmpty) {
      return Center(child: Text('app.common.no_data'.tr));
    }
    final showLoadingFooter =
        controller.isLoadingOnSale.value && controller.onSaleItems.isNotEmpty;
    final showNoMoreFooter =
        controller.onSaleItems.isNotEmpty &&
        !controller.isLoadingOnSale.value &&
        !controller.onSaleHasMore;
    final showFooter = showLoadingFooter || showNoMoreFooter;
    // Add padding at bottom for the fixed bottom bar
    return ListView.separated(
      controller: _onSaleScroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: controller.onSaleItems.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= controller.onSaleItems.length) {
          return _buildLoadMoreFooter(
            showLoading: showLoadingFooter,
            showNoMore: showNoMoreFooter,
          );
        }
        final item = controller.onSaleItems[index];
        final user = controller.users[item.userId?.toString() ?? ''];
        return _buildItemCard(item, user, currency);
      },
    );
  }

  Widget _buildItemCard(
    MarketListItem item,
    MarketUserInfo? user,
    CurrencyController currency,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schema = _lookupMarketSchema(item);
    final appId = item.appId ?? controller.appId;
    final imageUrl =
        schema?.imageUrl ?? item.raw['image_url']?.toString() ?? '';
    final title =
        schema?.marketName ??
        schema?.marketHashName ??
        item.marketHashName ??
        '-';
    final tags = schema?.tags;
    final rarity = TagInfo.fromMarketTag(tags?.rarity);
    final quality = TagInfo.fromMarketTag(tags?.quality);
    final exterior = TagInfo.fromMarketTag(tags?.exterior);
    final asset = _resolveAsset(item);
    final paintWearValue = _extractDouble(asset, ['paint_wear', 'paintWear']);
    final paintWearText =
        _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(item.raw, ['paint_wear', 'paintWear']) ??
        paintWearValue?.toString();
    final paintSeed = _extractText(asset, ['paint_seed', 'paintSeed']);
    final phase = _extractText(asset, ['phase']);
    final percentage = _extractText(asset, ['percentage']);
    final stickers = parseStickerList(
      asset?['stickers'] ?? item.raw['stickers'],
      schemaMap: controller.schemas,
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
                    height: 54,
                    child: GameItemImage(
                      imageUrl: imageUrl,
                      appId: appId,
                      rarity: rarity,
                      quality: quality,
                      exterior: exterior,
                      paintSeed: paintSeed,
                      phase: phase,
                      percentage: percentage,
                      paintWearText: paintWearText,
                      stickers: stickers,
                      gems: gems,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            currency.format(item.price ?? 0),
                            style: const TextStyle(
                              color: Color(0xFFFFB800),
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
                    ElevatedButton(
                      onPressed: canBuy ? () => _purchaseItem(item) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C81E7),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('app.trade.buy.text'.tr),
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
              if (gems.isNotEmpty ||
                  stickers.isNotEmpty ||
                  keychains.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (gems.isNotEmpty) GemRow(gems: gems, size: 16),
                      if (gems.isNotEmpty) const SizedBox(width: 6),
                      if (stickers.isNotEmpty)
                        StickerRow(stickers: stickers, size: 16),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Wrap(
          spacing: 8,
          children: [
            _buildDayChip(7, 'app.market.detail.price_trend.seven_days'.tr),
            _buildDayChip(
              30,
              'app.market.detail.price_trend.last_one_month'.tr,
            ),
            _buildDayChip(
              180,
              'app.market.detail.price_trend.last_half_year'.tr,
            ),
            _buildDayChip(365, 'app.market.detail.price_trend.last_year'.tr),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: controller.isLoadingTrend.value
              ? const Center(child: CircularProgressIndicator())
              : PriceTrendChart(points: controller.pricePoints),
        ),
      ],
    );
  }

  Widget _buildBuyRequestTab(CurrencyController currency) {
    if (controller.isLoadingBuyRequests.value &&
        controller.buyRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.buyRequests.isEmpty) {
      return Center(child: Text('app.common.no_data'.tr));
    }
    final showLoadingFooter =
        controller.isLoadingBuyRequests.value &&
        controller.buyRequests.isNotEmpty;
    final showNoMoreFooter =
        controller.buyRequests.isNotEmpty &&
        !controller.isLoadingBuyRequests.value &&
        !controller.buyRequestHasMore;
    final showFooter = showLoadingFooter || showNoMoreFooter;
    return ListView.separated(
      controller: _buyRequestScroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: controller.buyRequests.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= controller.buyRequests.length) {
          return _buildLoadMoreFooter(
            showLoading: showLoadingFooter,
            showNoMore: showNoMoreFooter,
          );
        }
        final item = controller.buyRequests[index];
        final schema = _lookupBuySchema(item);
        final user = _lookupBuyUser(item);
        final avatar = _resolveAvatar(user?.avatar);
        final title =
            schema?.marketName ??
            schema?.marketHashName ??
            item.raw['market_name']?.toString() ??
            '-';
        final imageUrl = schema?.imageUrl ?? '';
        final tags = schema?.raw['tags'];
        final rarity = TagInfo.fromRaw(tags is Map ? tags['rarity'] : null);
        final quality = TagInfo.fromRaw(tags is Map ? tags['quality'] : null);
        final exterior = TagInfo.fromRaw(tags is Map ? tags['exterior'] : null);
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

        return Card(
          color: isDark ? const Color(0xFF26272B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 43,
                  child: GameItemImage(
                    imageUrl: imageUrl,
                    appId: item.appId,
                    rarity: rarity,
                    quality: quality,
                    exterior: exterior,
                    phase: item.phase,
                    count: need > 0 ? need : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Text(
                          currency.format(item.price ?? 0),
                          style: const TextStyle(
                            color: Color(0xFFFFB800),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (wearMinText != null && wearMaxText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${'app.market.csgo.wear'.tr}: '
                            '$wearMinText - $wearMaxText',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${'app.inventory.count'.tr}: $need',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          if ((user?.nickname ?? '').isNotEmpty)
                            Expanded(
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
                                  Get.snackbar(
                                    'app.system.tips.title'.tr,
                                    'app.system.message.nologin'.tr,
                                  );
                                  return;
                                }
                                final result = await Get.toNamed(
                                  Routers.BUYING_SUPPLY,
                                  arguments: {'item': item, 'schema': schema},
                                );
                                if (result == true) {
                                  await controller.loadBuyRequests(reset: true);
                                  await Get.dialog<void>(
                                    AlertDialog(
                                      title: Text('app.system.tips.title'.tr),
                                      content: Text(
                                        'app.trade.supply.message.confirm'.tr,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('app.common.confirm'.tr),
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
                      OutlinedButton(
                        onPressed: () async {
                          await Get.toNamed(
                            Routers.BUYING_UPDATE_PRICE,
                            arguments: {'item': item, 'schema': schema},
                          );
                          await controller.loadBuyRequests(reset: true);
                        },
                        child: Text('app.inventory.price_change'.tr),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton(
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
                            final res = await _shopProductApi
                                .orderItemCancelBuy(id: id);
                            if (res.success) {
                              Get.snackbar(
                                'app.system.tips.title'.tr,
                                'app.system.message.success'.tr,
                              );
                            } else {
                              Get.snackbar(
                                'app.system.tips.title'.tr,
                                res.message.isNotEmpty
                                    ? res.message
                                    : 'app.trade.filter.failed'.tr,
                              );
                            }
                          } catch (_) {
                            Get.snackbar(
                              'app.system.tips.title'.tr,
                              'app.trade.filter.failed'.tr,
                            );
                          }
                          await controller.loadBuyRequests(reset: true);
                        },
                        child: Text('app.common.delete'.tr),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionTab(CurrencyController currency) {
    if (controller.isLoadingTransactions.value &&
        controller.transactionItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.transactionItems.isEmpty) {
      return Center(child: Text('app.common.no_data'.tr));
    }
    final showLoadingFooter =
        controller.isLoadingTransactions.value &&
        controller.transactionItems.isNotEmpty;
    final showNoMoreFooter =
        controller.transactionItems.isNotEmpty &&
        !controller.isLoadingTransactions.value &&
        !controller.transactionHasMore;
    final showFooter = showLoadingFooter || showNoMoreFooter;
    return ListView.builder(
      controller: _transactionScroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: controller.transactionItems.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= controller.transactionItems.length) {
          return _buildLoadMoreFooter(
            showLoading: showLoadingFooter,
            showNoMore: showNoMoreFooter,
          );
        }
        final item = controller.transactionItems[index];
        final user = controller.users[item.userId?.toString() ?? ''];
        final schema = _lookupMarketSchema(item);
        final imageUrl = schema?.imageUrl ?? '';
        final title =
            schema?.marketName ??
            schema?.marketHashName ??
            item.marketHashName ??
            '-';
        final appId = item.appId ?? controller.appId;
        final tags = schema?.tags;
        final rarity = TagInfo.fromMarketTag(tags?.rarity);
        final quality = TagInfo.fromMarketTag(tags?.quality);
        final exterior = TagInfo.fromMarketTag(tags?.exterior);
        final asset = _resolveAsset(item);
        final paintWearValue = _extractDouble(asset, [
          'paint_wear',
          'paintWear',
        ]);
        final paintWearText =
            _extractText(asset, ['paint_wear', 'paintWear']) ??
            _extractText(item.raw, ['paint_wear', 'paintWear']) ??
            paintWearValue?.toString();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          color: isDark ? const Color(0xFF26272B) : Colors.white,
          child: InkWell(
            onTap: () => _openItemDetail(item, schema, user),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                      exterior: exterior,
                      paintWearText: paintWearText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            currency.format(item.price ?? 0),
                            style: const TextStyle(
                              color: Color(0xFFFFB800),
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
      },
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
      await controller.loadOnSale(reset: true);
      await controller.loadTransactions(reset: true);
    }
  }

  Future<void> _purchaseItem(MarketListItem item) async {
    final user = UserStorage.getUserInfo();
    if (user == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.nologin'.tr);
      return;
    }
    final id = item.id?.toString();
    final price = item.price;
    final appId = item.appId ?? controller.appId;
    if (id == null || price == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
      return;
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
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.trade.buy.message.success'.tr,
        );
        await controller.loadOnSale(reset: true);
        await controller.loadTransactions(reset: true);
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, {this.backgroundColor});

  final TabBar _tabBar;
  final Color? backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
