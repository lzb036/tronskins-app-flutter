import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';

class BulkBuyingPage extends StatefulWidget {
  const BulkBuyingPage({super.key});

  @override
  State<BulkBuyingPage> createState() => _BulkBuyingPageState();
}

class _BulkBuyingPageState extends State<BulkBuyingPage> {
  final ApiMarketServer _marketApi = ApiMarketServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _numController = TextEditingController();

  late final int _appId;
  late final int _schemaId;

  MarketTemplateSchema? _schema;
  List<dynamic>? _paintKits;
  bool _showPaintKits = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingMatches = false;

  final List<MarketListItem> _matchedItems = <MarketListItem>[];
  int? _paintIndex;
  double? _wearMin;
  double? _wearMax;
  String? _filterLabel;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _appId = args['appId'] as int? ?? 730;
    _schemaId = args['schemaId'] as int? ?? 0;
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _numController.dispose();
    super.dispose();
  }

  bool get _showFilter {
    if (_appId == 440) {
      return false;
    }
    if (_showPaintKits) {
      return true;
    }
    final typeKey = _schema?.tags?.type?.key ?? _schema?.tags?.type?.name;
    const excludedTypes = <String>{
      'CSGO_Type_WeaponCase',
      'Type_CustomPlayer',
      'CSGO_Tool_Sticker',
    };
    return !excludedTypes.contains(typeKey);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final useAuth = UserStorage.getUserInfo() != null;
      var res = await _marketApi.marketTemplateDetail(
        appId: _appId,
        schemaId: _schemaId,
        useAuth: useAuth,
      );
      if (!res.success && useAuth) {
        res = await _marketApi.marketTemplateDetail(
          appId: _appId,
          schemaId: _schemaId,
          useAuth: false,
        );
      }
      _schema = res.datas?.schema;
      _paintKits = res.datas?.paintKits;
      _showPaintKits = _isShowPaintKits(_schema, _paintKits);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isShowPaintKits(MarketTemplateSchema? schema, List<dynamic>? kits) {
    if (schema == null) {
      return false;
    }
    final hash = schema.marketHashName?.toLowerCase() ?? '';
    return hash.contains('doppler') || (kits != null && kits.isNotEmpty);
  }

  void _sanitizePrice(String value) {
    if (value.isEmpty) {
      return;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return;
    }
    final parts = value.split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      _priceController.text = parsed.toStringAsFixed(2);
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.bulk_buying.price_decimal_error'.tr,
      );
    }
  }

  void _sanitizeNum(String value) {
    if (value.contains('.')) {
      _numController.text = value.split('.').first;
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.message.num_error'.tr,
      );
    }
    var numValue = int.tryParse(_numController.text) ?? 0;
    if (numValue > 200) {
      numValue = 200;
      _numController.text = '200';
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
    }
    if (_matchedItems.isNotEmpty && numValue > _matchedItems.length) {
      _numController.text = _matchedItems.length.toString();
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
    }
  }

  Future<void> _queryMatchedOnSale() async {
    final maxPrice = double.tryParse(_priceController.text);
    if (maxPrice == null || maxPrice <= 0) {
      if (_matchedItems.isNotEmpty || _isLoadingMatches) {
        setState(() {
          _matchedItems.clear();
          _isLoadingMatches = false;
        });
      }
      return;
    }
    final userId = int.tryParse(UserStorage.getUserInfo()?.id ?? '');
    setState(() => _isLoadingMatches = true);
    try {
      final res = await _marketApi.onSaleList(
        appId: _appId,
        schemaId: _schemaId,
        page: 1,
        pageSize: 100,
        maxPrice: maxPrice,
        userId: userId,
        paintIndex: _paintIndex,
        paintWearMin: _wearMin,
        paintWearMax: _wearMax,
      );
      final items = res.datas?.items ?? <MarketListItem>[];
      items.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      _matchedItems
        ..clear()
        ..addAll(items);
      final currentNum = int.tryParse(_numController.text) ?? 0;
      if (currentNum > _matchedItems.length) {
        _numController.text = _matchedItems.length.toString();
        _numController.selection = TextSelection.fromPosition(
          TextPosition(offset: _numController.text.length),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMatches = false);
      }
    }
  }

  double _totalAmount() {
    final quantity = int.tryParse(_numController.text) ?? 0;
    if (quantity <= 0 || _matchedItems.isEmpty) {
      return 0;
    }
    final selected = _matchedItems.take(quantity);
    var total = 0.0;
    for (final item in selected) {
      total += item.price ?? 0;
    }
    return total;
  }

  Future<void> _openFilterSheet() async {
    final paintController = TextEditingController(
      text: _paintIndex?.toString() ?? '',
    );
    final wearMinController = TextEditingController(
      text: _wearMin?.toString() ?? '',
    );
    final wearMaxController = TextEditingController(
      text: _wearMax?.toString() ?? '',
    );
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'app.market.filter.text'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paintController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'app.market.csgo.paint_index'.tr,
                  hintText: 'app.market.csgo.paint_index_placeholder'.tr,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: wearMinController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'app.market.filter.price_lowest'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: wearMaxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'app.market.filter.price_highest'.tr,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('app.common.cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('app.common.confirm'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == true) {
      setState(() {
        _paintIndex = int.tryParse(paintController.text);
        _wearMin = double.tryParse(wearMinController.text);
        _wearMax = double.tryParse(wearMaxController.text);
        _filterLabel = _buildFilterLabel();
      });
      await _queryMatchedOnSale();
    }
  }

  String _buildFilterLabel() {
    final parts = <String>[];
    if (_paintIndex != null) {
      parts.add('${'app.market.csgo.paint_index'.tr}: $_paintIndex');
    }
    if (_wearMin != null || _wearMax != null) {
      parts.add(
        '${'app.market.filter.csgo.wear_interval'.tr}: '
        '${_wearMin ?? '-'} - ${_wearMax ?? '-'}',
      );
    }
    if (parts.isEmpty) {
      return 'app.common.unlimited'.tr;
    }
    return parts.join(' / ');
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final user = UserStorage.getUserInfo();
    if (user == null) {
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.nologin'.tr);
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    final num = int.tryParse(_numController.text) ?? 0;
    final sellMin = _schema?.sellMin ?? 0;

    if (price <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.filter.message.price_error'.tr,
      );
      return;
    }
    if (num <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.message.num_error'.tr,
      );
      return;
    }
    if (num > 200) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.bulk_buying.num_error'.tr,
      );
      return;
    }
    if (sellMin > 0 && price < sellMin) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.bulk_buying.price_error'.tr,
      );
      return;
    }

    await _queryMatchedOnSale();
    if (num > _matchedItems.length) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.bulk_buying.num_over'.tr,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _shopApi.orderItemBatchBuy(
        params: {
          'num': num,
          'price': price,
          'appId': _appId,
          'id': _schemaId,
          'paintIndex': _paintIndex,
          'paintWearMax': _wearMax,
          'paintWearMin': _wearMin,
        }..removeWhere((key, value) => value == null),
      );

      final datas = res.datas;
      if (datas is String) {
        if (datas.contains('Steam issue')) {
          Get.dialog(
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
          Get.dialog(
            AlertDialog(
              title: Text('app.system.tips.title'.tr),
              content: Text('app.inventory.message.privacy'.tr),
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
        Get.back(result: true);
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final schema = _schema;
    final imageUrl = schema?.imageUrl ?? '';
    final title = schema?.marketName ?? schema?.marketHashName ?? '-';
    final sellMin = schema?.sellMin ?? 0;
    final buyMax = schema?.buyMax ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('app.market.detail.bulk_buying.title'.tr)),
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
                        const SizedBox(height: 8),
                        Obx(
                          () => Text(
                            '${'app.market.detail.sale_lowest'.tr}: '
                            '${currency.format(sellMin)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${'app.market.detail.purchase_highest'.tr}: '
                            '${currency.format(buyMax)}',
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
          if (_showFilter)
            Card(
              child: ListTile(
                title: Text('app.market.filter.text'.tr),
                subtitle: Text(_filterLabel ?? 'app.common.unlimited'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openFilterSheet,
              ),
            ),
          if (_showFilter) const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'app.market.detail.bulk_buying.price_highest'.tr,
                hintText:
                    '${'app.market.filter.price_lowest'.tr}${currency.format(sellMin)}',
              ),
              onChanged: _sanitizePrice,
              onEditingComplete: _queryMatchedOnSale,
              onSubmitted: (_) => _queryMatchedOnSale(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'app.trade.buy.quantity'.tr,
                    hintText: 'app.trade.buy.quantity'.tr,
                  ),
                  onChanged: _sanitizeNum,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 80),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isLoadingMatches
                      ? '...'
                      : '${_matchedItems.length}${'app.market.detail.bulk_buying.match'.tr}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
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
              color: Colors.black.withOpacity(0.05),
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
                  '${'app.market.price_total'.tr}: '
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
                  : Text('app.trade.buy.text'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
