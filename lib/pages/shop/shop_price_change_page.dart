import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class ShopPriceChangePage extends StatefulWidget {
  const ShopPriceChangePage({super.key});

  @override
  State<ShopPriceChangePage> createState() => _ShopPriceChangePageState();
}

class _ShopPriceChangePageState extends State<ShopPriceChangePage> {
  final ApiShopProductServer _api = ApiShopProductServer();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, double> _prices = {};

  late final List<ShopItemAsset> _items;
  late final Map<String, ShopSchemaInfo> _schemas;
  late final int _appId;
  bool _isSubmitting = false;

  static const double _minSellPrice = 0.02;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _items =
        (args['items'] as List?)
            ?.whereType<ShopItemAsset>()
            .where((item) => item.id != null)
            .toList() ??
        <ShopItemAsset>[];
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
    _appId = args['appId'] as int? ?? GameStorage.getGameType();

    for (final item in _items) {
      final id = item.id!;
      final initialPrice = _normalizePrice(item.price ?? 0);
      final initial = initialPrice > 0 ? initialPrice.toStringAsFixed(2) : '';
      _controllers[id] = TextEditingController(text: initial);
      _prices[id] = initialPrice;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ShopSchemaInfo? _lookupSchema(ShopItemAsset item) {
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

  double _extractSellMinForPricing(ShopSchemaInfo? schema) {
    if (schema == null) {
      return 0;
    }
    final raw = schema.raw;

    final sellMin = _parsePriceValue(raw['sell_min']);
    if (sellMin > 0) {
      return _normalizePrice(sellMin);
    }

    return 0;
  }

  double _extractAppraisePrice(ShopSchemaInfo? schema) {
    if (schema == null) {
      return 0;
    }

    final raw = schema.raw;
    final marketPrice = _parsePriceValue(raw['market_price']);
    final buffMinPrice = _parsePriceValue(raw['buff_min_price']);

    if (buffMinPrice > 0 && marketPrice > 0) {
      return _normalizePrice(
        buffMinPrice < marketPrice ? buffMinPrice : marketPrice,
      );
    }
    if (buffMinPrice > 0) {
      return _normalizePrice(buffMinPrice);
    }
    if (marketPrice > 0) {
      return _normalizePrice(marketPrice);
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

  bool _isPriceWarning(ShopItemAsset item, double price) {
    final schema = _lookupSchema(item);
    if (schema == null) {
      return false;
    }
    final sellMin = _parsePriceValue(schema.raw['sell_min']);
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
              Text('${'app.inventory.upshop.nums'.tr}: ${_items.length}'),
              const SizedBox(height: 8),
              Text(
                '${'app.inventory.upshop.expected_income'.tr}: '
                '${currency.format(_totalPrice())}',
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
                SizedBox(
                  width: double.maxFinite,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: warningLines
                            .map(
                              (line) => Text(
                                line,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                            .toList(),
                      ),
                    ),
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

  void _applyReferencePrice() {
    for (final item in _items) {
      final id = item.id!;
      final reference = _extractSellMinForPricing(_lookupSchema(item));
      if (reference <= 0) {
        continue;
      }

      double nextPrice = reference;
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

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final payload = <Map<String, dynamic>>[];
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
      payload.add({'id': id, 'price': price, 'nums': item.count ?? 1});
    }
    if (payload.isEmpty) {
      return;
    }

    final confirmed = await _showSubmitConfirmDialog(
      Map<int, double>.fromEntries(
        payload
            .where((entry) => entry['id'] is int && entry['price'] is num)
            .map(
              (entry) => MapEntry(
                entry['id'] as int,
                (entry['price'] as num).toDouble(),
              ),
            ),
      ),
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _api.orderItemChangePrice(
        appId: _appId,
        items: payload,
      );
      if (res.success) {
        Get.back();
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.system.message.success'.tr,
        );
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
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
        title: Text('app.inventory.price_change'.tr),
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
                final reference = _extractAppraisePrice(schema);
                final controller = _controllers[item.id!]!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, _) => const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, _, __) => const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
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
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      '${'app.inventory.upshop.expected_income'.tr}: '
                      '${currency.format(_totalPrice())}',
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('app.inventory.price_change'.tr),
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
