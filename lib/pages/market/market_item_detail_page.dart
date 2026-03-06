import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/game_item_utils.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class MarketItemDetailPage extends StatefulWidget {
  const MarketItemDetailPage({super.key});

  @override
  State<MarketItemDetailPage> createState() => _MarketItemDetailPageState();
}

class _MarketItemDetailPageState extends State<MarketItemDetailPage> {
  final ApiShopServer _shopServer = ApiShopServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();

  late final MarketListItem _item;
  MarketSchemaInfo? _schema;
  MarketUserInfo? _user;
  Map<String, MarketSchemaInfo> _schemas = {};
  Map<String, dynamic> _stickers = {};
  Map<String, dynamic>? _shopInfo;
  bool _loadingShopInfo = false;
  bool _shopStatsIsWeek = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _item = _parseItem(args['item']);
    _schema = _parseSchema(args['schema']);
    _user = _parseUser(args['user']);
    _schemas = _parseSchemas(args['schemas']);
    _stickers = _parseStickerMap(args['stickers']);
    _loadShopInfo();
  }

  MarketListItem _parseItem(dynamic raw) {
    if (raw is MarketListItem) {
      return raw;
    }
    if (raw is Map) {
      return MarketListItem.fromJson(Map<String, dynamic>.from(raw));
    }
    return const MarketListItem(raw: {});
  }

  MarketSchemaInfo? _parseSchema(dynamic raw) {
    if (raw is MarketSchemaInfo) {
      return raw;
    }
    if (raw is Map) {
      return MarketSchemaInfo.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  MarketUserInfo? _parseUser(dynamic raw) {
    if (raw is MarketUserInfo) {
      return raw;
    }
    if (raw is Map) {
      return MarketUserInfo.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Map<String, MarketSchemaInfo> _parseSchemas(dynamic raw) {
    if (raw is Map) {
      final map = <String, MarketSchemaInfo>{};
      raw.forEach((key, value) {
        if (value is MarketSchemaInfo) {
          map[key.toString()] = value;
        } else if (value is Map) {
          map[key.toString()] = MarketSchemaInfo.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
      return map;
    }
    return {};
  }

  Map<String, dynamic> _parseStickerMap(dynamic raw) {
    if (raw is Map) {
      final map = <String, dynamic>{};
      raw.forEach((key, value) {
        map[key.toString()] = value;
      });
      return map;
    }
    return {};
  }

  Map<String, dynamic>? _resolveAsset() {
    final raw = _item.raw;
    if (_item.appId == 730 && raw['csgoAsset'] is Map<String, dynamic>) {
      return raw['csgoAsset'] as Map<String, dynamic>;
    }
    if (_item.appId == 440 && raw['tf2Asset'] is Map<String, dynamic>) {
      return raw['tf2Asset'] as Map<String, dynamic>;
    }
    if (_item.appId == 570 && raw['dota2Asset'] is Map<String, dynamic>) {
      return raw['dota2Asset'] as Map<String, dynamic>;
    }
    return raw is Map<String, dynamic> ? raw : null;
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

  bool _isOwnOnSaleItem() {
    if (_item.own == true) {
      return true;
    }
    final currentUser = UserStorage.getUserInfo();
    final currentUserId = _asInt(currentUser?.id);
    final currentShopId = _asInt(currentUser?.shop?.id);
    final sellerId = _item.userId;
    if (sellerId == null) {
      return false;
    }
    return sellerId == currentUserId || sellerId == currentShopId;
  }

  List<GameItemSticker> _parseKeychains(dynamic raw) {
    final fromRaw = parseStickerList(
      raw,
      schemaMap: _schemas,
      stickerMap: _stickers,
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
          final schema = _schemas[schemaId.toString()];
          final url = schema?.imageUrl;
          if (url != null && url.isNotEmpty) {
            list.add(GameItemSticker(url));
          }
        }
      } else if (entry is num || entry is String) {
        final schema = _schemas[entry.toString()];
        final url = schema?.imageUrl;
        if (url != null && url.isNotEmpty) {
          list.add(GameItemSticker(url));
        }
      }
    }
    return list;
  }

  Future<void> _purchase() async {
    final user = UserStorage.getUserInfo();
    if (user == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.nologin'.tr);
      return;
    }
    final id = _item.id?.toString();
    final price = _item.price;
    final appId = _item.appId ?? _schema?.appId ?? 730;
    if (id == null || price == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
      return;
    }
    final currency = Get.find<CurrencyController>();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('${'app.trade.buy.pay_text'.tr} ${currency.format(price)}'),
        content: Text(
          '${'app.trade.buy.pay_text_2'.tr} ${price.floor()}\n'
          '${'app.trade.buy.pay_text_3'.tr}',
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
    if (confirmed != true) {
      return;
    }
    try {
      final res = await _shopApi.orderItemPurchase(
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
        Get.back(result: true);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    }
  }

  String? _resolveSellerUuid() {
    final fromUser = _user?.uuid?.trim();
    if (fromUser != null && fromUser.isNotEmpty) {
      return fromUser;
    }
    final fromRawUser = _item.raw['user'];
    if (fromRawUser is Map) {
      final uuid = fromRawUser['uuid']?.toString().trim();
      if (uuid != null && uuid.isNotEmpty) {
        return uuid;
      }
    }
    final fromRaw = _item.raw['uuid']?.toString().trim();
    if (fromRaw != null && fromRaw.isNotEmpty) {
      return fromRaw;
    }
    return null;
  }

  String _resolveAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return '';
    }
    if (avatar.startsWith('http')) {
      return avatar;
    }
    return 'https://www.tronskins.com/fms/image$avatar';
  }

  Future<void> _loadShopInfo() async {
    final uuid = _resolveSellerUuid();
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    if (mounted) {
      setState(() => _loadingShopInfo = true);
    }
    try {
      final res = await _shopServer.getUserShopInfo(params: {'uuid': uuid});
      if (!mounted) {
        return;
      }
      if (res.success && res.datas != null) {
        setState(() => _shopInfo = res.datas);
      }
    } catch (_) {
      // Ignore failures here. Shop info is supplemental content.
    } finally {
      if (mounted) {
        setState(() => _loadingShopInfo = false);
      }
    }
  }

  int _shopMetricInt(String key) => _asInt(_shopInfo?[key]) ?? 0;

  double _shopMetricDouble(String key) =>
      _extractDouble(_shopInfo, <String>[key]) ?? 0;

  String _deliverySuccessRate({required int total, required int notSend}) {
    if (total <= 0) {
      return '0%';
    }
    final rate = ((total - notSend) / total * 100).clamp(0, 100);
    return '${rate.toStringAsFixed(2)}%';
  }

  String _formatAverageDelivery(double avgMinutes) {
    final minutes = avgMinutes.isNaN || avgMinutes.isInfinite
        ? 0
        : avgMinutes.round();
    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remain = minutes % 60;
      return '$hours${'app.common.hours'.tr}$remain${'app.common.minutes'.tr}';
    }
    return '$minutes${'app.common.minutes'.tr}';
  }

  void _showShopDeliverTips() {
    Get.dialog<void>(
      AlertDialog(
        title: Text('app.system.tips.warm'.tr),
        content: Text('app.user.shop.message.order_placed'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('app.user.shop.deliver_iknow'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildShopMetricRow({required String label, required String value}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDaysToggle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildItem({required bool isWeek, required int days}) {
      final active = _shopStatsIsWeek == isWeek;
      return InkWell(
        onTap: () {
          if (_shopStatsIsWeek == isWeek) {
            return;
          }
          setState(() => _shopStatsIsWeek = isWeek);
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$days${'app.common.day'.tr}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: active
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildItem(isWeek: true, days: 7),
          const SizedBox(width: 2),
          buildItem(isWeek: false, days: 30),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (_loadingShopInfo) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final shopInfo = _shopInfo;
    if (shopInfo == null || shopInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    final isWeek = _shopStatsIsWeek;
    final days = isWeek ? 7 : 30;
    final avgKey = isWeek ? 'last7daysAvg' : 'last30daysAvg';
    final numsKey = isWeek ? 'last7daysNums' : 'last30daysNums';
    final notSendKey = isWeek ? 'last7daysNotSend' : 'last30daysNotSend';

    final avg = _shopMetricDouble(avgKey);
    final nums = _shopMetricInt(numsKey);
    final notSend = _shopMetricInt(notSendKey);

    final fallbackName = _user?.nickname?.trim();
    final shopName =
        _extractText(shopInfo, <String>['name', 'shopName']) ??
        ((fallbackName != null && fallbackName.isNotEmpty)
            ? fallbackName
            : '-');
    final avatar = _resolveAvatarUrl(
      _extractText(shopInfo, <String>['avatar']) ?? _user?.avatar,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Icon(
                        Icons.storefront_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildShopDaysToggle(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showShopDeliverTips,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'app.user.shop.deliver'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _buildShopMetricRow(
                      label:
                          '${'app.user.shop.deliver_rate_success'.tr}/$days${'app.common.day'.tr}',
                      value: _deliverySuccessRate(
                        total: nums,
                        notSend: notSend,
                      ),
                    ),
                    _buildShopMetricRow(
                      label:
                          '${'app.user.shop.deliver_time_average'.tr}/$days${'app.common.day'.tr}',
                      value: _formatAverageDelivery(avg),
                    ),
                    _buildShopMetricRow(
                      label:
                          '${'app.user.shop.undelivered_times'.tr}/$days${'app.common.day'.tr}',
                      value: '$notSend${'app.common.times'.tr}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(TagInfo tag) {
    final color = _parseHex(tag.color) ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        tag.label ?? '',
        style: TextStyle(
          color: color,
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

  Widget _buildTopHeroImage({
    required String imageUrl,
    required TagInfo? rarity,
  }) {
    return Container(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            rarityBgAsset(rarity?.color),
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => Image.asset(
              'assets/images/game/item/b0c3d9.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 220,
                    fit: BoxFit.contain,
                    placeholder: (context, _) =>
                        const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget: (context, _, __) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final appId = _item.appId ?? _schema?.appId ?? 730;
    final asset = _resolveAsset();
    final imageUrl =
        _schema?.imageUrl ??
        _extractText(asset, ['image_url', 'imageUrl']) ??
        _item.raw['image_url']?.toString() ??
        '';
    final tags = _schema?.tags;
    final rarity = TagInfo.fromMarketTag(tags?.rarity);
    final quality = TagInfo.fromMarketTag(tags?.quality);
    final exterior = TagInfo.fromMarketTag(tags?.exterior);
    final type = TagInfo.fromMarketTag(tags?.type);
    final hero = TagInfo.fromMarketTag(tags?.hero);
    final slot = TagInfo.fromMarketTag(tags?.slot);
    final itemSet = TagInfo.fromMarketTag(tags?.itemSet);

    final paintSeed = _extractText(asset, ['paint_seed', 'paintSeed']);
    final percentage = _extractText(asset, ['percentage']);
    final paintIndex = _extractText(asset, ['paint_index', 'paintIndex']);
    final phase = _extractText(asset, ['phase']);
    final tier = _extractText(asset, ['tier']);
    final fireIce = _extractText(asset, ['fire_ice', 'fireIce']);
    final paintWearValue = _extractDouble(asset, ['paint_wear', 'paintWear']);
    final paintWearText =
        _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(_item.raw, ['paint_wear', 'paintWear']) ??
        paintWearValue?.toString();

    final stickers = parseStickerList(
      asset?['stickers'] ?? _item.raw['stickers'],
      schemaMap: _schemas,
      stickerMap: _stickers,
    );
    final gems = parseGemList(
      asset?['gemList'] ??
          asset?['gems'] ??
          _item.raw['gemList'] ??
          _item.raw['gems'],
    );
    final keychains = _parseKeychains(
      asset?['keychains'] ?? _item.raw['keychains'],
    );

    final tagChips = <TagInfo>[];
    if (appId == 570) {
      if (hero != null) tagChips.add(hero);
      if (slot != null) tagChips.add(slot);
      if (type != null) tagChips.add(type);
    } else {
      if (type != null) tagChips.add(type);
      if (rarity != null) tagChips.add(rarity);
      if (quality != null) tagChips.add(quality);
    }
    final isOwnOnSale = _isOwnOnSaleItem();

    return Scaffold(
      appBar: AppBar(
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
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildTopHeroImage(imageUrl: imageUrl, rarity: rarity),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appId == 570 && hero?.label?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'app.market.dota2.hero_use'.tr}: ${hero?.label ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (appId == 730) ...[
                  if (paintSeed != null || percentage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${'app.market.csgo.paint_index'.tr}: '
                      '${paintSeed ?? ''}'
                      '${percentage != null ? ' (${percentage.endsWith('%') ? percentage : '$percentage%'})' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (paintIndex != null ||
                      phase != null ||
                      tier != null ||
                      fireIce != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'app.market.detail.skin_number'.tr}: '
                      '${paintIndex ?? ''}'
                      '${phase != null ? ' ($phase)' : ''}'
                      '${tier != null ? ' ($tier)' : ''}'
                      '${fireIce != null ? ' ($fireIce)' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (paintWearValue != null && paintWearText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${'app.market.csgo.abradability'.tr}: $paintWearText',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    WearProgressBar(paintWear: paintWearValue),
                  ],
                ],
                if (gems.isNotEmpty && (appId == 570 || appId == 440)) ...[
                  const SizedBox(height: 12),
                  Text(
                    'app.market.filter.dota2.gemstones_contains'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  GemRow(gems: gems, size: 24),
                ],
                if (stickers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  StickerRow(stickers: stickers, size: 24),
                ],
                if (keychains.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  StickerRow(stickers: keychains, size: 24),
                ],
                if (tags != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'app.market.detail.attribute'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tagChips
                        .map(_buildTagChip)
                        .toList(growable: false),
                  ),
                  if (exterior?.label?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'app.market.filter.appearance'.tr}: ${exterior?.label ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (itemSet?.label?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      itemSet?.label ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
                if (_loadingShopInfo || (_shopInfo?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  _buildShopInfoCard(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Text(
                    currency.format(_item.price ?? 0),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: isOwnOnSale
                    ? const SizedBox.shrink()
                    : ElevatedButton(
                        onPressed: _item.id != null && _item.price != null
                            ? _purchase
                            : null,
                        child: Text('app.trade.buy.text'.tr),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
