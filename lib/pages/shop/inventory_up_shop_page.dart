import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/controllers/inventory/inventory_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class InventoryUpShopPage extends StatefulWidget {
  const InventoryUpShopPage({super.key});

  @override
  State<InventoryUpShopPage> createState() => _InventoryUpShopPageState();
}

class _InventoryUpShopPageState extends State<InventoryUpShopPage> {
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final ApiSteamServer _steamApi = ApiSteamServer();
  final InventoryController _inventoryController =
      Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, double> _prices = {};

  late final List<InventoryItem> _items;
  late final Map<String, ShopSchemaInfo> _schemas;

  double _feeRate = 0;
  double _minFee = 0;
  bool _loadingParams = true;
  bool _isSubmitting = false;

  static const double _minSellPrice = 0.02;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _items =
        (args['items'] as List?)
            ?.whereType<InventoryItem>()
            .where((item) => item.id != null)
            .toList() ??
        <InventoryItem>[];
    final rawSchemas = args['schemas'];
    final schemaMap = <String, ShopSchemaInfo>{};
    if (rawSchemas is Map) {
      rawSchemas.forEach((key, value) {
        if (value is ShopSchemaInfo) {
          schemaMap[key.toString()] = value;
        }
      });
    }
    _schemas = schemaMap;

    for (final item in _items) {
      final id = item.id!;
      _controllers[id] = TextEditingController();
      _prices[id] = 0;
    }

    Future.microtask(_loadParams);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ShopSchemaInfo? _lookupSchema(InventoryItem item) {
    final hash = item.marketHashName;
    if (hash != null && _schemas.containsKey(hash)) {
      return _schemas[hash];
    }
    final key = item.schemaId?.toString();
    if (key != null && _schemas.containsKey(key)) {
      return _schemas[key];
    }
    return null;
  }

  Map<String, dynamic>? _resolveAsset(InventoryItem item) {
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

  double _parsePriceValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _truncateTo2(double value) {
    return (value * 100).floor() / 100;
  }

  double _normalizePrice(double value) {
    if (!value.isFinite || value <= 0) {
      return 0;
    }
    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded < _minSellPrice) {
      return _minSellPrice;
    }
    return rounded;
  }

  void _handlePriceChanged(int id, String value) {
    if (value.isEmpty) {
      _prices[id] = 0;
      setState(() {});
      return;
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      _prices[id] = 0;
      setState(() {});
      return;
    }

    final decimal = value.split('.');
    if (decimal.length == 2 && decimal[1].length > 2) {
      final normalized = _truncateTo2(parsed);
      final text = normalized.toStringAsFixed(2);
      final controller = _controllers[id];
      if (controller != null && controller.text != text) {
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.fromPosition(
            TextPosition(offset: text.length),
          ),
        );
      }
      _prices[id] = normalized;
      setState(() {});
      return;
    }

    _prices[id] = parsed;
    setState(() {});
  }

  void _normalizeInputOnBlur(int id) {
    final controller = _controllers[id];
    if (controller == null) {
      return;
    }
    final text = controller.text;
    if (text.endsWith('.')) {
      final normalizedText = text.substring(0, text.length - 1);
      controller.value = TextEditingValue(
        text: normalizedText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: normalizedText.length),
        ),
      );
    }
    _prices[id] = double.tryParse(controller.text) ?? 0;
    setState(() {});
  }

  double _extractReference(ShopSchemaInfo? schema) {
    if (schema == null) {
      return 0;
    }
    final raw = schema.raw;

    final sellMin = _parsePriceValue(raw['sell_min']);
    final buffMinPrice = _parsePriceValue(raw['buff_min_price']);
    if (sellMin > 0) {
      if (buffMinPrice > 0) {
        final minPrice = buffMinPrice < sellMin ? buffMinPrice : sellMin;
        return _normalizePrice(minPrice);
      }
      return _normalizePrice(sellMin);
    }

    final candidates = [
      raw['reference_price'],
      raw['buff_min_price'],
      raw['market_price'],
    ];
    for (final value in candidates) {
      final parsed = _parsePriceValue(value);
      if (parsed > 0) {
        return _normalizePrice(parsed);
      }
    }
    return 0;
  }

  Future<void> _loadParams() async {
    try {
      final res = await _shopApi.getSysParams();
      if (res.success && res.datas != null) {
        final data = res.datas!;
        _feeRate = (data['fee'] as num?)?.toDouble() ?? 0;
        _minFee = (data['minFeeAmount'] as num?)?.toDouble() ?? 0;
      }
    } finally {
      if (mounted) {
        setState(() => _loadingParams = false);
      }
    }
  }

  double _totalPrice() {
    double total = 0;
    for (final item in _items) {
      final id = item.id!;
      final price = _prices[id] ?? 0;
      final count = item.count ?? 1;
      total += price * count;
    }
    return total;
  }

  double _totalFee() {
    final total = _totalPrice();
    final fee = total * _feeRate;
    if (fee < _minFee) {
      return _minFee;
    }
    return fee;
  }

  double _totalIncome() {
    final total = _totalPrice();
    final fee = _totalFee();
    return total - fee;
  }

  int _totalCount() {
    int count = 0;
    for (final item in _items) {
      count += item.count ?? 1;
    }
    return count;
  }

  void _applyReferencePrice() {
    for (final item in _items) {
      final id = item.id!;
      final referencePrice = _extractReference(_lookupSchema(item));
      if (referencePrice <= 0) {
        continue;
      }

      double nextPrice = referencePrice;
      if (nextPrice > 1000) {
        nextPrice -= 0.5;
      } else if (nextPrice > 100) {
        nextPrice -= 0.1;
      } else if (nextPrice > _minSellPrice) {
        nextPrice -= 0.01;
      } else {
        nextPrice = _minSellPrice;
      }

      final normalizedPrice = _normalizePrice(nextPrice);
      if (normalizedPrice <= 0) {
        continue;
      }
      _prices[id] = normalizedPrice;
      _controllers[id]?.text = normalizedPrice.toStringAsFixed(2);
    }
    setState(() {});
  }

  bool _isPriceWarning(InventoryItem item, double price) {
    final schema = _lookupSchema(item);
    if (schema == null) {
      return false;
    }
    final rawSellMin = schema.raw['sell_min'];
    final sellMin = rawSellMin is num
        ? rawSellMin.toDouble()
        : double.tryParse(rawSellMin?.toString() ?? '') ?? 0;
    return sellMin > 10 && price < sellMin * 0.9;
  }

  Future<bool> _showSubmitConfirmDialog(Map<int, double> payload) async {
    final currency = Get.find<CurrencyController>();
    final warningLines = <String>[];

    for (final item in _items) {
      final id = item.id;
      if (id == null) {
        continue;
      }
      final price = payload[id];
      if (price == null) {
        continue;
      }
      if (_isPriceWarning(item, price)) {
        final schema = _lookupSchema(item);
        final title =
            item.marketName ??
            schema?.marketName ??
            item.marketHashName ??
            '#$id';
        warningLines.add('$title  ${currency.format(price)}');
      }
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.inventory.upshop.confirm_title'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'app.inventory.upshop.nums'.tr}: ${_totalCount()}'),
              const SizedBox(height: 8),
              Text(
                '${'app.inventory.upshop.handling_charge'.tr}: '
                '${currency.format(_totalFee())}',
              ),
              const SizedBox(height: 8),
              Text(
                '${'app.inventory.upshop.expected_income'.tr}: '
                '${currency.format(_totalIncome())}',
              ),
              if (warningLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'app.inventory.pricing_abnormal'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: warningLines.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          warningLines[index],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
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

    return confirmed == true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final payload = <int, double>{};
    for (final item in _items) {
      final id = item.id!;
      final price = _prices[id] ?? 0;
      if (price <= 0) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.inventory.message.price_and_num_error'.tr,
        );
        return;
      }
      payload[id] = price;
    }
    if (payload.isEmpty) {
      return;
    }

    final confirmed = await _showSubmitConfirmDialog(payload);
    if (!confirmed) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final steamStatus = await _steamApi.steamOnlineState();
      if (steamStatus.datas != true) {
        await Get.dialog<void>(
          AlertDialog(
            title: Text('app.system.tips.title'.tr),
            content: Text('app.steam.session.expired'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('app.common.cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routers.STEAM_SESSION);
                },
                child: Text('app.common.confirm'.tr),
              ),
            ],
          ),
        );
        return;
      }

      final submitRes = await _inventoryController.submitUpShopItems(payload);
      final submitCode = submitRes.code;
      final dynamicData = submitRes.datas;
      final dataText = dynamicData?.toString().trim();
      final submitText = (dataText?.isNotEmpty ?? false)
          ? dataText!
          : (submitRes.message.trim().isNotEmpty
                ? submitRes.message
                : 'app.trade.filter.failed'.tr);

      if (submitCode == 0 || submitCode == 200) {
        Get.back();
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.system.message.success'.tr,
        );
        return;
      }

      Get.snackbar('app.system.tips.title'.tr, submitText);
    } catch (_) {
      Get.snackbar('app.system.tips.title'.tr, 'app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('app.inventory.upshop.text'.tr),
        actions: [
          TextButton(
            onPressed: _applyReferencePrice,
            child: Text('app.inventory.pricing'.tr),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final schema = _lookupSchema(item);
                final imageUrl = item.imageUrl ?? schema?.imageUrl ?? '';
                final title =
                    item.marketName ??
                    schema?.marketName ??
                    item.marketHashName ??
                    '-';
                final reference = _extractReference(schema);
                final controller = _controllers[item.id!]!;
                final tags = schema?.raw['tags'];
                final rarity = TagInfo.fromRaw(
                  tags is Map ? tags['rarity'] : null,
                );
                final quality = TagInfo.fromRaw(
                  tags is Map ? tags['quality'] : null,
                );
                final exterior = TagInfo.fromRaw(
                  tags is Map ? tags['exterior'] : null,
                );
                final asset = _resolveAsset(item);
                final stickers = parseStickerList(
                  asset?['stickers'] ?? item.raw['stickers'],
                );
                final gems = parseGemList(
                  asset?['gemList'] ??
                      asset?['gems'] ??
                      item.raw['gemList'] ??
                      item.raw['gems'],
                );
                final wearValue =
                    item.paintWear ??
                    _extractDouble(asset, ['paint_wear', 'paintWear']);
                final wearText = wearValue?.toStringAsFixed(4);
                final paintSeed =
                    item.paintSeed ??
                    _extractText(asset, ['paint_seed', 'paintSeed']);
                final phase = item.phase ?? _extractText(asset, ['phase']);
                final percentage = _extractText(asset, ['percentage']);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                paintSeed: paintSeed,
                                phase: phase,
                                percentage: percentage,
                                count: item.count,
                                stickers: stickers,
                                gems: gems,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, maxLines: 2),
                                  const SizedBox(height: 4),
                                  if (reference > 0)
                                    Obx(
                                      () => Text(
                                        '${'app.inventory.price_appraise'.tr}: '
                                        '${currency.format(reference)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (wearValue != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${'app.market.csgo.abradability'.tr}: $wearText',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          WearProgressBar(paintWear: wearValue),
                        ],
                        if (stickers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          StickerRow(stickers: stickers, size: 18),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'app.inventory.price_selling'.tr,
                            hintText: 'app.inventory.selling_placeholder'.tr,
                          ),
                          onChanged: (value) =>
                              _handlePriceChanged(item.id!, value),
                          onEditingComplete: () =>
                              _normalizeInputOnBlur(item.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${'app.inventory.upshop.nums'.tr}: ${_totalCount()}',
                      ),
                      const Spacer(),
                      if (!_loadingParams)
                        Obx(
                          () => Text(
                            '${'app.inventory.upshop.handling_charge'.tr}: '
                            '${currency.format(_totalFee())}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Obx(
                        () => Text(
                          '${'app.inventory.upshop.expected_income'.tr}: '
                          '${currency.format(_totalIncome())}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('app.inventory.upshop.text'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
