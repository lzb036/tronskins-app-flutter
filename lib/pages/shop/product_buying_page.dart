import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/string_utils.dart';
import 'package:tronskins_app/controllers/shop/buy_request_controller.dart';

class ProductBuyingPage extends StatefulWidget {
  const ProductBuyingPage({super.key});

  @override
  State<ProductBuyingPage> createState() => _ProductBuyingPageState();
}

class _ProductBuyingPageState extends State<ProductBuyingPage> {
  final ApiMarketServer _marketApi = ApiMarketServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final ApiShopServer _shopServer = ApiShopServer();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _numController = TextEditingController();

  late final int _appId;
  late final int _schemaId;

  MarketTemplateSchema? _schema;
  List<dynamic>? _paintKits;
  double _purMinPrice = 0;
  double _minPrice = 0;
  int _purchaseNum = 0;
  int _remainNum = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  double? _wearMin;
  double? _wearMax;
  int? _paintIndex;
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final useAuth = UserStorage.getUserInfo() != null;
      final res = await _marketApi.marketTemplateDetail(
        appId: _appId,
        schemaId: _schemaId,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
      );
      _schema = res.datas?.schema;
      _paintKits = res.datas?.paintKits;

      final minRes = await _shopApi.getOrderBuyingMinPrice(
        appId: _appId,
        schemaId: _schemaId,
      );
      _purMinPrice = minRes.datas ?? 0;

      final remainRes = await _marketApi.buyRemainNum(schemaId: _schemaId);
      _purchaseNum = remainRes.datas?.purchaseNum ?? 0;
      _remainNum = remainRes.datas?.remainNum ?? 0;

      final paramsRes = await _shopApi.getSysParams();
      if (paramsRes.datas is Map<String, dynamic>) {
        final rawMin = paramsRes.datas?['minPrice'];
        if (rawMin is num) {
          _minPrice = rawMin.toDouble();
        } else {
          _minPrice = double.tryParse(rawMin?.toString() ?? '') ?? 0;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _showFilter => _appId == 730;

  double _totalAmount() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final nums = int.tryParse(_numController.text) ?? 0;
    return price * nums;
  }

  Future<bool> _checkPurchaseOnline() async {
    final user = UserStorage.getUserInfo();
    final uuid = user?.uuid ?? user?.shop?.uuid;
    if (uuid == null || uuid.isEmpty) {
      return true;
    }
    try {
      final res = await _shopServer.getUserShopInfo(params: {'uuid': uuid});
      if (res.success && res.datas != null) {
        return res.datas?['signWanted'] == true;
      }
    } catch (_) {}
    return true;
  }

  void _sanitizePrice(String value) {
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
    if (numValue > 1000) {
      _numController.text = '1000';
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
    }
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
    if (!await _checkPurchaseOnline()) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.offline_tips'.tr,
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    final nums = int.tryParse(_numController.text) ?? 0;
    if (_remainNum == 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.message.num_error'.tr,
      );
      return;
    }
    if (price <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.filter.message.price_error'.tr,
      );
      return;
    }
    if (nums <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.message.num_error'.tr,
      );
      return;
    }
    if (price < _purMinPrice) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.message.balance_insufficient'.tr,
      );
      return;
    }
    final sellMin = _schema?.sellMin ?? _minPrice;
    if (price >= 10 && sellMin > 0 && price > sellMin) {
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

    final total = price * nums;
    final available = (user.fund?.available ?? 0) + (user.fund?.gift ?? 0);
    if (available < total) {
      Get.dialog(
        AlertDialog(
          title: Text('app.system.tips.title'.tr),
          content: Text('app.trade.purchase.message.supply_price_error'.tr),
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

    setState(() => _isSubmitting = true);
    try {
      final res = await _shopApi.orderItemBuying(
        params: {
          'nums': nums,
          'price': price,
          'appId': _appId,
          'schemaId': _schemaId,
          'paintIndex': _paintIndex,
          'paintWearMax': _wearMax,
          'paintWearMin': _wearMin,
        }..removeWhere((key, value) => value == null),
      );

      final datas = res.datas;
      if (datas is String) {
        if (datas.contains('lower than')) {
          Get.dialog(
            AlertDialog(
              title: Text('app.system.tips.title'.tr),
              content: Text(datas),
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
      }

      if (res.success) {
        Get.back(result: true);
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.system.message.success'.tr,
        );
        final controller = Get.isRegistered<BuyRequestController>()
            ? Get.find<BuyRequestController>()
            : null;
        controller?.refreshMyBuying();
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
    final reference = schema?.referencePrice ?? 0;
    final sellMin = schema?.sellMin ?? 0;
    final buyMax = schema?.buyMax ?? 0;
    final purchaseTips = formatWithParams(
      'app.trade.purchase.message.remaining_tips'.tr,
      [_purchaseNum, _remainNum],
    );
    return Scaffold(
      appBar: AppBar(title: Text('app.trade.purchase.text'.tr)),
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
                        if (reference > 0)
                          Obx(
                            () => Text(
                              '${'app.market.detail.steam_price'.tr}: '
                              '${currency.format(reference)}',
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
          const SizedBox(height: 12),
          Obx(
            () => TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'app.trade.purchase.price'.tr,
                hintText:
                    '${'app.market.filter.price_lowest'.tr}${currency.format(_purMinPrice)}',
              ),
              onChanged: _sanitizePrice,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'app.trade.purchase.num'.tr,
              hintText: 'app.trade.purchase.num_placeholder'.tr,
            ),
            onChanged: _sanitizeNum,
          ),
          if (_purchaseNum > 0 || _remainNum > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                purchaseTips,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
                  : Text('app.market.detail.release_purchase'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
