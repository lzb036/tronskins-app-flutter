import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';

class BuyingUpdatePricePage extends StatefulWidget {
  const BuyingUpdatePricePage({super.key});

  @override
  State<BuyingUpdatePricePage> createState() => _BuyingUpdatePricePageState();
}

class _BuyingUpdatePricePageState extends State<BuyingUpdatePricePage> {
  final ApiShopProductServer _api = ApiShopProductServer();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _numController = TextEditingController();

  late final BuyRequestItem _item;
  Map<String, dynamic> _schemaRaw = {};
  double _minPrice = 0;
  bool _isSubmitting = false;

  static const double _minTradePrice = 0.02;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final rawItem = args['item'];
    if (rawItem is BuyRequestItem) {
      _item = rawItem;
    } else if (rawItem is Map) {
      _item = BuyRequestItem.fromJson(Map<String, dynamic>.from(rawItem));
    } else {
      _item = BuyRequestItem(raw: const {});
    }

    final rawSchema = args['schema'];
    if (rawSchema is ShopSchemaInfo) {
      _schemaRaw = rawSchema.raw;
    } else if (rawSchema is Map) {
      _schemaRaw = Map<String, dynamic>.from(rawSchema);
    }

    _priceController.text = _normalizeDisplayPrice(_item.price ?? 0);
    _numController.text = (_item.nums ?? 0).toString();
    _loadParams();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _numController.dispose();
    super.dispose();
  }

  Future<void> _loadParams() async {
    final res = await _api.getSysParams();
    final raw = res.datas;
    if (raw is Map<String, dynamic>) {
      final minValue = raw['minPrice'];
      if (minValue is num) {
        _minPrice = max(minValue.toDouble(), _minTradePrice);
      } else {
        _minPrice = max(
          double.tryParse(minValue?.toString() ?? '') ?? 0,
          _minTradePrice,
        );
      }
    }
  }

  double _sellMin() {
    final sellMin = _parseDouble(_schemaRaw['sell_min']);
    final buffMin = _parseDouble(_schemaRaw['buff_min_price']);
    final candidates = [
      sellMin,
      buffMin,
    ].whereType<double>().where((value) => value > 0).toList();
    if (candidates.isEmpty) {
      return 0;
    }
    final minMarket = candidates.reduce(min);
    return minMarket > _minTradePrice ? minMarket : _minTradePrice;
  }

  double _buyMax() {
    return _parseDouble(_schemaRaw['buy_max']) ?? 0;
  }

  double _truncateTo2(double value) {
    return (value * 100).floor() / 100;
  }

  String _normalizeDisplayPrice(double value) {
    if (value <= 0) {
      return '';
    }
    final normalized = _truncateTo2(value);
    return normalized.toStringAsFixed(2);
  }

  double _getPricingRules(double buyMaxPrice) {
    if (buyMaxPrice <= 0) {
      return 0;
    }
    double newPrice = 0;
    if (buyMaxPrice <= 10 && buyMaxPrice > 0) {
      newPrice = buyMaxPrice + 0.01;
    }
    if (buyMaxPrice > 10 && buyMaxPrice <= 100) {
      newPrice = buyMaxPrice + 0.1;
    }
    if (buyMaxPrice > 100) {
      newPrice = buyMaxPrice + 0.5;
    }
    final rounded = double.parse(newPrice.toStringAsFixed(2));
    return rounded < _minTradePrice ? _minTradePrice : rounded;
  }

  double _totalAmount() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final num = int.tryParse(_numController.text) ?? 0;
    return price * num;
  }

  void _applyMaxPrice() {
    final value = _getPricingRules(_buyMax());
    if (value <= 0) {
      return;
    }
    _priceController.text = value.toStringAsFixed(2);
    _priceController.selection = TextSelection.fromPosition(
      TextPosition(offset: _priceController.text.length),
    );
  }

  void _sanitizePrice(String value) {
    if (value.isEmpty) {
      return;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return;
    }
    var normalized = parsed;
    if (normalized < _minTradePrice) {
      normalized = _minTradePrice;
      _priceController.text = normalized.toStringAsFixed(2);
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
      return;
    }
    final parts = value.split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      final truncated = _truncateTo2(normalized);
      _priceController.text = truncated.toStringAsFixed(2);
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
    }
  }

  void _normalizePriceOnBlur() {
    final text = _priceController.text;
    if (text.isEmpty) {
      return;
    }
    if (text.endsWith('.')) {
      final normalizedText = text.substring(0, text.length - 1);
      _priceController.text = normalizedText;
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
    }
    final price = double.tryParse(_priceController.text);
    if (price == null) {
      return;
    }
    if (price < _minTradePrice) {
      _priceController.text = _minTradePrice.toStringAsFixed(2);
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
    }
  }

  void _sanitizeNum(String value) {
    if (value.contains('.')) {
      final integer = value.split('.').first;
      _numController.text = integer;
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
    }
    final numValue = int.tryParse(_numController.text) ?? 0;
    if (numValue > 200) {
      _numController.text = '200';
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final price = double.tryParse(_priceController.text) ?? 0;
    final nums = int.tryParse(_numController.text) ?? 0;
    if (price <= 0 || nums <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.filter.message.price_error'.tr,
      );
      return;
    }
    final effectiveMinPrice = _minPrice > 0 ? _minPrice : _minTradePrice;
    if (price < effectiveMinPrice) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.message.min_price_error'.tr,
      );
      return;
    }
    final sellMin = _sellMin();
    final shouldConfirm = price >= 10 && sellMin > 0 && price > sellMin;
    if (shouldConfirm) {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('app.system.tips.title'.tr),
          content: Text('app.trade.purchase.message.confirm_to_buy'.tr),
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
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await _api.myBuyUpdatePrice(
        items: [
          {'id': _item.id, 'price': price, 'nums': nums},
        ],
      );
      if (!res.success) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
        return;
      }
      Get.back(result: true);
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.inventory.message.price_change_success'.tr,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final imageUrl = _schemaRaw['image_url']?.toString() ?? '';
    final title =
        _schemaRaw['market_name']?.toString() ??
        _schemaRaw['market_hash_name']?.toString() ??
        '-';
    final wearMin = _item.paintWearMin;
    final wearMax = _item.paintWearMax;
    return Scaffold(
      appBar: AppBar(
        title: Text('app.trade.purchase.price_change'.tr),
        actions: [
          TextButton(
            onPressed: _applyMaxPrice,
            child: Text('app.inventory.pricing'.tr),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => const SizedBox(
                        width: 72,
                        height: 72,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, _, __) =>
                          const Icon(Icons.image_not_supported_outlined),
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
                        ),
                        if (wearMin != null && wearMax != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${'app.market.filter.csgo.wear_interval'.tr}: '
                              '${wearMin.toStringAsFixed(2)} - '
                              '${wearMax.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () => Text(
                            currency.format(_sellMin()),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'app.market.detail.sale_lowest'.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () => Text(
                            currency.format(_buyMax()),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'app.market.detail.purchase_highest'.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'app.trade.purchase.price'.tr,
              hintText: 'app.trade.purchase.placeholder_price'.tr,
            ),
            onChanged: _sanitizePrice,
            onEditingComplete: _normalizePriceOnBlur,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'app.trade.purchase.num'.tr,
              hintText: 'app.trade.purchase.placeholder_num'.tr,
            ),
            onChanged: _sanitizeNum,
          ),
          const SizedBox(height: 12),
          Text(
            '1.${'app.trade.purchase.buyer_notice_1'.tr}'
            '${'app.trade.purchase.buyer_notice_2'.tr}'
            '${'app.trade.purchase.buyer_notice_3'.tr}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '2.${'app.trade.purchase.buyer_notice_4'.tr}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => Text(
                  '${'app.trade.purchase.payable'.tr}: '
                  '${currency.format(_totalAmount())}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('app.common.confirm'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
