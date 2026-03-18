import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';

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
  final FocusNode _priceFocusNode = FocusNode();

  late final int _appId;
  late final int _schemaId;

  MarketTemplateSchema? _schema;
  List<dynamic>? _paintKits;
  bool _showPaintKits = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingMatches = false;
  Timer? _priceQueryDebounce;
  int _matchQueryVersion = 0;

  final List<MarketListItem> _matchedItems = <MarketListItem>[];
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
    _priceFocusNode.addListener(_handlePriceFocusChange);
    _loadData();
  }

  @override
  void dispose() {
    _priceQueryDebounce?.cancel();
    _priceController.removeListener(_onInputChanged);
    _numController.removeListener(_onInputChanged);
    _priceFocusNode.removeListener(_handlePriceFocusChange);
    _priceController.dispose();
    _numController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handlePriceFocusChange() {
    if (_priceFocusNode.hasFocus) {
      return;
    }
    _priceQueryDebounce?.cancel();
    unawaited(_queryMatchedOnSale());
  }

  void _onPriceInputChanged(String value) {
    _sanitizePrice(value);
    _scheduleMatchedQuery();
  }

  void _scheduleMatchedQuery({
    Duration delay = const Duration(milliseconds: 360),
  }) {
    _priceQueryDebounce?.cancel();
    _priceQueryDebounce = Timer(delay, () {
      if (!mounted) {
        return;
      }
      unawaited(_queryMatchedOnSale());
    });
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
      final res = await _marketApi.marketTemplateDetail(
        appId: _appId,
        schemaId: _schemaId,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
      );
      _schema = res.datas?.schema;
      _paintKits = res.datas?.paintKits;
      _showPaintKits = _isShowPaintKits(_schema, _paintKits);
      _filterLabel = _buildFilterLabel();
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
      AppSnackbar.error('app.market.detail.bulk_buying.price_decimal_error'.tr);
    }
  }

  void _sanitizeNum(String value) {
    if (value.contains('.')) {
      _numController.text = value.split('.').first;
      _numController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numController.text.length),
      );
      AppSnackbar.error('app.market.detail.message.num_error'.tr);
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
      _matchQueryVersion++;
      if (_matchedItems.isNotEmpty || _isLoadingMatches) {
        setState(() {
          _matchedItems.clear();
          _isLoadingMatches = false;
        });
      }
      return;
    }

    final user = UserStorage.getUserInfo();
    final useAuth = user != null;
    final userId = int.tryParse(user?.id ?? '');
    final queryVersion = ++_matchQueryVersion;

    setState(() => _isLoadingMatches = true);
    try {
      final res = await _marketApi.onSaleList(
        appId: _appId,
        schemaId: _schemaId,
        page: 1,
        pageSize: 100,
        maxPrice: maxPrice,
        userId: userId,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
      );
      if (!mounted || queryVersion != _matchQueryVersion) {
        return;
      }
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
      if (mounted && queryVersion == _matchQueryVersion) {
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

    final result = await showModalBottomSheet<_BulkWearRange>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isQuickSelected(_BulkWearQuickOption option) {
              final min = double.tryParse(wearMinController.text.trim());
              final max = double.tryParse(wearMaxController.text.trim());
              if (min == null || max == null) {
                return false;
              }
              return (min - option.min).abs() < 0.000001 &&
                  (max - option.max).abs() < 0.000001;
            }

            Future<void> closeSheet(_BulkWearRange result) async {
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
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                          (option) => _buildWearChip(
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
                          onPressed: () => closeSheet(const _BulkWearRange()),
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
                            closeSheet(normalized);
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
      _wearMin = result.min;
      _wearMax = result.max;
      _filterLabel = _buildFilterLabel();
    });
  }

  String _buildFilterLabel() {
    if (_wearMin == null && _wearMax == null) {
      return 'app.common.unlimited'.tr;
    }
    return '${'app.market.filter.csgo.wear_interval'.tr}: '
        '${_wearMin != null ? _formatWearValue(_wearMin!) : '-'} - '
        '${_wearMax != null ? _formatWearValue(_wearMax!) : '-'}';
  }

  List<_BulkWearQuickOption> _buildWearQuickOptions(String? exteriorKey) {
    switch (exteriorKey) {
      case 'WearCategory0':
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.00, 0.01),
          _BulkWearQuickOption(0.01, 0.02),
          _BulkWearQuickOption(0.02, 0.03),
          _BulkWearQuickOption(0.03, 0.04),
          _BulkWearQuickOption(0.04, 0.07),
        ];
      case 'WearCategory1':
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.07, 0.08),
          _BulkWearQuickOption(0.08, 0.09),
          _BulkWearQuickOption(0.09, 0.10),
          _BulkWearQuickOption(0.10, 0.11),
          _BulkWearQuickOption(0.11, 0.15),
        ];
      case 'WearCategory2':
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.15, 0.18),
          _BulkWearQuickOption(0.18, 0.21),
          _BulkWearQuickOption(0.21, 0.24),
          _BulkWearQuickOption(0.24, 0.27),
          _BulkWearQuickOption(0.27, 0.38),
        ];
      case 'WearCategory3':
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.38, 0.39),
          _BulkWearQuickOption(0.39, 0.40),
          _BulkWearQuickOption(0.40, 0.41),
          _BulkWearQuickOption(0.41, 0.42),
          _BulkWearQuickOption(0.42, 0.45),
        ];
      case 'WearCategory4':
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.45, 0.50),
          _BulkWearQuickOption(0.50, 0.63),
          _BulkWearQuickOption(0.63, 0.76),
          _BulkWearQuickOption(0.76, 0.90),
          _BulkWearQuickOption(0.90, 1.00),
        ];
      default:
        return const <_BulkWearQuickOption>[
          _BulkWearQuickOption(0.00, 0.01),
          _BulkWearQuickOption(0.01, 0.02),
          _BulkWearQuickOption(0.02, 0.03),
          _BulkWearQuickOption(0.03, 0.04),
          _BulkWearQuickOption(0.04, 0.07),
        ];
    }
  }

  _BulkWearRange _normalizeWearRange({
    required String minInput,
    required String maxInput,
    required String? exteriorKey,
  }) {
    final options = _buildWearQuickOptions(exteriorKey);
    final minAllowed = options.first.min;
    final maxAllowed = options.last.max;

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

    return _BulkWearRange(
      min: min != null ? double.parse(min.toStringAsFixed(2)) : null,
      max: max != null ? double.parse(max.toStringAsFixed(2)) : null,
    );
  }

  Widget _buildWearChip(
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
      AppSnackbar.error('app.system.message.nologin'.tr);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final price = double.tryParse(_priceController.text) ?? 0;
    final num = int.tryParse(_numController.text) ?? 0;
    final sellMin = _schema?.sellMin ?? 0;

    if (price <= 0) {
      AppSnackbar.error('app.market.filter.message.price_error'.tr);
      return;
    }

    if (num <= 0) {
      AppSnackbar.error('app.market.detail.message.num_error'.tr);
      return;
    }

    if (num > 200) {
      AppSnackbar.error('app.market.detail.bulk_buying.num_error'.tr);
      return;
    }

    if (sellMin > 0 && price < sellMin) {
      AppSnackbar.error('app.market.detail.bulk_buying.price_error'.tr);
      return;
    }

    await _queryMatchedOnSale();
    if (num > _matchedItems.length) {
      AppSnackbar.error('app.market.detail.bulk_buying.num_over'.tr);
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
        shouldClosePage = true;
        FocusManager.instance.primaryFocus?.unfocus();
        Get.back(result: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success('app.trade.buy.message.success'.tr);
        });
        return;
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.10)),
      ),
      child: Center(child: child),
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

    return Scaffold(
      appBar: AppBar(title: Text('app.market.detail.bulk_buying.title'.tr)),
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
                            width: 84,
                            height: 84,
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
                    Expanded(
                      child: _buildInputShell(
                        context,
                        child: TextField(
                          controller: _priceController,
                          focusNode: _priceFocusNode,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            height: 1.15,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'app.trade.buy.price_placeholder'.tr,
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.78,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onPriceInputChanged,
                          onEditingComplete: _queryMatchedOnSale,
                          onSubmitted: (_) => _queryMatchedOnSale(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildRowContainer(
              context,
              withTopGap: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputShell(
                            context,
                            child: TextField(
                              controller: _numController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 15,
                                height: 1.15,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText:
                                    'app.trade.purchase.placeholder_num'.tr,
                                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: _sanitizeNum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _isLoadingMatches
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest
                                          .withValues(alpha: 0.42),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${_matchedItems.length} ${'app.market.detail.bulk_buying.match'.tr}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      : Text('app.trade.buy.text'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkWearQuickOption {
  final double min;
  final double max;

  const _BulkWearQuickOption(this.min, this.max);

  String get minText => min.toStringAsFixed(2);

  String get maxText => max.toStringAsFixed(2);

  String get label => '${min.toStringAsFixed(2)}-${max.toStringAsFixed(2)}';
}

class _BulkWearRange {
  final double? min;
  final double? max;

  const _BulkWearRange({this.min, this.max});
}
