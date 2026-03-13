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
      _filterLabel = _buildFilterLabel();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _showFilter {
    if (_appId != 730) {
      return false;
    }
    final typeKey = _schema?.tags?.type?.key ?? _schema?.tags?.type?.name;
    const excludedTypes = <String>{
      'CSGO_Type_WeaponCase',
      'Type_CustomPlayer',
      'CSGO_Tool_Sticker',
    };
    return !excludedTypes.contains(typeKey);
  }

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
      _numController.text = value.split('.').first;
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.message.num_error'.tr,

        titleText: const SizedBox.shrink(),
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

  void _calibratePrice() {
    final value = _priceController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return;
    }
    var next = parsed;
    if (next < _minPrice) {
      next = _minPrice;
    }
    final text = next.toStringAsFixed(2);
    _priceController.text = text;
    _priceController.selection = TextSelection.fromPosition(
      TextPosition(offset: _priceController.text.length),
    );
  }

  Future<void> _openFilterSheet() async {
    final exteriorKey = _schema?.tags?.exterior?.key;
    final wearQuickOptions = _buildWearQuickOptions(exteriorKey);
    final minWearHint = wearQuickOptions.first.minText;
    final maxWearHint = wearQuickOptions.last.maxText;

    final wearMinController = TextEditingController(
      text: _wearMin != null ? _formatWearValue(_wearMin!) : '',
    );
    final wearMaxController = TextEditingController(
      text: _wearMax != null ? _formatWearValue(_wearMax!) : '',
    );

    final result = await showModalBottomSheet<_ProductFilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isQuickSelected(_ProductWearQuickOption option) {
              final min = double.tryParse(wearMinController.text.trim());
              final max = double.tryParse(wearMaxController.text.trim());
              if (min == null || max == null) {
                return false;
              }
              return (min - option.min).abs() < 0.000001 &&
                  (max - option.max).abs() < 0.000001;
            }

            Future<void> closeSheet(_ProductFilterResult result) async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 10));
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop(result);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app.market.filter.csgo.wear_interval'.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: wearMinController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(hintText: minWearHint),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('~'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: wearMaxController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(hintText: maxWearHint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'app.market.filter.selection_quick'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wearQuickOptions
                        .map(
                          (option) => _buildFilterChip(
                            context,
                            label: option.label,
                            selected: isQuickSelected(option),
                            onSelected: () {
                              setModalState(() {
                                wearMinController.text = option.minText;
                                wearMaxController.text = option.maxText;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              closeSheet(const _ProductFilterResult()),
                          child: Text('app.market.filter.reset'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final normalized = _normalizeWearRange(
                              minInput: wearMinController.text,
                              maxInput: wearMaxController.text,
                              exteriorKey: exteriorKey,
                            );
                            closeSheet(
                              _ProductFilterResult(
                                wearMin: normalized.min,
                                wearMax: normalized.max,
                              ),
                            );
                          },
                          child: Text('app.market.filter.finish'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _wearMin = result.wearMin;
      _wearMax = result.wearMax;
      _filterLabel = _buildFilterLabel();
    });
  }

  String _buildFilterLabel() {
    final parts = <String>[];
    if (_wearMin != null || _wearMax != null) {
      parts.add(
        '${'app.market.filter.csgo.wear_interval'.tr}: '
        '${_wearMin != null ? _formatWearValue(_wearMin!) : '-'} - '
        '${_wearMax != null ? _formatWearValue(_wearMax!) : '-'}',
      );
    }
    if (parts.isEmpty) {
      return 'app.common.unlimited'.tr;
    }
    return parts.join(' / ');
  }

  List<_ProductWearQuickOption> _buildWearQuickOptions(String? exteriorKey) {
    switch (exteriorKey) {
      case 'WearCategory0':
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.00, 0.01),
          _ProductWearQuickOption(0.01, 0.02),
          _ProductWearQuickOption(0.02, 0.03),
          _ProductWearQuickOption(0.03, 0.04),
          _ProductWearQuickOption(0.04, 0.07),
        ];
      case 'WearCategory1':
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.07, 0.08),
          _ProductWearQuickOption(0.08, 0.09),
          _ProductWearQuickOption(0.09, 0.10),
          _ProductWearQuickOption(0.10, 0.11),
          _ProductWearQuickOption(0.11, 0.15),
        ];
      case 'WearCategory2':
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.15, 0.18),
          _ProductWearQuickOption(0.18, 0.21),
          _ProductWearQuickOption(0.21, 0.24),
          _ProductWearQuickOption(0.24, 0.27),
          _ProductWearQuickOption(0.27, 0.38),
        ];
      case 'WearCategory3':
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.38, 0.39),
          _ProductWearQuickOption(0.39, 0.40),
          _ProductWearQuickOption(0.40, 0.41),
          _ProductWearQuickOption(0.41, 0.42),
          _ProductWearQuickOption(0.42, 0.45),
        ];
      case 'WearCategory4':
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.45, 0.50),
          _ProductWearQuickOption(0.50, 0.63),
          _ProductWearQuickOption(0.63, 0.76),
          _ProductWearQuickOption(0.76, 0.90),
          _ProductWearQuickOption(0.90, 1.00),
        ];
      default:
        return const <_ProductWearQuickOption>[
          _ProductWearQuickOption(0.00, 0.01),
          _ProductWearQuickOption(0.01, 0.02),
          _ProductWearQuickOption(0.02, 0.03),
          _ProductWearQuickOption(0.03, 0.04),
          _ProductWearQuickOption(0.04, 0.07),
        ];
    }
  }

  _ProductWearRange _normalizeWearRange({
    required String minInput,
    required String maxInput,
    required String? exteriorKey,
  }) {
    final quickOptions = _buildWearQuickOptions(exteriorKey);
    final minAllowed = quickOptions.first.min;
    final maxAllowed = quickOptions.last.max;

    var min = _toDouble(minInput.trim());
    var max = _toDouble(maxInput.trim());

    if (min != null) {
      if (min < minAllowed) {
        min = minAllowed;
      } else if (min > maxAllowed) {
        min = maxAllowed;
      }
    }

    if (max != null) {
      if (max < minAllowed) {
        max = minAllowed;
      } else if (max > maxAllowed) {
        max = maxAllowed;
      }
    }

    if (min != null && max != null && min > max) {
      max = min;
    }

    return _ProductWearRange(
      min: min != null ? double.parse(min.toStringAsFixed(2)) : null,
      max: max != null ? double.parse(max.toStringAsFixed(2)) : null,
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: colors.primary.withValues(alpha: 0.16),
      side: BorderSide(
        color: selected
            ? colors.primary.withValues(alpha: 0.85)
            : colors.outline.withValues(alpha: 0.45),
      ),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: selected ? colors.primary : colors.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatWearValue(double value) => value.toStringAsFixed(2);

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    var shouldClosePage = false;
    final user = UserStorage.getUserInfo();
    if (user == null) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.system.message.nologin'.tr,
        titleText: const SizedBox.shrink(),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await _checkPurchaseOnline()) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.offline_tips'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    final nums = int.tryParse(_numController.text) ?? 0;
    if (_remainNum == 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.message.num_error'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (price <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.filter.message.price_error'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (nums <= 0) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.market.detail.message.num_error'.tr,

        titleText: const SizedBox.shrink(),
      );
      return;
    }
    if (price < _purMinPrice) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.trade.purchase.message.balance_insufficient'.tr,

        titleText: const SizedBox.shrink(),
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
        shouldClosePage = true;
        final buyRequestController = Get.isRegistered<BuyRequestController>()
            ? Get.find<BuyRequestController>()
            : null;
        FocusManager.instance.primaryFocus?.unfocus();
        Get.back(result: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success('app.trade.purchase.message.success'.tr);
          buyRequestController?.refreshMyBuying();
        });
        return;
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,

          titleText: const SizedBox.shrink(),
        );
      }
    } finally {
      if (mounted && !shouldClosePage) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildRowContainer(
    BuildContext context, {
    required Widget child,
    bool withTopGap = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(14, withTopGap ? 12 : 0, 14, 0),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderPill(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInputShell(BuildContext context, {required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildNoticeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                children: [
                  TextSpan(text: '1.${'app.trade.purchase.buyer_notice_1'.tr}'),
                  TextSpan(
                    text: ' ${'app.trade.purchase.buyer_notice_2'.tr} ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' ${'app.trade.purchase.buyer_notice_3'.tr}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
    final sellMin = schema?.sellMin ?? 0;
    final buyMax = schema?.buyMax ?? 0;
    final purchaseTips = formatWithParams(
      'app.trade.purchase.message.remaining_tips'.tr,
      [_purchaseNum, _remainNum],
    );
    return Scaffold(
      appBar: AppBar(title: Text('app.trade.purchase.text'.tr)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.05),
              colors.surface,
              colors.surface,
            ],
            stops: const [0.0, 0.24, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 108),
          children: [
            _buildRowContainer(
              context,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.38,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, _) => const SizedBox(
                            width: 82,
                            height: 82,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, _, __) =>
                              const Icon(Icons.image_not_supported_outlined),
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
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildHeaderPill(
                                  context,
                                  label:
                                      '${'app.market.detail.sale_lowest'.tr}:',
                                  value: currency.format(sellMin),
                                  color: colors.primary,
                                ),
                                _buildHeaderPill(
                                  context,
                                  label:
                                      '${'app.market.detail.purchase_highest'.tr}:',
                                  value: currency.format(buyMax),
                                  color: colors.tertiary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showFilter)
              _buildRowContainer(
                context,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openFilterSheet,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 96,
                          child: Text(
                            'app.market.filter.text'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _filterLabel ?? 'app.common.unlimited'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
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
            _buildRowContainer(
              context,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        'app.trade.purchase.price'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: _buildInputShell(
                        context,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText:
                                '${'app.market.filter.price_lowest'.tr}${currency.format(_purMinPrice)}',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _sanitizePrice,
                          onEditingComplete: _calibratePrice,
                          onSubmitted: (_) => _calibratePrice(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildRowContainer(
              context,
              withTopGap: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        'app.trade.purchase.num'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: _buildInputShell(
                        context,
                        child: TextField(
                          controller: _numController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'app.trade.purchase.num_placeholder'.tr,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _sanitizeNum,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_purchaseNum >= 0 && _remainNum >= 0)
              _buildRowContainer(
                context,
                withTopGap: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Text(
                    purchaseTips,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            _buildNoticeSection(context),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(color: colors.outline.withValues(alpha: 0.16)),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Row(
                    children: [
                      Text(
                        '${'app.market.price_total'.tr}: ',
                        style: theme.textTheme.titleSmall,
                      ),
                      Flexible(
                        child: Text(
                          currency.format(_totalAmount()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('app.market.detail.release_purchase'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductWearQuickOption {
  final double min;
  final double max;

  const _ProductWearQuickOption(this.min, this.max);

  String get minText => min.toStringAsFixed(2);

  String get maxText => max.toStringAsFixed(2);

  String get label => '${min.toStringAsFixed(2)}-${max.toStringAsFixed(2)}';
}

class _ProductWearRange {
  final double? min;
  final double? max;

  const _ProductWearRange({this.min, this.max});
}

class _ProductFilterResult {
  final double? wearMin;
  final double? wearMax;

  const _ProductFilterResult({this.wearMin, this.wearMax});
}
