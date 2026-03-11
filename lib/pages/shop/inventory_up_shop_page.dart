import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/controllers/inventory/inventory_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class _InventoryMergeGroup {
  _InventoryMergeGroup(this.key, InventoryItem first) : items = [first];

  final String key;
  final List<InventoryItem> items;
}

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
  bool _showOverview = false;
  bool _mergeSameItems = false;
  final Set<String> _expandedDetailKeys = <String>{};

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

  int? _parseIntValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  MarketItemEntity _toMarketDetailItem(InventoryItem item) {
    final schema = _lookupSchema(item);
    final schemaId = item.schemaId ?? _parseIntValue(schema?.raw['id']);
    final appId =
        item.appId ??
        _parseIntValue(schema?.raw['app_id'] ?? schema?.raw['appId']);

    final raw = Map<String, dynamic>.from(item.raw);
    if (schemaId != null) {
      raw['schema_id'] ??= schemaId;
      raw['id'] ??= schemaId;
    }
    if (appId != null) {
      raw['app_id'] ??= appId;
    }
    raw['market_name'] ??= item.marketName ?? schema?.marketName;
    raw['market_hash_name'] ??= item.marketHashName ?? schema?.marketHashName;
    raw['image_url'] ??= item.imageUrl ?? schema?.imageUrl;
    final displayPrice = _extractReference(item, schema);
    if (displayPrice > 0) {
      raw['market_price'] ??= displayPrice;
    }
    raw['buff_min_price'] ??= schema?.raw['buff_min_price'];
    raw['reference_price'] ??= schema?.raw['reference_price'];
    raw['tags'] ??= schema?.raw['tags'];

    return MarketItemEntity.fromJson(raw);
  }

  void _openMarketDetail(InventoryItem item) {
    final marketItem = _toMarketDetailItem(item);
    final schemaId = marketItem.schemaId ?? marketItem.id;
    if (schemaId == null) {
      return;
    }
    Get.toNamed(Routers.MARKET_DETAIL, arguments: marketItem);
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

  String? _extractWearText(InventoryItem item, Map<String, dynamic>? asset) {
    return _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(item.raw, ['paint_wear', 'paintWear']) ??
        item.paintWear?.toString();
  }

  double? _extractWearValue(InventoryItem item, Map<String, dynamic>? asset) {
    final text = _extractWearText(item, asset);
    if (text != null) {
      final parsed = double.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
    }
    return item.paintWear ?? _extractDouble(asset, ['paint_wear', 'paintWear']);
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

  String _itemMergeKey(InventoryItem item) {
    final schemaId = item.schemaId;
    if (schemaId != null) {
      return 'schema:$schemaId';
    }
    final marketHashName = item.marketHashName;
    if (marketHashName != null && marketHashName.isNotEmpty) {
      return 'hash:$marketHashName';
    }
    final id = item.id;
    if (id != null) {
      return 'id:$id';
    }
    return 'raw:${item.raw.hashCode}';
  }

  List<_InventoryMergeGroup> _buildMergedGroups() {
    final groups = <String, _InventoryMergeGroup>{};
    for (final item in _items) {
      final key = _itemMergeKey(item);
      final exists = groups[key];
      if (exists != null) {
        exists.items.add(item);
      } else {
        groups[key] = _InventoryMergeGroup(key, item);
      }
    }
    return groups.values.toList(growable: false);
  }

  List<_InventoryMergeGroup> _visibleGroups() {
    if (!_mergeSameItems) {
      return _items
          .map((item) => _InventoryMergeGroup('id:${item.id}', item))
          .toList(growable: false);
    }
    return _buildMergedGroups();
  }

  bool _isDetailExpanded(String key) {
    return _expandedDetailKeys.contains(key);
  }

  void _toggleDetailExpanded(String key) {
    setState(() {
      if (_expandedDetailKeys.contains(key)) {
        _expandedDetailKeys.remove(key);
      } else {
        _expandedDetailKeys.add(key);
      }
    });
  }

  List<int> _groupIds(_InventoryMergeGroup group) {
    return group.items
        .map((item) => item.id)
        .whereType<int>()
        .toList(growable: false);
  }

  int _groupTotalCount(_InventoryMergeGroup group) {
    var count = 0;
    for (final item in group.items) {
      count += _itemCount(item);
    }
    return count;
  }

  double _groupTotalPrice(_InventoryMergeGroup group) {
    var total = 0.0;
    for (final item in group.items) {
      total += _itemTotalPrice(item);
    }
    return total;
  }

  double _groupAppraise(_InventoryMergeGroup group) {
    var total = 0.0;
    for (final item in group.items) {
      total += _itemAppraise(item);
    }
    return total;
  }

  double _groupFee(_InventoryMergeGroup group) {
    if (_loadingParams) {
      return 0;
    }
    var total = 0.0;
    for (final item in group.items) {
      total += _itemFee(item);
    }
    return total;
  }

  double _groupIncome(_InventoryMergeGroup group) {
    if (_loadingParams) {
      return 0;
    }
    final total = _groupTotalPrice(group);
    if (total <= 0) {
      return 0;
    }
    return total - _groupFee(group);
  }

  int _groupRewardPoints(_InventoryMergeGroup group) {
    return _pointsFromAmount(_groupTotalPrice(group));
  }

  bool _groupHasWarning(_InventoryMergeGroup group) {
    for (final item in group.items) {
      final id = item.id;
      if (id == null) {
        continue;
      }
      final price = _prices[id] ?? 0;
      if (price > 0 && _isPriceWarning(item, price)) {
        return true;
      }
    }
    return false;
  }

  void _handlePriceChangedForIds(List<int> ids, String value, {int? sourceId}) {
    if (ids.isEmpty) {
      return;
    }
    if (value.isEmpty) {
      for (final id in ids) {
        _prices[id] = 0;
        if (sourceId == null || sourceId != id) {
          _controllers[id]?.text = '';
        }
      }
      setState(() {});
      return;
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      for (final id in ids) {
        _prices[id] = 0;
      }
      setState(() {});
      return;
    }

    final decimal = value.split('.');
    if (decimal.length == 2 && decimal[1].length > 2) {
      final normalized = _truncateTo2(parsed);
      final text = normalized.toStringAsFixed(2);
      for (final id in ids) {
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
      }
      setState(() {});
      return;
    }

    for (final id in ids) {
      if (sourceId == null || sourceId != id) {
        final controller = _controllers[id];
        if (controller != null && controller.text != value) {
          controller.text = value;
        }
      }
      _prices[id] = parsed;
    }
    setState(() {});
  }

  void _normalizeInputOnBlurForIds(List<int> ids, {int? sourceId}) {
    if (ids.isEmpty) {
      return;
    }
    final activeId = sourceId ?? ids.first;
    final controller = _controllers[activeId];
    if (controller == null) {
      return;
    }
    var text = controller.text;
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.fromPosition(
          TextPosition(offset: text.length),
        ),
      );
    }
    final parsed = double.tryParse(text) ?? 0;
    for (final id in ids) {
      _prices[id] = parsed;
      if (id == activeId) {
        continue;
      }
      final peer = _controllers[id];
      if (peer != null && peer.text != text) {
        peer.text = text;
      }
    }
    setState(() {});
  }

  void _syncMergedGroupPricesFromLead() {
    final groups = _buildMergedGroups();
    for (final group in groups) {
      final ids = _groupIds(group);
      if (ids.length <= 1) {
        continue;
      }

      var mergedPrice = 0.0;
      var mergedText = '';
      for (final id in ids) {
        final currentText = _controllers[id]?.text.trim() ?? '';
        final currentPrice = _prices[id] ?? double.tryParse(currentText) ?? 0;
        if (currentPrice > mergedPrice) {
          mergedPrice = currentPrice;
          mergedText = currentText;
        }
      }

      if (mergedPrice <= 0) {
        mergedPrice = 0;
        mergedText = '';
      } else if (mergedText.isEmpty) {
        mergedText = mergedPrice.toStringAsFixed(2);
      }

      for (final id in ids) {
        _prices[id] = mergedPrice;
        final controller = _controllers[id];
        if (controller != null && controller.text != mergedText) {
          controller.text = mergedText;
        }
      }
    }
  }

  void _setMergeSameItems(bool enable) {
    if (_mergeSameItems == enable) {
      return;
    }
    if (enable) {
      _syncMergedGroupPricesFromLead();
    }
    setState(() {
      _mergeSameItems = enable;
    });
  }

  double _extractReference(InventoryItem item, ShopSchemaInfo? schema) {
    // Keep up-shop appraisal pricing aligned with tronskins-app getReferencePrice:
    // 1) sell_min > 0: use min(buff_min_price, sell_min), and enforce >= 0.02
    // 2) no sell_min: use buff_min_price directly
    // 3) fallback to 0
    if (schema == null) {
      return 0;
    }
    final raw = schema.raw;
    final sellMinPrice = _parsePriceValue(raw['sell_min'] ?? raw['sellMin']);
    final buffMinPrice = _parsePriceValue(
      raw['buff_min_price'] ?? raw['buffMinPrice'],
    );
    if (sellMinPrice > 0) {
      if (buffMinPrice > 0) {
        final price = buffMinPrice < sellMinPrice ? buffMinPrice : sellMinPrice;
        return price > _minSellPrice ? price : _minSellPrice;
      }
      return sellMinPrice > _minSellPrice ? sellMinPrice : _minSellPrice;
    }
    if (buffMinPrice > 0) {
      return buffMinPrice;
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
      final reference = _extractReference(item, _lookupSchema(item));
      if (reference <= 0) {
        continue;
      }
      total += reference * (item.count ?? 1);
    }
    return total;
  }

  int _totalCount() {
    int count = 0;
    for (final item in _items) {
      count += item.count ?? 1;
    }
    return count;
  }

  int _itemCount(InventoryItem item) {
    return item.count ?? 1;
  }

  double _itemTotalPrice(InventoryItem item) {
    final id = item.id;
    if (id == null) {
      return 0;
    }
    final price = _prices[id] ?? 0;
    return price * _itemCount(item);
  }

  double _itemAppraise(InventoryItem item) {
    final reference = _extractReference(item, _lookupSchema(item));
    if (reference <= 0) {
      return 0;
    }
    return reference * _itemCount(item);
  }

  double _itemFee(InventoryItem item) {
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

  void _applyReferencePrice() {
    for (final item in _items) {
      final id = item.id!;
      final referencePrice = _extractReference(item, _lookupSchema(item));
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
        AppSnackbar.error('app.inventory.message.price_and_num_error'.tr);
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
        AppSnackbar.success('app.inventory.message.upshop_success'.tr);
        return;
      }

      AppSnackbar.error(submitText);
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

            if (constraints.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      label: 'app.inventory.upshop.nums'.tr,
                      value: Text('${_totalCount()}', style: amountStyle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStat(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      label: 'app.inventory.upshop.handling_charge'.tr,
                      value: _loadingParams
                          ? Text('--', style: amountStyle)
                          : Obx(
                              () => Text(
                                currency.format(_totalFee()),
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
                        value: Text('${_totalCount()}', style: amountStyle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryStat(
                        context: context,
                        icon: Icons.receipt_long_outlined,
                        label: 'app.inventory.upshop.handling_charge'.tr,
                        value: _loadingParams
                            ? Text('--', style: amountStyle)
                            : Obx(
                                () => Text(
                                  currency.format(_totalFee()),
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

  Widget _buildItemCard(
    BuildContext context,
    CurrencyController currency,
    _InventoryMergeGroup group,
  ) {
    final item = group.items.first;
    final ids = _groupIds(group);
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }
    final leadId = ids.first;
    final schema = _lookupSchema(item);
    final imageUrl = item.imageUrl ?? schema?.imageUrl ?? '';
    final title =
        item.marketName ?? schema?.marketName ?? item.marketHashName ?? '-';
    final controller = _controllers[leadId]!;
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
    final paintSeed =
        item.paintSeed ?? _extractText(asset, ['paint_seed', 'paintSeed']);
    final phase = item.phase ?? _extractText(asset, ['phase']);
    final percentage = _extractText(asset, ['percentage']);
    final itemCount = _groupTotalCount(group);
    final itemAppraise = _groupAppraise(group);
    final itemFee = _groupFee(group);
    final itemIncome = _groupIncome(group);
    final rewardPoints = _groupRewardPoints(group);
    final showWarning = _groupHasWarning(group);
    final detailsExpanded = _isDetailExpanded(group.key);
    final colorScheme = Theme.of(context).colorScheme;

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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_mergeSameItems)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'x$itemCount',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                      if (!_mergeSameItems) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _openMarketDetail(item),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              '${'app.market.view'.tr}>',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
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
              onChanged: (value) =>
                  _handlePriceChangedForIds(ids, value, sourceId: leadId),
              onEditingComplete: () =>
                  _normalizeInputOnBlurForIds(ids, sourceId: leadId),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _toggleDetailExpanded(group.key),
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          incomeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _setMergeSameItems(!_mergeSameItems),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _mergeSameItems
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 14,
                              color: _mergeSameItems
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'app.inventory.upshop.combining'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: _mergeSameItems
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
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
                        Text('app.inventory.upshop.text'.tr),
                      ],
                    )
                  : Text('app.inventory.upshop.text'.tr),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final visibleGroups = _visibleGroups();
    return Scaffold(
      appBar: AppBar(
        title: Text('app.inventory.upshop.text'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                setState(() => _showOverview = !_showOverview);
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('app.inventory.view_overview'.tr),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _applyReferencePrice,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('app.inventory.pricing'.tr),
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
              itemCount: visibleGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = visibleGroups[index];
                return KeyedSubtree(
                  key: ValueKey(group.key),
                  child: _buildItemCard(context, currency, group),
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
