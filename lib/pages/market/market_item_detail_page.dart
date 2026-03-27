import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/common/widgets/glass_notice_dialog.dart';
import 'package:tronskins_app/common/widgets/steam_style_confirm_dialog.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/game_item_utils.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class MarketItemDetailPage extends StatefulWidget {
  const MarketItemDetailPage({super.key});

  @override
  State<MarketItemDetailPage> createState() => _MarketItemDetailPageState();
}

enum _ShopMetricType { successRate, averageTime, notShipped }

class _MarketItemDetailPageState extends State<MarketItemDetailPage> {
  final ApiMarketServer _marketServer = ApiMarketServer();
  final ApiShopServer _shopServer = ApiShopServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();

  late MarketListItem _item;
  MarketSchemaInfo? _schema;
  MarketUserInfo? _user;
  Map<String, MarketSchemaInfo> _schemas = {};
  Map<String, dynamic> _stickers = {};
  Map<String, dynamic>? _shopInfo;
  bool _loadingShopInfo = false;
  bool _shopStatsIsWeek = true;
  bool _isPurchasing = false;
  bool _favorited = false;
  bool _favoriteSubmitting = false;
  bool _refreshingStickers = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _item = _parseItem(args['item']);
    _schema = _parseSchema(args['schema']);
    _user = _parseUser(args['user']);
    _schemas = _parseSchemas(args['schemas']);
    _stickers = _parseStickerMap(args['stickers']);
    _favorited = _item.favorited == true;
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

  List<GameItemSticker> _parseStickers(Map<String, dynamic>? asset) {
    for (final candidate in _stickerCandidates(asset)) {
      final parsed = parseStickerList(
        _normalizeStickerEntries(candidate),
        schemaMap: _schemas,
        stickerMap: _stickers,
      );
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return const [];
  }

  List<_StickerDetailData> _resolveStickerDetailsFromItem(
    Map<String, dynamic>? asset,
  ) {
    for (final candidate in _stickerCandidates(asset)) {
      final details = _resolveStickerDetails(candidate);
      if (details.isNotEmpty) {
        return details;
      }
    }
    return const [];
  }

  List<dynamic> _stickerCandidates(Map<String, dynamic>? asset) {
    final rawAsset =
        _asMap(_item.raw['asset']) ?? _asMap(_item.raw['itemAsset']);
    final rawCsgoAsset =
        _asMap(_item.raw['csgoAsset']) ?? _asMap(_item.raw['csgo_asset']);
    final rawTf2Asset =
        _asMap(_item.raw['tf2Asset']) ?? _asMap(_item.raw['tf2_asset']);
    final rawDotaAsset =
        _asMap(_item.raw['dota2Asset']) ?? _asMap(_item.raw['dota2_asset']);

    return <dynamic>[
      asset?['stickers'],
      asset?['stickerList'],
      asset?['sticker_list'],
      asset?['sticker'],
      rawAsset?['stickers'],
      rawAsset?['stickerList'],
      rawAsset?['sticker_list'],
      rawAsset?['sticker'],
      rawCsgoAsset?['stickers'],
      rawCsgoAsset?['stickerList'],
      rawCsgoAsset?['sticker_list'],
      rawCsgoAsset?['sticker'],
      rawTf2Asset?['stickers'],
      rawTf2Asset?['stickerList'],
      rawTf2Asset?['sticker_list'],
      rawTf2Asset?['sticker'],
      rawDotaAsset?['stickers'],
      rawDotaAsset?['stickerList'],
      rawDotaAsset?['sticker_list'],
      rawDotaAsset?['sticker'],
      _item.raw['stickers'],
      _item.raw['stickerList'],
      _item.raw['sticker_list'],
      _item.raw['sticker'],
    ];
  }

  List<_StickerDetailData> _resolveStickerDetails(dynamic raw) {
    final entries = _normalizeStickerEntries(raw);
    final details = <_StickerDetailData>[];
    for (final entry in entries) {
      final detail = _resolveStickerDetail(entry);
      if (detail != null) {
        details.add(detail);
      }
    }
    return details;
  }

  List<dynamic> _normalizeStickerEntries(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Iterable) {
      return raw.toList(growable: false);
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
      return raw.values.toList(growable: false);
    }
    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty || value == 'null') {
        return const [];
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
      return <dynamic>[value];
    }
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  _StickerDetailData? _resolveStickerDetail(dynamic entry) {
    String? imageUrl;
    String? name;
    double? price;
    String? stickerId;

    if (entry is Map) {
      imageUrl = _extractText(entry, <String>[
        'image_url',
        'imageUrl',
        'image',
      ]);
      name = _extractText(entry, <String>['market_name', 'marketName', 'name']);
      price = _extractDouble(entry, <String>[
        'market_price',
        'marketPrice',
        'price',
      ]);
      stickerId = _extractText(entry, <String>[
        'sticker_id',
        'stickerId',
        'schema_id',
        'schemaId',
        'id',
      ]);
    } else if (entry is num || entry is String) {
      final value = entry.toString().trim();
      if (value.isEmpty) {
        return null;
      }
      if (RegExp(r'^\d+$').hasMatch(value)) {
        stickerId = value;
      } else {
        imageUrl = value;
      }
    }

    final schema = stickerId == null ? null : _schemas[stickerId];
    final stickerMeta = stickerId == null
        ? null
        : _resolveStickerMeta(stickerId);
    imageUrl ??=
        _extractText(stickerMeta, <String>['image_url', 'imageUrl', 'image']) ??
        schema?.imageUrl;
    name ??=
        _extractText(stickerMeta, <String>[
          'market_name',
          'marketName',
          'name',
        ]) ??
        schema?.marketName;
    price ??=
        _extractDouble(stickerMeta, <String>[
          'market_price',
          'marketPrice',
          'price',
        ]) ??
        _extractDouble(schema?.raw, <String>[
          'market_price',
          'marketPrice',
          'price',
        ]);

    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    return _StickerDetailData(
      imageUrl: _normalizeSteamImageUrl(imageUrl),
      name: name,
      price: price,
    );
  }

  Map<String, dynamic>? _resolveStickerMeta(String stickerId) {
    dynamic value;
    if (_stickers.containsKey(stickerId)) {
      value = _stickers[stickerId];
    }
    if (value == null) {
      for (final entry in _stickers.entries) {
        if (entry.key.toString() == stickerId) {
          value = entry.value;
          break;
        }
      }
    }
    if (value is MarketSchemaInfo) {
      return value.raw;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _normalizeSteamImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://community.steamstatic.com/economy/image/$url';
  }

  Future<void> _purchase() async {
    if (_isPurchasing) {
      return;
    }
    final user = UserStorage.getUserInfo();
    if (user == null) {
      AppSnackbar.info('app.system.message.nologin'.tr);
      return;
    }
    final id = _item.id?.toString();
    final price = _item.price;
    final appId = _item.appId ?? _schema?.appId ?? 730;
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
    if (!mounted) {
      return;
    }
    setState(() => _isPurchasing = true);
    try {
      final res = await _shopApi.orderItemPurchase(
        appId: appId,
        id: id,
        price: price,
      );
      final datas = res.datas;
      if (datas is String) {
        if (datas.contains('Steam issue')) {
          AppSnackbar.error('app.steam.message.trading_restrictions'.tr);
          return;
        }
        if (datas.contains('Inventory privacy')) {
          final nickname = user.config?.nickname ?? user.nickname ?? '';
          AppSnackbar.error('${'app.inventory.message.privacy'.tr}$nickname');
          return;
        }
      }
      if (res.success) {
        Get.back(result: true);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty
              ? res.message
              : (datas is String && datas.trim().isNotEmpty
                    ? datas
                    : 'app.trade.filter.failed'.tr),
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteSubmitting) {
      return;
    }
    if (UserStorage.getUserInfo() == null) {
      await Get.toNamed(Routers.LOGIN);
      return;
    }
    final itemId = _item.id;
    final appId = _item.appId ?? _schema?.appId ?? 730;
    if (itemId == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }
    setState(() => _favoriteSubmitting = true);
    try {
      final res = _favorited
          ? await _marketServer.removeFavorite(itemId: itemId)
          : await _marketServer.addFavorite(appId: appId, itemId: itemId);
      if (!res.success) {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      setState(() => _favorited = !_favorited);
      AppSnackbar.success(
        (_favorited
                ? 'app.user.collection.message.success'
                : 'app.user.collection.uncollect_success')
            .tr,
      );
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _favoriteSubmitting = false);
      }
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

  Future<void> _refreshStickerData() async {
    if (_refreshingStickers) {
      return;
    }
    final schemaId = _item.schemaId ?? _schema?.schemaId;
    final sellerId = _item.userId;
    final appId = _item.appId ?? _schema?.appId ?? 730;
    if (schemaId == null || sellerId == null) {
      await _showRefreshNotice(
        message: 'app.trade.filter.failed'.tr,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _refreshingStickers = true);
    try {
      final useAuth = UserStorage.getUserInfo() != null;
      final res = await _marketServer.onSaleList(
        appId: appId,
        schemaId: schemaId,
        userId: sellerId,
        page: 1,
        pageSize: 100,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
      );
      final data = res.datas;
      if (!mounted) {
        return;
      }
      if (!res.success || data == null) {
        await _showRefreshNotice(
          message: 'app.trade.filter.failed'.tr,
          icon: Icons.error_outline_rounded,
        );
        return;
      }

      final refreshedItem = data.items
          .where((item) => item.id == _item.id)
          .cast<MarketListItem?>()
          .firstWhere((item) => item != null, orElse: () => null);

      setState(() {
        if (refreshedItem != null) {
          _item = refreshedItem;
          _favorited = refreshedItem.favorited == true;
        }
        _schemas = <String, MarketSchemaInfo>{..._schemas, ...data.schemas};
        _stickers = <String, dynamic>{..._stickers, ...data.stickers};

        final schemaKey = (refreshedItem?.schemaId ?? schemaId).toString();
        final hashKey = refreshedItem?.marketHashName;
        _schema =
            data.schemas[schemaKey] ??
            ((hashKey != null && data.schemas.containsKey(hashKey))
                ? data.schemas[hashKey]
                : _schema);

        final userKey = sellerId.toString();
        _user = data.users[userKey] ?? _user;
      });

      await _showRefreshNotice(
        message: 'app.steam.message.refresh_info_success'.tr,
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (_) {
      if (mounted) {
        await _showRefreshNotice(
          message: 'app.trade.filter.failed'.tr,
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingStickers = false);
      }
    }
  }

  Future<void> _showRefreshNotice({
    required String message,
    required IconData icon,
  }) async {
    if (!mounted) {
      return;
    }
    await showGlassNoticeDialog(
      context,
      message: message,
      icon: icon,
      barrierLabel: 'market_item_detail_refresh_notice',
    );
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

  bool get _isEnglishLocale =>
      (Get.locale?.languageCode ?? '').toLowerCase().startsWith('en');

  bool get _isChineseLocale =>
      (Get.locale?.languageCode ?? '').toLowerCase().startsWith('zh');

  String _stickerSectionTitle() =>
      _isChineseLocale ? '包含印花' : 'Containing Stickers';

  String _stickerFallbackName(int index) =>
      _isChineseLocale ? '印花 ${index + 1}' : 'Sticker ${index + 1}';

  String _shopDaysLabel(int days) {
    if (_isEnglishLocale) {
      return days == 1 ? '$days Day' : '$days Days';
    }
    return '$days${'app.common.day'.tr}';
  }

  String _shopDeliverLabel() {
    return 'app.user.shop.deliver'.tr;
  }

  String _shopMetricLabel(_ShopMetricType type, int days) {
    final dayLabel = _shopDaysLabel(days);
    switch (type) {
      case _ShopMetricType.successRate:
        return _isEnglishLocale
            ? '${'app.user.shop.deliver_rate_success'.tr} · $dayLabel'
            : '${'app.user.shop.deliver_rate_success'.tr}/$dayLabel';
      case _ShopMetricType.averageTime:
        return _isEnglishLocale
            ? '${'app.user.shop.deliver_time_average'.tr} · $dayLabel'
            : '${'app.user.shop.deliver_time_average'.tr}/$dayLabel';
      case _ShopMetricType.notShipped:
        return _isEnglishLocale
            ? '${'app.user.shop.undelivered_times'.tr} · $dayLabel'
            : '${'app.user.shop.undelivered_times'.tr}/$dayLabel';
    }
  }

  String _shopUndeliveredValue(int count) {
    if (_isEnglishLocale) {
      return count == 1 ? '$count Time' : '$count Times';
    }
    return '$count${'app.common.times'.tr}';
  }

  String _formatAverageDelivery(double avgMinutes) {
    final minutes = avgMinutes.isNaN || avgMinutes.isInfinite
        ? 0
        : avgMinutes.round();
    if (_isEnglishLocale) {
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remain = minutes % 60;
        final hourText = hours == 1 ? '$hours Hour' : '$hours Hours';
        if (remain == 0) {
          return hourText;
        }
        final minuteText = remain == 1 ? '$remain Minute' : '$remain Minutes';
        return '$hourText $minuteText';
      }
      return minutes == 1 ? '$minutes Minute' : '$minutes Minutes';
    }
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

  Widget _buildAppBarIconButton({
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 24,
      splashRadius: 24,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: icon,
    );
  }

  Widget _buildShopMetricRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
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
            _shopDaysLabel(days),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.02),
          theme.cardColor,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
          const SizedBox(height: 12),
          Material(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _showShopDeliverTips,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _shopDeliverLabel(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _buildShopMetricRow(
                icon: Icons.check_circle_outline_rounded,
                label: _shopMetricLabel(_ShopMetricType.successRate, days),
                value: _deliverySuccessRate(total: nums, notSend: notSend),
              ),
              const SizedBox(height: 8),
              _buildShopMetricRow(
                icon: Icons.schedule_rounded,
                label: _shopMetricLabel(_ShopMetricType.averageTime, days),
                value: _formatAverageDelivery(avg),
              ),
              const SizedBox(height: 8),
              _buildShopMetricRow(
                icon: Icons.inventory_2_outlined,
                label: _shopMetricLabel(_ShopMetricType.notShipped, days),
                value: _shopUndeliveredValue(notSend),
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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

  Widget _buildStickerInfoCard({
    required List<_StickerDetailData> stickers,
    required bool isRefreshing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.secondary.withValues(alpha: 0.04),
          theme.cardColor,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _stickerSectionTitle(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: isRefreshing ? null : _refreshStickerData,
                tooltip: 'app.common.refresh'.tr,
                iconSize: 20,
                splashRadius: 20,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isRefreshing)
            Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                  child: _buildStickerLoadingRow(),
                ),
              ),
            )
          else
            for (var i = 0; i < stickers.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildStickerDetailRow(sticker: stickers[i], index: i),
            ],
        ],
      ),
    );
  }

  Widget _buildStickerDetailRow({
    required _StickerDetailData sticker,
    required int index,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = sticker.name?.trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CachedNetworkImage(
              imageUrl: sticker.imageUrl,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, _) => const SizedBox.expand(),
              errorWidget: (context, _, __) => Icon(
                Icons.image_not_supported_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (title != null && title.isNotEmpty)
                      ? title
                      : _stickerFallbackName(index),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerLoadingRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeroImage({
    required String imageUrl,
    required TagInfo? rarity,
  }) {
    return SizedBox(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    final stickers = _parseStickers(asset);
    final stickerDetails = _resolveStickerDetailsFromItem(asset);
    final displayStickerDetails = stickerDetails.isNotEmpty
        ? stickerDetails
        : stickers
              .map((sticker) => _StickerDetailData(imageUrl: sticker.imageUrl))
              .toList(growable: false);
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

    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: _buildAppBarIconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
          ),
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
          actions: !isOwnOnSale
              ? [
                  _buildAppBarIconButton(
                    onPressed: _favoriteSubmitting ? null : _toggleFavorite,
                    icon: _favoriteSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _favorited ? Icons.favorite : Icons.favorite_border,
                          ),
                  ),
                ]
              : const [],
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
                  if (_refreshingStickers ||
                      displayStickerDetails.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStickerInfoCard(
                      stickers: displayStickerDetails,
                      isRefreshing: _refreshingStickers,
                    ),
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
                color: Colors.black.withValues(alpha: 0.08),
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
                        color: colorScheme.primary,
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
                      : FilledButton(
                          onPressed:
                              _item.id != null &&
                                  _item.price != null &&
                                  !_isPurchasing
                              ? _purchase
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(96, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isPurchasing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text('app.trade.buy.text'.tr),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerDetailData {
  const _StickerDetailData({required this.imageUrl, this.name, this.price});

  final String imageUrl;
  final String? name;
  final double? price;
}
