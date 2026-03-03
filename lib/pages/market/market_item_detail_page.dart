import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class MarketItemDetailPage extends StatefulWidget {
  const MarketItemDetailPage({super.key});

  @override
  State<MarketItemDetailPage> createState() => _MarketItemDetailPageState();
}

class _MarketItemDetailPageState extends State<MarketItemDetailPage> {
  final ApiShopProductServer _shopApi = ApiShopProductServer();

  late final MarketListItem _item;
  MarketSchemaInfo? _schema;
  MarketUserInfo? _user;
  Map<String, MarketSchemaInfo> _schemas = {};
  Map<String, dynamic> _stickers = {};

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _item = _parseItem(args['item']);
    _schema = _parseSchema(args['schema']);
    _user = _parseUser(args['user']);
    _schemas = _parseSchemas(args['schemas']);
    _stickers = _parseStickerMap(args['stickers']);
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
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.trade.buy.message.success'.tr,
        );
        Get.back(result: true);
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
    final title =
        _schema?.marketName ??
        _item.raw['market_name']?.toString() ??
        _item.marketHashName ??
        '-';
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

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
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
          const SizedBox(height: 16),
          if (tagChips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tagChips.map(_buildTagChip).toList(growable: false),
            ),
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
              children: tagChips.map(_buildTagChip).toList(growable: false),
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
          const SizedBox(height: 100),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton(
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
