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

    final user = UserStorage.getUserInfo();
    final useAuth = user != null;
    final userId = int.tryParse(user?.id ?? '');

    setState(() => _isLoadingMatches = true);
    try {
      final res = await _marketApi.onSaleList(
        appId: _appId,
        schemaId: _schemaId,
        page: 1,
        pageSize: 100,
        maxPrice: maxPrice,
        userId: userId,
        paintWearMin: _wearMin,
        paintWearMax: _wearMax,
        useAuth: useAuth,
        fallbackToPublicOnFail: true,
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

    try {
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
                      'app.market.filter.text'.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
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
                            decoration: InputDecoration(
                              labelText: 'app.market.filter.price_lowest'.tr,
                              hintText: minWearHint,
                            ),
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
                            decoration: InputDecoration(
                              labelText: 'app.market.filter.price_highest'.tr,
                              hintText: maxWearHint,
                            ),
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
                            onPressed: () {
                              setModalState(() {
                                wearMinController.clear();
                                wearMaxController.clear();
                              });
                            },
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
                              Navigator.of(context).pop(normalized);
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

      if (result == null) {
        return;
      }

      setState(() {
        _wearMin = result.min;
        _wearMax = result.max;
        _filterLabel = _buildFilterLabel();
      });
      await _queryMatchedOnSale();
    } finally {
      wearMinController.dispose();
      wearMaxController.dispose();
    }
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

  Widget _buildRowContainer(
    BuildContext context, {
    required Widget child,
    bool withTopGap = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(top: withTopGap ? 10 : 0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.14)),
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.14)),
        ),
      ),
      child: child,
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _buildRowContainer(
            context,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => Text(
                            '${'app.market.detail.sale_lowest'.tr}: ${currency.format(sellMin)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            '${'app.market.detail.purchase_highest'.tr}: ${currency.format(buyMax)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
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
          if (_showFilter)
            _buildRowContainer(
              context,
              child: InkWell(
                onTap: _openFilterSheet,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          'app.market.filter.text'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
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
                    width: 112,
                    child: Text(
                      'app.market.detail.bulk_buying.price_highest'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'app.trade.buy.price_placeholder'.tr,
                        border: InputBorder.none,
                      ),
                      onChanged: _sanitizePrice,
                      onEditingComplete: _queryMatchedOnSale,
                      onSubmitted: (_) => _queryMatchedOnSale(),
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
                    width: 112,
                    child: Text(
                      'app.trade.buy.quantity'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _numController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'app.trade.buy.num_placeholder'.tr,
                        border: InputBorder.none,
                      ),
                      onChanged: _sanitizeNum,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoadingMatches)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        '${_matchedItems.length}${'app.market.detail.bulk_buying.match'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(color: colors.outline.withValues(alpha: 0.16)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                height: 40,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
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
