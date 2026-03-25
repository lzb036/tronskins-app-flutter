import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/notify/notify_trade_deliver_sheet.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletLockedDetailPage extends StatefulWidget {
  const WalletLockedDetailPage({super.key});

  @override
  State<WalletLockedDetailPage> createState() => _WalletLockedDetailPageState();
}

class _WalletLockedDetailPageState extends State<WalletLockedDetailPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final ApiSteamServer _steamApi = ApiSteamServer();

  Map<String, dynamic> args = const {};
  bool _loading = true;
  WalletLockedDetail? _detail;

  @override
  void initState() {
    super.initState();
    args = (Get.arguments as Map<String, dynamic>?) ?? {};
    controller.refreshUser();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = args['id']?.toString();
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final detail = await controller.loadLockedDetail(
      id: id,
      lockType: args['lockType'] as int?,
    );
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success('app.system.message.copy_success'.tr);
  }

  void _showTopSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (isSuccess) {
      AppSnackbar.success(message);
      return;
    }
    if (isError) {
      AppSnackbar.error(message);
      return;
    }
    AppSnackbar.info(message);
  }

  String _currentUserId() {
    return controller.userInfo.value?.id?.trim() ?? '';
  }

  bool _isBuyer(WalletLockedOrder? order) {
    if (order == null) {
      return false;
    }
    final userId = _currentUserId();
    final buyerId = order.buyerId?.trim() ?? '';
    if (userId.isEmpty || buyerId.isEmpty) {
      return false;
    }
    return userId == buyerId;
  }

  bool _isSeller(WalletLockedOrder? order) {
    if (order == null) {
      return false;
    }
    final userId = _currentUserId();
    final sellerId = order.sellerId?.trim() ?? '';
    if (userId.isEmpty || sellerId.isEmpty) {
      return false;
    }
    return userId == sellerId;
  }

  String? _schemaPaintWearText(
    WalletSchemaInfo? schema,
    WalletLockedOrder? order,
  ) {
    final value =
        _pickRawValue(schema?.raw, const ['paint_wear', 'paintWear']) ??
        _pickRawValue(order?.raw, const ['paint_wear', 'paintWear']) ??
        _pickRawValue(_pickRawMap(order?.raw['asset']), const [
          'paint_wear',
          'paintWear',
        ]) ??
        _pickRawValue(_pickRawMap(order?.raw['csgoAsset']), const [
          'paint_wear',
          'paintWear',
        ]);
    if (value != null) {
      return value.toString();
    }
    return schema?.paintWear?.toString();
  }

  double? _schemaPaintWearValue(
    WalletSchemaInfo? schema,
    WalletLockedOrder? order,
  ) {
    return _asDouble(
          _pickRawValue(schema?.raw, const ['paint_wear', 'paintWear']),
        ) ??
        _asDouble(
          _pickRawValue(order?.raw, const ['paint_wear', 'paintWear']),
        ) ??
        _asDouble(
          _pickRawValue(_pickRawMap(order?.raw['asset']), const [
            'paint_wear',
            'paintWear',
          ]),
        ) ??
        _asDouble(
          _pickRawValue(_pickRawMap(order?.raw['csgoAsset']), const [
            'paint_wear',
            'paintWear',
          ]),
        ) ??
        schema?.paintWear;
  }

  TagInfo? _schemaTag(WalletSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  int _resolveAppId(WalletSchemaInfo? schema, WalletLockedOrder? order) {
    final rawAsset = _pickRawMap(order?.raw['asset']);
    final rawCsgoAsset = _pickRawMap(order?.raw['csgoAsset']);
    return schema?.appId ??
        order?.appId ??
        _asInt(_pickRawValue(schema?.raw, const ['app_id', 'appId'])) ??
        _asInt(_pickRawValue(order?.raw, const ['app_id', 'appId'])) ??
        _asInt(_pickRawValue(rawAsset, const ['app_id', 'appId'])) ??
        _asInt(_pickRawValue(rawCsgoAsset, const ['app_id', 'appId'])) ??
        GameStorage.getGameType();
  }

  String _resolveImageUrl(WalletSchemaInfo? schema, WalletLockedOrder? order) {
    final rawAsset = _pickRawMap(order?.raw['asset']);
    final rawCsgoAsset = _pickRawMap(order?.raw['csgoAsset']);
    return schema?.imageUrl ??
        _pickRawText(schema?.raw, const [
          'image_url',
          'imageUrl',
          'icon_url',
          'iconUrl',
          'image',
        ]) ??
        _pickRawText(order?.raw, const [
          'image_url',
          'imageUrl',
          'icon_url',
          'iconUrl',
          'image',
        ]) ??
        _pickRawText(rawAsset, const [
          'image_url',
          'imageUrl',
          'icon_url',
          'iconUrl',
          'image',
        ]) ??
        _pickRawText(rawCsgoAsset, const [
          'image_url',
          'imageUrl',
          'icon_url',
          'iconUrl',
          'image',
        ]) ??
        '';
  }

  List<GameItemSticker> _schemaStickers(
    WalletSchemaInfo? schema,
    WalletLockedOrder? order,
  ) {
    final rawAsset = _pickRawMap(order?.raw['asset']);
    final rawCsgoAsset = _pickRawMap(order?.raw['csgoAsset']);
    final stickerRaw =
        _pickRawValue(schema?.raw, const ['stickers']) ??
        _pickRawValue(order?.raw, const ['stickers']) ??
        _pickRawValue(rawAsset, const ['stickers']) ??
        _pickRawValue(rawCsgoAsset, const ['stickers']);
    return parseStickerList(stickerRaw, stickerMap: _detail?.stickers);
  }

  Map? _pickRawMap(dynamic value) {
    if (value is Map) {
      return value;
    }
    return null;
  }

  dynamic _pickRawValue(dynamic source, List<String> keys) {
    if (source is! Map) {
      return null;
    }
    for (final key in keys) {
      final value = source[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String? _pickRawText(dynamic source, List<String> keys) {
    final value = _pickRawValue(source, keys);
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  Future<void> _openDeliverDrawer(WalletLockedOrder order) async {
    final buyerId = order.buyerId?.trim() ?? '';
    if (buyerId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }
    await showNotifyTradeDeliverSheet(
      context,
      buyerId: buyerId,
      status: order.status,
      onDelivered: () {
        _loadDetail();
      },
    );
  }

  Future<void> _receiveGoods(WalletLockedOrder order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.trade.receipt.message.confirm_auto'.tr),
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

    final orderId = order.id?.toString() ?? '';
    if (orderId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }

    try {
      final steamStatus = await _steamApi.steamOnlineState();
      if (steamStatus.datas != true) {
        final tradeOfferId = order.tradeOfferId ?? '';
        if (tradeOfferId.isNotEmpty) {
          Get.toNamed(
            Routers.RECEIVE_GOODS,
            arguments: {'tradeOfferId': tradeOfferId},
          );
        } else {
          _showTopSnack('app.trade.filter.failed'.tr, isError: true);
        }
        return;
      }

      final response = await _shopApi.tradeofferReceipt(id: orderId);
      if (response.success) {
        _showTopSnack(
          response.message.isNotEmpty
              ? response.message
              : 'app.system.message.success'.tr,
          isSuccess: true,
        );
        await _loadDetail();
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              Get.back();
            }
          });
        }
      } else {
        _showTopSnack(
          response.message.isNotEmpty
              ? response.message
              : 'app.trade.filter.failed'.tr,
          isError: true,
        );
      }
    } catch (_) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
    }
  }

  Future<void> _cancelOrder(WalletLockedOrder order) async {
    final orderId = order.id?.toString() ?? '';
    if (orderId.isEmpty) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
      return;
    }

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final changeTime = order.changeTime ?? order.createTime ?? 0;
    final isCancelTimeLess =
        changeTime > 0 && (nowSeconds - changeTime).abs() <= 1800;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.trade.order.cancel'.tr),
        content: Text(
          isCancelTimeLess
              ? 'app.trade.order.message.cancel_time_less'.tr
              : 'app.trade.order.message.confirm_cancel'.tr,
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
      final response = await _shopApi.cancelOrder(id: orderId);
      if (response.success) {
        _showTopSnack('app.system.message.success'.tr, isSuccess: true);
        await _loadDetail();
        if (mounted) {
          Get.back();
        }
        return;
      }
      _showTopSnack(
        response.message.isNotEmpty
            ? response.message
            : 'app.trade.filter.failed'.tr,
        isError: true,
      );
    } catch (_) {
      _showTopSnack('app.trade.filter.failed'.tr, isError: true);
    }
  }

  Widget? _buildBottomActions() {
    final order = _detail?.order;
    if (order == null) {
      return null;
    }
    final status = order.status ?? -999;
    final isSeller = _isSeller(order);
    final isBuyer = _isBuyer(order);

    final actions = <Widget>[];
    if (isSeller && status == 2) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _openDeliverDrawer(order),
            child: Text('app.market.product.deliver'.tr),
          ),
        ),
      );
    }
    if (isBuyer && status == 4) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: () => _receiveGoods(order),
            child: Text('app.market.product.receive'.tr),
          ),
        ),
      );
    }
    if (isBuyer && status == 2) {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelOrder(order),
            child: Text('app.trade.order.cancel'.tr),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        backgroundColor: WalletUi.pageBackground(context),
        appBar: AppBar(
          title: Text('app.trade.order.details'.tr),
          actions: [
            IconButton(
              tooltip: 'app.user.menu.feedback'.tr,
              onPressed: () => Get.toNamed(Routers.FEEDBACK_LIST),
              icon: const Icon(Icons.headset_mic_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _detail == null
            ? Center(child: Text('app.common.no_data'.tr))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOrderInfo(currency),
                  const SizedBox(height: 16),
                  _buildAssetInfo(currency),
                  const SizedBox(height: 16),
                  _buildTips(),
                ],
              ),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  Widget _buildOrderInfo(CurrencyController currency) {
    final order = _detail?.order;
    final orderId = order?.id?.toString() ?? '-';
    final price = currency.formatUsd(order?.price ?? 0);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CopyInfoRow(
              label: 'app.trade.order.number'.tr,
              value: orderId,
              onCopy: orderId == '-' ? null : () => _copy(orderId),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    '${'app.trade.order.total_price'.tr}:',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    price,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetInfo(CurrencyController currency) {
    final schema = _detail?.schema;
    final order = _detail?.order;
    final name = schema?.marketName ?? schema?.marketHashName ?? '-';
    final sellMin = schema?.sellMin;
    final buyMax = schema?.buyMax;
    final paintWearText = _schemaPaintWearText(schema, order);
    final paintWear = _schemaPaintWearValue(schema, order);
    final stickers = _schemaStickers(schema, order);
    final appId = _resolveAppId(schema, order);
    final imageUrl = _resolveImageUrl(schema, order);
    final rarity = _schemaTag(schema, 'rarity');
    final quality = _schemaTag(schema, 'quality');
    final exterior = _schemaTag(schema, 'exterior');
    final phase = _pickRawText(schema?.raw, const ['phase']);
    final percentage = _pickRawText(schema?.raw, const ['percentage']);
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  height: 66,
                  child: GameItemImage(
                    imageUrl: imageUrl,
                    appId: appId,
                    rarity: rarity,
                    quality: quality,
                    exterior: exterior,
                    phase: phase,
                    percentage: percentage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (sellMin != null)
                        Text(
                          '${'app.market.detail.sale_lowest'.tr} '
                          '${currency.formatUsd(sellMin)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (buyMax != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${'app.market.detail.purchase_highest'.tr} '
                            '${currency.formatUsd(buyMax)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (paintWearText != null && paintWearText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${'app.market.csgo.abradability'.tr}: $paintWearText'),
            ],
            if (paintWear != null) ...[
              const SizedBox(height: 6),
              WearProgressBar(paintWear: paintWear),
            ],
            if (stickers.isNotEmpty) ...[
              const SizedBox(height: 10),
              StickerRow(stickers: stickers, size: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    final tips = [
      'app.trade.order.buyer_tips_1'.tr,
      'app.trade.order.buyer_tips_2'.tr,
      'app.trade.order.buyer_tips_3'.tr,
      'app.trade.order.buyer_tips_4'.tr,
    ];
    return Card(
      elevation: 0,
      shape: WalletUi.cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.system.tips.warm'.tr,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < tips.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. ${tips[i]}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CopyInfoRow extends StatelessWidget {
  const _CopyInfoRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium;
    final valueLineHeight =
        ((valueStyle?.fontSize ?? 14) * (valueStyle?.height ?? 1.35)) + 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: valueLineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: valueStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onCopy,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('app.common.copy'.tr),
          ),
        ],
      ],
    );
  }
}
