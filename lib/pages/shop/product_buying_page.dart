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
    _priceController.addListener(_onInputChanged);
    _numController.addListener(_onInputChanged);
    _loadData();
  }

  @override
  void dispose() {
    _priceController.removeListener(_onInputChanged);
    _numController.removeListener(_onInputChanged);
    _priceController.dispose();
    _numController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
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

  double _enteredPrice() {
    return double.tryParse(_priceController.text) ?? 0;
  }

  int _enteredQuantity() {
    return int.tryParse(_numController.text) ?? 0;
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

  Widget _buildHeaderCard({
    required BuildContext context,
    required CurrencyController currency,
    required String imageUrl,
    required String title,
    required double sellMin,
    required double buyMax,
    required double reference,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: isDark ? 0.24 : 0.14),
            colors.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: isDark ? 0.42 : 0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, _, __) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatPill(
                        context: context,
                        icon: Icons.south_west_rounded,
                        label: 'app.market.detail.sale_lowest'.tr,
                        value: currency.format(sellMin),
                        accent: colors.primary,
                      ),
                      _buildStatPill(
                        context: context,
                        icon: Icons.north_east_rounded,
                        label: 'app.market.detail.purchase_highest'.tr,
                        value: currency.format(buyMax),
                        accent: colors.tertiary,
                      ),
                      if (reference > 0)
                        _buildStatPill(
                          context: context,
                          icon: Icons.public_rounded,
                          label: 'app.market.detail.steam_price'.tr,
                          value: currency.format(reference),
                          accent: colors.secondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeConfigCard({
    required BuildContext context,
    required CurrencyController currency,
    required String purchaseTips,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'app.trade.purchase.text'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_showFilter)
              Material(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openFilterSheet,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filterLabel ?? 'app.common.unlimited'.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showFilter) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'app.trade.purchase.price'.tr,
                      hintText:
                          '${'app.market.filter.price_lowest'.tr}${currency.format(_purMinPrice)}',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(
                        alpha: 0.28,
                      ),
                    ),
                    onChanged: _sanitizePrice,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _numController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'app.trade.purchase.num'.tr,
                      hintText: 'app.trade.purchase.num_placeholder'.tr,
                      prefixIcon: const Icon(
                        Icons.format_list_numbered_rounded,
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(
                        alpha: 0.28,
                      ),
                    ),
                    onChanged: _sanitizeNum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    purchaseTips,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${'app.market.filter.price_lowest'.tr}: ${currency.format(_purMinPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'app.system.tips.title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1.${'app.trade.purchase.buyer_notice_1'.tr}'
              '${'app.trade.purchase.buyer_notice_2'.tr}'
              '${'app.trade.purchase.buyer_notice_3'.tr}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '2.${'app.trade.purchase.buyer_notice_4'.tr}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
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
    final colors = theme.colorScheme;
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          Obx(
            () => _buildHeaderCard(
              context: context,
              currency: currency,
              imageUrl: imageUrl,
              title: title,
              sellMin: sellMin,
              buyMax: buyMax,
              reference: reference,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => _buildTradeConfigCard(
              context: context,
              currency: currency,
              purchaseTips: purchaseTips,
            ),
          ),
          const SizedBox(height: 12),
          _buildNoticeCard(context),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${'app.market.price_total'.tr}: ${currency.format(_totalAmount())}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'app.trade.purchase.price'.tr}: '
                        '${currency.format(_enteredPrice())}  ·  '
                        '${'app.trade.purchase.num'.tr}: ${_enteredQuantity()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        size: 18,
                      ),
                label: Text('app.market.detail.release_purchase'.tr),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
