import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

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
  double _feeRate = 0;
  double _minFee = 0;
  bool _loadingParams = true;
  bool _isSubmitting = false;
  bool _showOverview = false;
  final Set<int> _expandedDetailIds = <int>{};

  static const double _minSellPrice = 0.02;

  bool _isDetailExpanded(int id) {
    return _expandedDetailIds.contains(id);
  }

  void _toggleDetailExpanded(int id) {
    setState(() {
      if (_expandedDetailIds.contains(id)) {
        _expandedDetailIds.remove(id);
      } else {
        _expandedDetailIds.add(id);
      }
    });
  }

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

    Future.microtask(_loadParams);
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

  Map<String, dynamic>? _resolveAsset(ShopItemAsset item) {
    return item.asset ?? item.raw;
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

  String? _extractWearText(ShopItemAsset item, Map<String, dynamic>? asset) {
    return _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(item.raw, ['paint_wear', 'paintWear']);
  }

  double? _extractWearValue(ShopItemAsset item, Map<String, dynamic>? asset) {
    final text = _extractWearText(item, asset);
    if (text != null) {
      final parsed = double.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
    }
    return _extractDouble(asset, ['paint_wear', 'paintWear']) ??
        _extractDouble(item.raw, ['paint_wear', 'paintWear']);
  }

  bool _itemHasWarning(ShopItemAsset item) {
    final id = item.id;
    if (id == null) {
      return false;
    }
    final price = _prices[id] ?? 0;
    return price > 0 && _isPriceWarning(item, price);
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

  Future<void> _loadParams() async {
    try {
      final res = await _api.getSysParams();
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
                '${'app.inventory.upshop.handling_charge'.tr}: '
                '${currency.format(_totalFee())}',
              ),
              const SizedBox(height: 8),
              Text(
                '${'app.inventory.upshop.expected_income'.tr}: '
                '${currency.format(_totalIncome())}',
              ),
              const SizedBox(height: 8),
              Text(
                '${'app.inventory.upshop.expected_reward'.tr}: '
                '${_totalRewardPoints()} ${'app.user.integral.unit'.tr}',
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

  double _totalFee() {
    final total = _totalPrice();
    if (total <= 0) {
      return 0;
    }
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

  int _pointsFromAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      return 0;
    }
    return amount.floor();
  }

  int _totalRewardPoints() {
    return _pointsFromAmount(_totalPrice());
  }

  double _totalAppraise() {
    double total = 0;
    for (final item in _items) {
      final reference = _extractAppraisePrice(_lookupSchema(item));
      if (reference <= 0) {
        continue;
      }
      total += reference * (item.count ?? 1);
    }
    return total;
  }

  int _itemCount(ShopItemAsset item) {
    return item.count ?? 1;
  }

  double _itemTotalPrice(ShopItemAsset item) {
    final id = item.id;
    if (id == null) {
      return 0;
    }
    final price = _prices[id] ?? 0;
    return price * _itemCount(item);
  }

  double _itemAppraise(ShopItemAsset item) {
    final reference = _extractAppraisePrice(_lookupSchema(item));
    if (reference <= 0) {
      return 0;
    }
    return reference * _itemCount(item);
  }

  double _itemFee(ShopItemAsset item) {
    if (_loadingParams) {
      return 0;
    }
    final total = _itemTotalPrice(item);
    if (total <= 0) {
      return 0;
    }
    final fee = total * _feeRate;
    if (fee < _minFee) {
      return _minFee;
    }
    return fee;
  }

  double _itemIncome(ShopItemAsset item) {
    if (_loadingParams) {
      return 0;
    }
    final total = _itemTotalPrice(item);
    if (total <= 0) {
      return 0;
    }
    return total - _itemFee(item);
  }

  int _itemRewardPoints(ShopItemAsset item) {
    return _pointsFromAmount(_itemTotalPrice(item));
  }

  Future<void> _showImagePreview({
    required String title,
    required Widget preview,
  }) async {
    final previewWidth = MediaQuery.of(context).size.width - 64;
    final maxPreviewHeight = MediaQuery.of(context).size.height * 0.62;
    final previewHeight = (previewWidth * 0.62)
        .clamp(180.0, maxPreviewHeight)
        .toDouble();
    await Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: SizedBox(
                        width: previewWidth,
                        height: previewHeight,
                        child: preview,
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

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final payload = <Map<String, dynamic>>[];
    for (final item in _items) {
      final id = item.id!;
      final price = _prices[id] ?? 0;
      if (price <= 0) {
        AppSnackbar.error('app.inventory.message.price_and_num_error'.tr);
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
        Get.back(result: true);
        AppSnackbar.success('app.system.message.success'.tr);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSummaryStat({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, CurrencyController currency) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.22 : 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final amountStyle = Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
            final feeText = _loadingParams
                ? '--'
                : currency.format(_totalFee());

            if (constraints.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      label: 'app.inventory.upshop.nums'.tr,
                      value: Text('${_items.length}', style: amountStyle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      label: 'app.inventory.upshop.handling_charge'.tr,
                      value: Text(
                        feeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: amountStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.insights_outlined,
                      label: 'app.inventory.price_appraise'.tr,
                      value: Obx(
                        () => Text(
                          currency.format(_totalAppraise()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: amountStyle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.payments_outlined,
                      label: 'app.inventory.upshop.expected_income'.tr,
                      value: Obx(
                        () => Text(
                          currency.format(_totalIncome()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: amountStyle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.stars_rounded,
                      label: 'app.inventory.upshop.expected_reward'.tr,
                      value: Text(
                        '${_totalRewardPoints()} ${'app.user.integral.unit'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: amountStyle,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.inventory_2_outlined,
                        label: 'app.inventory.upshop.nums'.tr,
                        value: Text('${_items.length}', style: amountStyle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.receipt_long_outlined,
                        label: 'app.inventory.upshop.handling_charge'.tr,
                        value: Text(
                          feeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: amountStyle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.insights_outlined,
                        label: 'app.inventory.price_appraise'.tr,
                        value: Obx(
                          () => Text(
                            currency.format(_totalAppraise()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: amountStyle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.payments_outlined,
                        label: 'app.inventory.upshop.expected_income'.tr,
                        value: Obx(
                          () => Text(
                            currency.format(_totalIncome()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: amountStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.stars_rounded,
                        label: 'app.inventory.upshop.expected_reward'.tr,
                        value: Text(
                          '${_totalRewardPoints()} ${'app.user.integral.unit'.tr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: amountStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemStatCell({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    CurrencyController currency,
    ShopItemAsset item,
  ) {
    final id = item.id;
    if (id == null) {
      return const SizedBox.shrink();
    }
    final schema = _lookupSchema(item);
    final imageUrl = item.imageUrl ?? schema?.imageUrl ?? '';
    final title =
        item.marketName ?? schema?.marketName ?? item.marketHashName ?? '-';
    final tags = schema?.raw['tags'];
    final rarity = TagInfo.fromRaw(tags is Map ? tags['rarity'] : null);
    final quality = TagInfo.fromRaw(tags is Map ? tags['quality'] : null);
    final exterior = TagInfo.fromRaw(tags is Map ? tags['exterior'] : null);
    final asset = _resolveAsset(item);
    final stickers = parseStickerList(
      asset?['stickers'] ?? item.raw['stickers'],
      schemaMap: _schemas,
    );
    final gems = parseGemList(
      asset?['gemList'] ??
          asset?['gems'] ??
          item.raw['gemList'] ??
          item.raw['gems'],
    );
    final wearValue = _extractWearValue(item, asset);
    final wearText = _extractWearText(item, asset);
    final paintSeed = _extractText(asset, ['paint_seed', 'paintSeed']);
    final phase = _extractText(asset, ['phase']);
    final percentage = _extractText(asset, ['percentage']);
    final controller = _controllers[id]!;
    final showWarning = _itemHasWarning(item);
    final itemCount = _itemCount(item);
    final itemAppraise = _itemAppraise(item);
    final itemFee = _itemFee(item);
    final itemIncome = _itemIncome(item);
    final rewardPoints = _itemRewardPoints(item);
    final colorScheme = Theme.of(context).colorScheme;
    final detailsExpanded = _isDetailExpanded(id);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: imageUrl.isEmpty
                      ? null
                      : () => _showImagePreview(
                          title: title,
                          preview: GameItemImage(
                            imageUrl: imageUrl,
                            appId: item.appId,
                            rarity: rarity,
                            quality: quality,
                            exterior: exterior,
                            paintSeed: paintSeed,
                            phase: phase,
                            percentage: percentage,
                            paintWearText: wearText,
                            count: itemCount,
                            stickers: stickers,
                            gems: gems,
                          ),
                        ),
                  child: Container(
                    width: 118,
                    height: 76,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GameItemImage(
                            imageUrl: imageUrl,
                            appId: item.appId,
                            rarity: rarity,
                            quality: quality,
                            exterior: exterior,
                            paintSeed: paintSeed,
                            phase: phase,
                            percentage: percentage,
                            count: itemCount,
                            stickers: stickers,
                            gems: gems,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_out_map_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (wearValue != null && wearText != null) ...[
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'app.inventory.price_selling'.tr,
                hintText: 'app.inventory.selling_placeholder'.tr,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    currency.currentCurrencyIcon,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        currency.symbol,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _handlePriceChanged(id, value),
              onEditingComplete: () => _normalizeInputOnBlur(id),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _toggleDetailExpanded(id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.38,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          detailsExpanded
                              ? 'app.inventory.upshop.listing_details_collapse'
                                    .tr
                              : 'app.inventory.upshop.listing_details_expand'
                                    .tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        turns: detailsExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: detailsExpanded ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 8.0;
                            final itemWidth =
                                (constraints.maxWidth - spacing) / 2;
                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildItemStatCell(
                                    context: context,
                                    icon: Icons.inventory_2_outlined,
                                    label: 'app.inventory.upshop.nums'.tr,
                                    value: '$itemCount',
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildItemStatCell(
                                    context: context,
                                    icon: Icons.insights_outlined,
                                    label: 'app.inventory.price_appraise'.tr,
                                    value: currency.format(itemAppraise),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildItemStatCell(
                                    context: context,
                                    icon: Icons.receipt_long_outlined,
                                    label:
                                        'app.inventory.upshop.handling_charge'
                                            .tr,
                                    value: _loadingParams
                                        ? '--'
                                        : currency.format(itemFee),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildItemStatCell(
                                    context: context,
                                    icon: Icons.payments_outlined,
                                    label:
                                        'app.inventory.upshop.expected_income'
                                            .tr,
                                    value: _loadingParams
                                        ? '--'
                                        : currency.format(itemIncome),
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _buildItemStatCell(
                                    context: context,
                                    icon: Icons.stars_rounded,
                                    label:
                                        'app.inventory.upshop.expected_reward'
                                            .tr,
                                    value:
                                        '$rewardPoints ${'app.user.integral.unit'.tr}',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (showWarning) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'app.inventory.pricing_abnormal'.tr,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final colorScheme = Theme.of(context).colorScheme;
    final incomeText = _loadingParams ? '--' : currency.format(_totalIncome());
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app.inventory.upshop.expected_income'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    incomeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('app.inventory.price_change'.tr),
                      ],
                    )
                  : Text('app.inventory.price_change'.tr),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final primaryActionColor = theme.colorScheme.primary;
    final actionLabelStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: primaryActionColor,
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leadingWidth: 40,
        titleSpacing: 4,
        title: Text(
          'app.inventory.price_change'.tr,
          maxLines: 1,
          softWrap: false,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: TextButton(
              onPressed: () {
                setState(() => _showOverview = !_showOverview);
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryActionColor,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'app.inventory.view_overview'.tr,
                style: actionLabelStyle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TextButton(
              onPressed: _applyReferencePrice,
              style: TextButton.styleFrom(
                foregroundColor: primaryActionColor,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('app.inventory.pricing'.tr, style: actionLabelStyle),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _showOverview ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showOverview ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _buildHeaderCard(context, currency),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return KeyedSubtree(
                  key: ValueKey(item.id ?? index),
                  child: _buildPriceCard(context, currency, item),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
}
