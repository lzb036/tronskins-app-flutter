import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/inventory.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/inventory_item_card.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class BuyingSupplyPage extends StatefulWidget {
  const BuyingSupplyPage({super.key});

  @override
  State<BuyingSupplyPage> createState() => _BuyingSupplyPageState();
}

class _BuyingSupplyPageState extends State<BuyingSupplyPage> {
  final ApiInventoryServer _inventoryApi = ApiInventoryServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final ApiSteamServer _steamApi = ApiSteamServer();

  late final BuyRequestItem _request;
  ShopSchemaInfo? _schema;

  final List<InventoryItem> _items = [];
  final Map<String, ShopSchemaInfo> _schemas = {};
  final Set<int> _selectedIds = <int>{};
  final ScrollController _scrollController = ScrollController();

  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  double _feeRate = 0;
  bool _loadingFee = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _request = _parseRequest(args['item']);
    _schema = _parseSchema(args['schema']);
    _scrollController.addListener(_handleScroll);
    _loadFeeRate();
    _refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  BuyRequestItem _parseRequest(dynamic raw) {
    if (raw is BuyRequestItem) {
      return raw;
    }
    if (raw is Map) {
      return BuyRequestItem.fromJson(Map<String, dynamic>.from(raw));
    }
    return const BuyRequestItem(raw: {});
  }

  ShopSchemaInfo? _parseSchema(dynamic raw) {
    if (raw is ShopSchemaInfo) {
      return raw;
    }
    if (raw is Map) {
      return ShopSchemaInfo.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  int get _maxNeed {
    final need = _request.need ?? _request.nums ?? 0;
    return need < 0 ? 0 : need;
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadInventory();
    }
  }

  Future<void> _refresh() async {
    _page = 1;
    _hasMore = true;
    _items.clear();
    _selectedIds.clear();
    await _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (_isLoading || !_hasMore) {
      return;
    }
    final appId = _request.appId ?? 730;
    final schemaId = _request.schemaId;
    if (schemaId == null) {
      _hasMore = false;
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _inventoryApi.inventoryList(
        appId: appId,
        page: _page,
        pageSize: 50,
        schemaId: schemaId,
        canSupply: true,
      );
      final data = res.datas;
      if (data == null || data.items.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(data.items);
        _page += 1;
      }
      _schemas.addAll(data?.schemas ?? const {});
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFeeRate() async {
    try {
      final res = await _shopApi.getSysParams();
      if (res.datas is Map<String, dynamic>) {
        final fee = res.datas?['fee'];
        if (fee is num) {
          _feeRate = fee.toDouble();
        } else {
          _feeRate = double.tryParse(fee?.toString() ?? '') ?? 0;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFee = false);
      }
    }
  }

  bool _isSelectable(InventoryItem item) {
    final isCooling =
        (item.coolingDown ?? false) || (item.cooldown?.isNotEmpty == true);
    final isTradable = item.tradable ?? true;
    final inSupply = item.status == 2;
    return isTradable && !isCooling && !inSupply;
  }

  void _toggleSelection(InventoryItem item) {
    final id = item.id;
    if (id == null) {
      return;
    }
    final isCooling =
        (item.coolingDown ?? false) || (item.cooldown?.isNotEmpty == true);
    final isTradable = item.tradable ?? true;
    if (isCooling) {
      AppSnackbar.info('app.market.product.cooling'.tr);
      return;
    }
    if (!isTradable) {
      AppSnackbar.info('app.inventory.message.non_tradable'.tr);
      return;
    }
    if (item.status == 2) {
      AppSnackbar.info('app.inventory.in_supply'.tr);
      return;
    }
    if (!_selectedIds.contains(id) && _maxNeed > 0) {
      if (_selectedIds.length >= _maxNeed) {
        AppSnackbar.info('app.trade.supply.message.more_than_needed'.tr);
        return;
      }
    }
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    final available = _items.where(_isSelectable).toList();
    final limit = _maxNeed > 0 ? _maxNeed : available.length;
    if (limit <= 0) {
      return;
    }
    setState(() {
      if (_selectedIds.length >= limit) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(
            available
                .where((item) => item.id != null)
                .map((item) => item.id!)
                .take(limit),
          );
      }
    });
  }

  double _totalAmount() {
    final price = _request.price ?? 0;
    return price * _selectedIds.length;
  }

  double _feeAmount() {
    final fee = _totalAmount() * _feeRate;
    return (fee * 100).floor() / 100;
  }

  double _incomeAmount() {
    final income = _totalAmount() - _feeAmount();
    return (income * 100).round() / 100;
  }

  Future<void> _showConfirmDialog() async {
    if (_selectedIds.isEmpty) {
      AppSnackbar.error('app.trade.supply.message.not_selected'.tr);
      return;
    }
    if (_maxNeed > 0 && _selectedIds.length > _maxNeed) {
      AppSnackbar.info('app.trade.supply.message.more_than_needed'.tr);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _SupplyConfirmDialog(
          count: _selectedIds.length,
          total: _totalAmount(),
          fee: _feeAmount(),
          income: _incomeAmount(),
        );
      },
    );
    if (confirmed == true) {
      await _submitSupply();
    }
  }

  Future<void> _submitSupply() async {
    if (_isSubmitting) {
      return;
    }
    final requestId = _request.id;
    final appId = _request.appId;
    final price = _request.price;
    if (requestId == null || appId == null || price == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
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

      final res = await _shopApi.orderItemSupply(
        params: {
          'appid': appId,
          'id': requestId,
          'price': price,
          'ids': _selectedIds.toList(),
        },
      );
      final datas = res.datas;
      if (datas is String) {
        if (datas.contains('Steam issue')) {
          await Get.dialog<void>(
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
          final user = UserStorage.getUserInfo();
          final nickname = user?.config?.nickname ?? user?.nickname ?? '';
          await Get.dialog<void>(
            AlertDialog(
              title: Text('app.system.tips.title'.tr),
              content: Text('${'app.inventory.message.privacy'.tr}$nickname'),
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

      final dataText = datas?.toString().trim();
      if (res.success) {
        FocusManager.instance.primaryFocus?.unfocus();
        Get.back(result: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success('app.trade.supply.message.success'.tr);
        });
        return;
      }

      final errorText = (dataText?.isNotEmpty ?? false)
          ? dataText!
          : (res.message.trim().isNotEmpty
                ? res.message
                : 'app.trade.filter.failed'.tr);
      AppSnackbar.error(errorText);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final fallbackSchema =
        _schema ?? _schemas[_request.schemaId?.toString() ?? ''];
    final headerTitle =
        fallbackSchema?.marketName ??
        fallbackSchema?.marketHashName ??
        _request.raw['market_name']?.toString() ??
        '-';
    final imageUrl =
        fallbackSchema?.imageUrl ?? _request.raw['image_url']?.toString() ?? '';
    final price = _request.price ?? 0;
    final maxNeed = _maxNeed;
    final isAllSelected = maxNeed > 0
        ? _selectedIds.length >= maxNeed
        : _items.isNotEmpty && _selectedIds.length >= _items.length;
    final headerAppId = _request.appId ?? 730;
    return Scaffold(
      appBar: AppBar(title: Text('app.trade.supply.inventory'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 58,
                      child: GameItemImage(
                        imageUrl: imageUrl,
                        appId: headerAppId,
                        count: maxNeed > 0 ? maxNeed : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Obx(
                            () => Text(
                              currency.format(price),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (maxNeed > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_selectedIds.length}/$maxNeed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  'app.trade.supply.message.select_inventory'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length}/${_items.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_items.isEmpty && _isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_items.isEmpty)
                    SliverFillRemaining(
                      child: Center(child: Text('app.common.no_data'.tr)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.74,
                            ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final schema = _lookupSchema(item);
                          final selected = _selectedIds.contains(item.id ?? -1);
                          final isCooling =
                              (item.coolingDown ?? false) ||
                              (item.cooldown?.isNotEmpty == true);
                          final isTradable = item.tradable ?? true;
                          final inSupply = item.status == 2;
                          final disabled = !isTradable || isCooling || inSupply;
                          final disabledLabel = !isTradable
                              ? 'app.trade.non_tradable'.tr
                              : isCooling
                              ? 'app.market.product.cooling'.tr
                              : inSupply
                              ? 'app.inventory.in_supply'.tr
                              : null;
                          return InventoryItemCard(
                            item: item,
                            schema: schema,
                            useSchemaBuffMinPrice: false,
                            selected: selected,
                            disabledLabel: disabled ? disabledLabel : null,
                            onTap: () => _toggleSelection(item),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildLoadMoreFooter()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
              IconButton(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  isAllSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
              ),
              Text(
                '${_selectedIds.length}/${_items.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isSubmitting || _loadingFee
                    ? null
                    : _showConfirmDialog,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('app.trade.supply.text'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (!_hasMore && _items.isNotEmpty) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }
    return const SizedBox(height: 4);
  }
}

class _SupplyConfirmDialog extends StatelessWidget {
  const _SupplyConfirmDialog({
    required this.count,
    required this.total,
    required this.fee,
    required this.income,
  });

  final int count;
  final double total;
  final double fee;
  final double income;

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final points = (total * 100).floor() / 100;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.trade.supply.text'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRow(
              context,
              label: 'app.inventory.count'.tr,
              value: '$count ${'app.market.unit_qty'.tr}',
            ),
            Obx(
              () => _buildRow(
                context,
                label: 'app.inventory.upshop.expected_income'.tr,
                value: currency.format(total),
              ),
            ),
            Obx(
              () => _buildRow(
                context,
                label: 'app.inventory.upshop.handling_charge'.tr,
                value: currency.format(fee),
              ),
            ),
            Obx(
              () => _buildRow(
                context,
                label: 'app.trade.supply.actual_income'.tr,
                value: currency.format(income),
                highlight: true,
              ),
            ),
            _buildRow(
              context,
              label: 'app.user.integral.award'.tr,
              value:
                  '${points.toStringAsFixed(2)} ${'app.user.integral.unit'.tr}',
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
                    child: Text('app.trade.supply.text'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final style = Theme.of(context).textTheme.bodyMedium!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(
              color: highlight
                  ? Theme.of(context).colorScheme.primary
                  : style.color,
              fontWeight: highlight ? FontWeight.w600 : style.fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
