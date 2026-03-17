import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/glass_notice_dialog.dart';
import 'package:tronskins_app/components/game/game_icon_button.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/shop_sale_item_card.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/components/notify/notify_trade_deliver_sheet.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_order_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_sales_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_shipping_notice_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

enum _ShopTabFilter { onSale, pending, saleRecord }

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  final ShopController shopController = Get.isRegistered<ShopController>()
      ? Get.find<ShopController>()
      : Get.put(ShopController());
  final ShopSalesController salesController =
      Get.isRegistered<ShopSalesController>()
      ? Get.find<ShopSalesController>()
      : Get.put(ShopSalesController());
  final ShopOrderController orderController =
      Get.isRegistered<ShopOrderController>()
      ? Get.find<ShopOrderController>()
      : Get.put(ShopOrderController());
  final ShopShippingNoticeController shippingNoticeController =
      Get.isRegistered<ShopShippingNoticeController>()
      ? Get.find<ShopShippingNoticeController>()
      : Get.put(ShopShippingNoticeController(), permanent: true);
  final UserController userController = Get.find<UserController>();

  late final TabController _tabController;
  int _activeTab = 0;
  final ScrollController _onSaleScroll = ScrollController();
  final ScrollController _pendingScroll = ScrollController();
  final ScrollController _recordScroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pendingSearchController =
      TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  final Set<int> _refreshingPendingBuyerOrderIds = <int>{};
  Worker? _loginWorker;
  Worker? _shopTargetTabWorker;
  static const List<StatusOption> _statusOptions = [
    StatusOption(
      labelKey: 'app.market.filter.all',
      values: [-2, -1, 1, 3, 4, 5, 6, 9],
    ),
    StatusOption(labelKey: 'app.trade.filter.in', values: [2, 3, 4]),
    StatusOption(labelKey: 'app.trade.filter.failed', values: [-1]),
    StatusOption(labelKey: 'app.trade.filter.revoked', values: [-2]),
    StatusOption(labelKey: 'app.trade.filter.settling', values: [5]),
    StatusOption(labelKey: 'app.trade.filter.success', values: [6]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _activeTab = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _onSaleScroll.addListener(_handleOnSaleScroll);
    _pendingScroll.addListener(_handlePendingScroll);
    _recordScroll.addListener(_handleRecordScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarketFilterSheet.preload(appId: GameStorage.getGameType());
    });
    final navController = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    _shopTargetTabWorker = ever<int?>(navController.pendingShopTabIndex, (
      targetTab,
    ) {
      if (targetTab == null) {
        return;
      }
      _switchToShopTab(targetTab);
      navController.clearPendingShopTab();
    });
    final initialTargetTab = navController.pendingShopTabIndex.value;
    if (initialTargetTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _switchToShopTab(initialTargetTab);
        navController.clearPendingShopTab();
      });
    }

    if (userController.isLoggedIn.value) {
      salesController.refreshOnSale();
      orderController.refreshPending();
      salesController.refreshSellRecords();
      shippingNoticeController.refreshPendingTotals();
    }

    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        salesController.refreshOnSale();
        orderController.refreshPending();
        salesController.refreshSellRecords();
        shippingNoticeController.refreshPendingTotals();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _onSaleScroll
      ..removeListener(_handleOnSaleScroll)
      ..dispose();
    _pendingScroll
      ..removeListener(_handlePendingScroll)
      ..dispose();
    _recordScroll
      ..removeListener(_handleRecordScroll)
      ..dispose();
    _searchController.dispose();
    _pendingSearchController.dispose();
    _recordSearchController.dispose();
    _loginWorker?.dispose();
    _shopTargetTabWorker?.dispose();
    super.dispose();
  }

  void _switchToShopTab(int targetTab) {
    final safeIndex = targetTab.clamp(0, _tabController.length - 1).toInt();
    if (_tabController.index == safeIndex) {
      return;
    }
    _tabController.animateTo(safeIndex);
  }

  void _handleTabChange() {
    if (_tabController.index == _activeTab) {
      return;
    }
    setState(() {
      _activeTab = _tabController.index;
      if (_activeTab != 0 && _selectedIds.isNotEmpty) {
        _selectedIds.clear();
      }
    });
  }

  void _handleOnSaleScroll() {
    if (_onSaleScroll.position.pixels >
        _onSaleScroll.position.maxScrollExtent - 200) {
      salesController.loadOnSale();
    }
  }

  void _handlePendingScroll() {
    if (_pendingScroll.position.pixels >
        _pendingScroll.position.maxScrollExtent - 200) {
      orderController.loadPendingShipments();
    }
  }

  void _handleRecordScroll() {
    if (_recordScroll.position.pixels >
        _recordScroll.position.maxScrollExtent - 200) {
      salesController.loadSellRecords();
    }
  }

  void _toggleSelection(ShopItemAsset item) {
    final id = item.id;
    if (id == null) {
      return;
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
    final ids = salesController.onSaleItems
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    setState(() {
      if (_selectedIds.length == ids.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _confirmDelist() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.inventory.message.confirm_delist'.tr),
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
    if (confirmed != true) {
      return;
    }
    try {
      final res = await salesController.delistItems(_selectedIds.toList());
      if (res.success) {
        setState(_selectedIds.clear);
        AppSnackbar.success('app.system.message.success'.tr);
      } else {
        AppSnackbar.error(
          res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
        );
      }
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    }
  }

  ShopSchemaInfo? _lookupSchema(
    Map<String, ShopSchemaInfo> schemas,
    String? marketHashName,
    int? schemaId,
  ) {
    if (marketHashName != null && schemas.containsKey(marketHashName)) {
      return schemas[marketHashName];
    }
    final key = schemaId?.toString();
    if (key != null && schemas.containsKey(key)) {
      return schemas[key];
    }
    return null;
  }

  TagInfo? _schemaTag(ShopSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  int _resolveDetailAppId(ShopOrderDetail detail, ShopSchemaInfo? schema) {
    final raw = detail.raw;
    final schemaRaw = schema?.raw;
    final rawApp = raw['app_id'] ?? raw['appId'];
    final schemaApp = schemaRaw?['app_id'] ?? schemaRaw?['appId'];
    return _asInt(rawApp) ?? _asInt(schemaApp) ?? GameStorage.getGameType();
  }

  String? _detailText(ShopOrderDetail detail, List<String> keys) {
    final raw = detail.raw;
    for (final key in keys) {
      final value = raw[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  double? _detailDouble(ShopOrderDetail detail, List<String> keys) {
    final raw = detail.raw;
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
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  double _sumOrderPrice(ShopOrderItem order) {
    if (order.price != null) {
      return order.price!;
    }
    double total = 0;
    for (final detail in order.details) {
      final unit = detail.price ?? 0;
      final count = detail.count ?? 1;
      total += unit * count;
    }
    return total;
  }

  int _pendingShippingType(ShopOrderItem order) {
    for (final detail in order.details) {
      if (detail.type == 2) {
        return 2;
      }
    }
    return 1;
  }

  double _pendingShippingHours(ShopOrderItem order) {
    final status = order.status;
    final type = _pendingShippingType(order);
    if (status == 3) {
      return 0.5;
    }
    if (type == 2 && status == 2) {
      return 0.5;
    }
    if (type == 1 && status == 2) {
      return 18;
    }
    if (status == 4) {
      return 18;
    }
    return 18;
  }

  int _pendingDeadlineMs(ShopOrderItem order) {
    final changeTime = order.changeTime;
    if (changeTime == null || changeTime <= 0) {
      return 0;
    }
    final shippingMs = (_pendingShippingHours(order) * 3600 * 1000).round();
    return changeTime * 1000 + shippingMs;
  }

  int _pendingRemainMs(ShopOrderItem order) {
    final deadline = _pendingDeadlineMs(order);
    if (deadline <= 0) {
      return 0;
    }
    final remain = deadline - DateTime.now().millisecondsSinceEpoch;
    return remain > 0 ? remain : 0;
  }

  bool _showPendingCountdown(ShopOrderItem order) {
    return _pendingRemainMs(order) > 0;
  }

  int _pendingOrderKey(ShopOrderItem order) {
    return order.id ?? order.hashCode;
  }

  ShopOrderItem _copyOrderWithUser(ShopOrderItem source, ShopUserInfo? user) {
    return ShopOrderItem(
      raw: source.raw,
      id: source.id,
      status: source.status,
      statusName: source.statusName,
      createTime: source.createTime,
      changeTime: source.changeTime,
      price: source.price,
      totalPrice: source.totalPrice,
      nums: source.nums,
      protectionTime: source.protectionTime,
      type: source.type,
      tradeOfferId: source.tradeOfferId,
      cancelDesc: source.cancelDesc,
      buyerId: source.buyerId,
      details: source.details,
      user: user,
    );
  }

  Future<void> _refreshPendingBuyer(ShopOrderItem order) async {
    final buyerId = (order.buyerId ?? order.user?.id ?? '').trim();
    if (buyerId.isEmpty) {
      return;
    }
    final orderKey = _pendingOrderKey(order);
    if (_refreshingPendingBuyerOrderIds.contains(orderKey)) {
      return;
    }
    setState(() {
      _refreshingPendingBuyerOrderIds.add(orderKey);
    });
    try {
      final res = await ApiSteamServer().getSteamUserInfo(id: buyerId);
      final data = res.datas;
      if (res.code == 0 && data != null) {
        final mergedUser = ShopUserInfo(
          id: data['id']?.toString() ?? order.user?.id ?? buyerId,
          uuid: data['uuid']?.toString() ?? order.user?.uuid,
          avatar: data['avatar']?.toString() ?? order.user?.avatar,
          nickname: data['nickname']?.toString() ?? order.user?.nickname,
          level: _asInt(data['level']) ?? order.user?.level,
          yearsLevel: _asInt(data['yearsLevel']) ?? order.user?.yearsLevel,
        );
        orderController.users[buyerId] = mergedUser;
        final updated = orderController.pendingShipments
            .map((item) {
              final sameOrder = order.id != null && item.id == order.id;
              final sameBuyer = item.buyerId == buyerId;
              if (!sameOrder && !sameBuyer) {
                return item;
              }
              return _copyOrderWithUser(item, mergedUser);
            })
            .toList(growable: false);
        orderController.pendingShipments.assignAll(updated);
        if (mounted) {
          unawaited(
            showGlassNoticeDialog(
              context,
              message: 'app.steam.message.refresh_info_success'.tr,
              icon: Icons.check_circle_outline_rounded,
              barrierLabel: 'refresh_pending_buyer_success',
            ),
          );
        }
      } else {
        final dataText = _extractApiErrorText(data);
        final message = (dataText?.isNotEmpty ?? false)
            ? dataText!
            : (res.message.trim().isNotEmpty
                  ? res.message
                  : 'app.trade.filter.failed'.tr);
        if (mounted) {
          unawaited(
            showGlassNoticeDialog(
              context,
              message: message,
              icon: Icons.error_outline_rounded,
              barrierLabel: 'refresh_pending_buyer_failed',
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        unawaited(
          showGlassNoticeDialog(
            context,
            message: 'app.trade.filter.failed'.tr,
            icon: Icons.error_outline_rounded,
            barrierLabel: 'refresh_pending_buyer_failed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingPendingBuyerOrderIds.remove(orderKey);
        });
      }
    }
  }

  String? _extractApiErrorText(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final candidates = [
      data['_message'],
      data['message'],
      data['msg'],
      data['datas'],
      data['error'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  Widget _buildPendingBuyerInfo(ShopOrderItem order) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = order.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final nickname = (user.nickname ?? '').trim();
    final level = user.level;
    final yearsLevel = user.yearsLevel;
    final refreshing = _refreshingPendingBuyerOrderIds.contains(
      _pendingOrderKey(order),
    );
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Image.asset(
            'assets/images/login/steam-icon.png',
            width: 16,
            height: 16,
            errorBuilder: (_, __, ___) => Icon(
              Icons.sports_esports,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              nickname.isEmpty ? '-' : nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (level != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.7),
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$level',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (yearsLevel != null) ...[
            const SizedBox(width: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                'https://community.cloudflare.steamstatic.com/public/images/badges/02_years/steamyears${yearsLevel}_80.png',
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: refreshing ? null : () => _refreshPendingBuyer(order),
            child: SizedBox(
              width: 18,
              height: 18,
              child: Center(
                child: refreshing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, size: 14, color: colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatusAction(ShopOrderItem order) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = order.status;
    if (status == 2) {
      return FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(92, 34),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openDeliverSheet(order),
        child: Text('app.market.product.deliver'.tr),
      );
    }
    if (status == 3) {
      return Text(
        'app.steam.message.confirm_quote'.tr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final statusText = (order.statusName ?? '').trim().isEmpty
        ? '-'
        : (order.statusName ?? '').trim();
    final statusColor = status == -1
        ? colorScheme.onSurfaceVariant
        : colorScheme.error;
    return Text(
      statusText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _resolveDetailTitle(
    ShopOrderDetail detail,
    Map<String, ShopSchemaInfo> schemas,
  ) {
    final schema = _lookupSchema(
      schemas,
      detail.marketHashName,
      detail.schemaId,
    );
    return detail.marketName ?? schema?.marketName ?? '-';
  }

  List<String> _buildMultiDetailTitleLines({
    required List<ShopOrderDetail> details,
    required Map<String, ShopSchemaInfo> schemas,
    int maxVisibleNames = 3,
  }) {
    if (details.isEmpty) {
      return const ['-'];
    }
    final names = details
        .map((detail) => _resolveDetailTitle(detail, schemas))
        .toList(growable: false);
    final visible = names.take(maxVisibleNames).toList(growable: false);
    final hasOverflow = names.length > maxVisibleNames;
    final lines = <String>[];
    for (var i = 0; i < visible.length; i++) {
      final name = visible[i];
      final isLastVisible = i == visible.length - 1;
      final suffix = hasOverflow && isLastVisible ? '...' : '';
      lines.add('. $name$suffix');
    }
    return lines;
  }

  Widget _buildSellRecordDetailImage({
    required ShopOrderDetail detail,
    required Map<String, ShopSchemaInfo> schemas,
  }) {
    final schema = _lookupSchema(
      schemas,
      detail.marketHashName,
      detail.schemaId,
    );
    final appId = _resolveDetailAppId(detail, schema);
    final imageUrl = detail.imageUrl ?? schema?.imageUrl ?? '';
    final rarity = _schemaTag(schema, 'rarity');
    final quality = _schemaTag(schema, 'quality');
    final phase = _detailText(detail, ['phase']);
    final percentage = _detailText(detail, ['percentage']);
    final rawAsset = detail.raw['asset'];
    final rawCsgoAsset = detail.raw['csgoAsset'];
    final stickerRaw =
        detail.raw['stickers'] ??
        (rawAsset is Map ? rawAsset['stickers'] : null) ??
        (rawCsgoAsset is Map ? rawCsgoAsset['stickers'] : null);
    final stickers = parseStickerList(
      stickerRaw,
      schemaMap: schemas,
      stickerMap: salesController.stickers,
    );
    final count = detail.count ?? 1;
    return SizedBox(
      width: 72,
      height: 43,
      child: GameItemImage(
        imageUrl: imageUrl,
        appId: appId,
        rarity: rarity,
        quality: quality,
        phase: phase,
        percentage: percentage,
        count: count > 1 ? count : null,
        stickers: stickers,
      ),
    );
  }

  Widget _buildSellRecordDetailOverflowHint(int hiddenCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 43,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text('+$hiddenCount', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  String _buildRecordStatusText(ShopOrderItem record) {
    final status = record.status;
    if (status == 6) {
      return 'app.trade.sale.success'.tr;
    }
    final statusName = record.statusName?.trim();
    if ([2, 3, 4].contains(status)) {
      return (statusName == null || statusName.isEmpty) ? '-' : statusName;
    }
    final cancelDesc = record.cancelDesc?.trim();
    if (![2, 3, 4, 5, 6].contains(status) &&
        cancelDesc != null &&
        cancelDesc.isNotEmpty) {
      return cancelDesc;
    }
    if (statusName != null && statusName.isNotEmpty) {
      return statusName;
    }
    return '-';
  }

  ({Color bg, Color fg}) _recordStatusPalette(int? status) {
    if ([5, 6].contains(status)) {
      return (bg: const Color(0xFFE8F5E9), fg: const Color(0xFF008000));
    }
    if ([2, 3, 4].contains(status)) {
      return (bg: const Color(0xFFFDECEC), fg: const Color(0xFFC22121));
    }
    return (bg: const Color(0xFFF5F5F5), fg: const Color(0xFF888888));
  }

  Widget _buildRecordStatusBadge(
    ShopOrderItem record, {
    double maxWidth = 160,
  }) {
    final palette = _recordStatusPalette(record.status);
    final statusText = _buildRecordStatusText(record);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          statusText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: palette.fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordInfoChip({required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _showRecordCountdown(ShopOrderItem record) {
    final protectionTime = record.protectionTime;
    return protectionTime != null && protectionTime > 0 && record.status == 5;
  }

  Future<void> _openOnSaleFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.price', field: 'price'),
        SortOption(labelKey: 'app.market.filter.hot', field: 'hot'),
      ],
      initial: MarketFilterResult(
        sortField: salesController.onSaleSortField.value,
        sortAsc: salesController.onSaleSortAsc.value,
        priceMin: salesController.onSalePriceMin.value,
        priceMax: salesController.onSalePriceMax.value,
        tags: Map<String, dynamic>.from(salesController.onSaleTags),
        itemName: salesController.onSaleItemName.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _searchController.clear();
      }
      await salesController.applyOnSaleFilter(
        sortField: result.sortField,
        sortAsc: result.sortAsc,
        minPrice: result.priceMin,
        maxPrice: result.priceMax,
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  Future<void> _openPendingFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      showSort: false,
      showPriceRange: false,
      initial: MarketFilterResult(
        sortField: orderController.pendingSortField.value,
        sortAsc: orderController.pendingSortAsc.value,
        tags: Map<String, dynamic>.from(orderController.pendingTags),
        itemName: orderController.pendingItemName.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _pendingSearchController.clear();
      }
      await orderController.applyPendingFilter(
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  Future<void> _openSellRecordFilterSheet() async {
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: GameStorage.getGameType(),
      sortOptions: const [
        SortOption(labelKey: 'app.market.filter.time', field: 'time'),
      ],
      showSort: false,
      showPriceRange: false,
      showStatus: true,
      showDateRange: true,
      statusOptions: _statusOptions,
      initial: MarketFilterResult(
        sortField: salesController.recordSortField.value,
        sortAsc: salesController.recordSortAsc.value,
        tags: Map<String, dynamic>.from(salesController.recordTags),
        itemName: salesController.recordItemName.value,
        statusList: salesController.recordStatusList.toList(),
        startDate: salesController.recordStartDate.value,
        endDate: salesController.recordEndDate.value,
      ),
    );
    if (result != null) {
      if (result.clearKeyword) {
        _recordSearchController.clear();
      }
      await salesController.applyRecordFilter(
        statusList: result.statusList,
        startDate: result.startDate,
        endDate: result.endDate,
        sortAsc: result.sortAsc,
        sortField: result.sortField,
        tags: result.tags,
        itemName: result.itemName,
        keyword: result.clearKeyword ? '' : null,
      );
    }
  }

  _ShopTabFilter _currentShopTabFilter() {
    switch (_activeTab) {
      case 1:
        return _ShopTabFilter.pending;
      case 2:
        return _ShopTabFilter.saleRecord;
      case 0:
      default:
        return _ShopTabFilter.onSale;
    }
  }

  String _shopTabLabelKey(_ShopTabFilter filter) {
    switch (filter) {
      case _ShopTabFilter.onSale:
        return 'app.trade.onSale.text';
      case _ShopTabFilter.pending:
        return 'app.market.product.wait_for_sending';
      case _ShopTabFilter.saleRecord:
        return 'app.user.menu.sale';
    }
  }

  IconData _shopTabIcon(_ShopTabFilter filter) {
    switch (filter) {
      case _ShopTabFilter.onSale:
        return Icons.storefront_outlined;
      case _ShopTabFilter.pending:
        return Icons.local_shipping_outlined;
      case _ShopTabFilter.saleRecord:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _openShopTabSwitchMenu(BuildContext iconContext) async {
    final currentFilter = _currentShopTabFilter();
    final currentAppId = GameStorage.getGameType();
    final pendingTotal = shippingNoticeController.pendingCount(currentAppId);
    final selected = await _showShopTabSwitchMenu(
      iconContext: iconContext,
      currentFilter: currentFilter,
      pendingTotal: pendingTotal,
    );
    if (selected == null || selected == currentFilter) {
      return;
    }

    final targetIndex = switch (selected) {
      _ShopTabFilter.onSale => 0,
      _ShopTabFilter.pending => 1,
      _ShopTabFilter.saleRecord => 2,
    };
    if (targetIndex != _tabController.index) {
      _tabController.animateTo(targetIndex);
    }
  }

  Widget _buildShopTabSwitcher() {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final filter = _currentShopTabFilter();
    final label = _shopTabLabelKey(filter).tr;
    return Builder(
      builder: (iconContext) {
        return Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openShopTabSwitchMenu(iconContext),
              child: Obx(() {
                final currentAppId = GameStorage.getGameType();
                final hasPendingInCurrentGame =
                    shippingNoticeController.pendingCount(currentAppId) > 0;
                final content = SizedBox(
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _shopTabIcon(filter),
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 72),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return _buildTopActionWithDot(
                  visible: hasPendingInCurrentGame,
                  dotColor: Colors.orange.shade600,
                  child: content,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopIconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionWithDot({
    required Widget child,
    required Color dotColor,
    required bool visible,
  }) {
    if (!visible) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopSummaryBar(CurrencyController currency) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseStart = isDark ? colors.surfaceContainerHigh : Colors.white;
    final baseEnd = isDark
        ? colors.surfaceContainer
        : colors.primary.withValues(alpha: 0.05);
    final borderColor = colors.outline.withValues(alpha: 0.18);

    return Obx(() {
      final count = salesController.totalOnSale.value;
      final totalValue = salesController.totalOnSalePrice.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseStart, baseEnd],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.03),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildShopSummaryMetric(
                label: 'app.inventory.count'.tr,
                value: '$count',
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            Expanded(
              child: _buildShopSummaryMetric(
                label: 'app.inventory.total_value'.tr,
                value: currency.format(totalValue),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShopSummaryMetric({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnSaleSelectAllToggle({
    required bool selected,
    required bool enabled,
  }) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = colors.outline.withValues(alpha: 0.45);
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Tooltip(
        message: selected
            ? 'app.common.deselect_all'.tr
            : 'app.common.select_all'.tr,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: enabled ? _toggleSelectAll : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: colors.primary, size: 16)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Obx(() {
        if (!userController.isLoggedIn.value) {
          return _buildLoginPrompt();
        }
        final isShopOnline = shopController.shop.value?.isOnline ?? false;
        return SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outline.withValues(alpha: 0.08),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'app.user.menu.shop'.tr,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildShopTabSwitcher(),
                          const SizedBox(width: 6),
                          _buildTopActionWithDot(
                            visible: true,
                            dotColor: isShopOnline
                                ? const Color(0xFF22C55E)
                                : colors.outlineVariant,
                            child: _buildTopIconAction(
                              icon: Icons.settings,
                              tooltip: 'app.user.shop.setting'.tr,
                              onTap: () => Get.toNamed(Routers.SHOP_SETTING),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (iconContext) {
                              return Obx(() {
                                final currentAppId = GameStorage.getGameType();
                                final hasPendingInAnyGame =
                                    shippingNoticeController.hasAnyPending;
                                return _buildTopActionWithDot(
                                  visible: hasPendingInAnyGame,
                                  dotColor: Colors.orange.shade600,
                                  child: GameIconButton(
                                    appId: currentAppId,
                                    size: 34,
                                    onTap: () async {
                                      final selected = await showGameSwitchMenu(
                                        iconContext: iconContext,
                                        currentAppId: currentAppId,
                                        pendingTotalsByAppId:
                                            shippingNoticeController
                                                .snapshotTotals(),
                                      );
                                      if (selected == null) {
                                        return;
                                      }
                                      await GameStorage.setGameType(selected);
                                      salesController.refreshOnSale();
                                      orderController.refreshPending();
                                      salesController.refreshSellRecords();
                                      shippingNoticeController
                                          .refreshPendingTotals();
                                      setState(() {});
                                    },
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildSharedTabSearchBar(),
                    const SizedBox(height: 6),
                    if (_activeTab == 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildShopSummaryBar(currency),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              _buildShopStatusBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOnSaleTab(),
                    _buildPendingShipmentTab(currency),
                    _buildSellRecordTab(currency),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: _activeTab == 0 && _selectedIds.isNotEmpty
          ? _buildOnSaleActions()
          : null,
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('app.system.message.nologin'.tr),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Get.toNamed(Routers.LOGIN),
            child: Text('app.user.login.nologin'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusBanner() {
    return Obx(() {
      final shop = shopController.shop.value;
      if (shop == null || shop.isOnline == true) {
        return const SizedBox.shrink();
      }
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final borderColor = colors.error.withValues(alpha: isDark ? 0.24 : 0.12);
      final iconBackground = colors.error.withValues(
        alpha: isDark ? 0.24 : 0.10,
      );
      final bannerColor = colors.errorContainer.withValues(
        alpha: isDark ? 0.36 : 0.82,
      );
      final titleStyle = theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onErrorContainer,
      );
      final bodyStyle = theme.textTheme.bodySmall?.copyWith(
        height: 1.35,
        color: colors.onErrorContainer.withValues(alpha: 0.86),
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: colors.onErrorContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('app.user.shop.status'.tr, style: titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        'app.user.shop.message.offline'.tr,
                        style: bodyStyle,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Get.toNamed(Routers.SHOP_SETTING),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onErrorContainer,
                          backgroundColor: colors.surface.withValues(
                            alpha: isDark ? 0.14 : 0.55,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Text(
                          'app.user.shop.setting'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onErrorContainer,
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
      );
    });
  }

  Widget _buildTabSearchBar({
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onSearch,
    required IconData filterIcon,
    required VoidCallback onFilter,
    String filterTooltipKey = 'app.market.filter.text',
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final hintColor = isDark
        ? Colors.white38
        : colors.onSurface.withValues(alpha: 0.4);
    final hasKeyword = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: Material(
                color: fillColor,
                borderRadius: BorderRadius.circular(9),
                child: TextField(
                  controller: controller,
                  onSubmitted: onSubmitted,
                  onChanged: (_) {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'app.market.filter.search'.tr,
                    hintStyle: TextStyle(color: hintColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: hintColor, size: 18),
                    suffixIcon: hasKeyword
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              controller.clear();
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildSearchActionButton(
            tooltip: 'app.market.filter.search'.tr,
            icon: Icons.send,
            onTap: onSearch,
          ),
          const SizedBox(width: 6),
          _buildSearchActionButton(
            tooltip: filterTooltipKey.tr,
            icon: filterIcon,
            onTap: onFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.surfaceContainerHighest;
    final iconColor = colors.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: baseColor,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildListFooter({
    required bool showLoading,
    required bool showNoMore,
  }) {
    if (showLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (showNoMore) {
      return const ListEndTip();
    }
    return const SizedBox.shrink();
  }

  Widget _buildPullToRefreshEmpty({
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 180),
          Center(child: Text('app.common.no_data'.tr)),
        ],
      ),
    );
  }

  Widget _buildSharedTabSearchBar() {
    switch (_activeTab) {
      case 0:
        return _buildTabSearchBar(
          controller: _searchController,
          onSubmitted: salesController.searchOnSale,
          onSearch: () => salesController.searchOnSale(_searchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openOnSaleFilterSheet,
        );
      case 1:
        return _buildTabSearchBar(
          controller: _pendingSearchController,
          onSubmitted: orderController.searchPending,
          onSearch: () =>
              orderController.searchPending(_pendingSearchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openPendingFilterSheet,
        );
      case 2:
        return _buildTabSearchBar(
          controller: _recordSearchController,
          onSubmitted: salesController.searchSellRecords,
          onSearch: () =>
              salesController.searchSellRecords(_recordSearchController.text),
          filterIcon: Icons.filter_alt_outlined,
          onFilter: _openSellRecordFilterSheet,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOnSaleTab() {
    return Obx(() {
      if (salesController.onSaleItems.isEmpty &&
          salesController.isLoadingOnSale.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (salesController.onSaleItems.isEmpty) {
        return _buildPullToRefreshEmpty(
          onRefresh: salesController.refreshOnSale,
        );
      }
      final showLoadingFooter =
          salesController.isLoadingOnSale.value &&
          salesController.onSaleItems.isNotEmpty;
      final showNoMoreFooter =
          salesController.onSaleItems.isNotEmpty &&
          !salesController.isLoadingOnSale.value &&
          !salesController.onSaleHasMore;
      return RefreshIndicator(
        onRefresh: salesController.refreshOnSale,
        child: CustomScrollView(
          controller: _onSaleScroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: salesController.onSaleItems.length,
                itemBuilder: (context, index) {
                  final item = salesController.onSaleItems[index];
                  final schema = _lookupSchema(
                    salesController.schemas,
                    item.marketHashName,
                    item.schemaId,
                  );
                  final selected = _selectedIds.contains(item.id ?? -1);
                  return ShopSaleItemCard(
                    item: item,
                    schema: schema,
                    schemaMap: salesController.schemas,
                    stickerMap: salesController.stickers,
                    selected: selected,
                    onTap: () => _toggleSelection(item),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _buildListFooter(
                showLoading: showLoadingFooter,
                showNoMore: showNoMoreFooter,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPendingShipmentTab(CurrencyController currency) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Obx(() {
      if (orderController.pendingShipments.isEmpty &&
          orderController.isLoadingPending.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (orderController.pendingShipments.isEmpty) {
        return _buildPullToRefreshEmpty(
          onRefresh: orderController.refreshPending,
        );
      }
      final pendingShipments = orderController.pendingShipments;
      final showLoadingFooter =
          orderController.isLoadingPending.value && pendingShipments.isNotEmpty;
      final showNoMoreFooter =
          pendingShipments.isNotEmpty &&
          !orderController.isLoadingPending.value &&
          !orderController.pendingHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;
      return RefreshIndicator(
        onRefresh: orderController.refreshPending,
        child: ListView.separated(
          controller: _pendingScroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: pendingShipments.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= pendingShipments.length) {
              return _buildListFooter(
                showLoading: showLoadingFooter,
                showNoMore: showNoMoreFooter,
              );
            }
            final order = pendingShipments[index];
            final details = order.details;
            final hasMultipleDetails = details.length > 1;
            final totalPrice = _sumOrderPrice(order);
            final showCountdown = _showPendingCountdown(order);
            final deadlineMs = _pendingDeadlineMs(order);
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openDeliverSheet(order),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasMultipleDetails)
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currency.format(totalPrice),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (showCountdown)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 13,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      _PendingShipmentCountdown(
                                        endTimeMs: deadlineMs,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (details.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('app.common.no_data'.tr),
                        )
                      else
                        ...details.map((detail) {
                          final schema = _lookupSchema(
                            orderController.schemas,
                            detail.marketHashName,
                            detail.schemaId,
                          );
                          final appId = _resolveDetailAppId(detail, schema);
                          final imageUrl =
                              detail.imageUrl ?? schema?.imageUrl ?? '';
                          final title =
                              detail.marketName ??
                              schema?.marketName ??
                              detail.marketHashName ??
                              '-';
                          final count = detail.count ?? 1;
                          final rarity = _schemaTag(schema, 'rarity');
                          final quality = _schemaTag(schema, 'quality');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          height: 43,
                                          child: GameItemImage(
                                            imageUrl: imageUrl,
                                            appId: appId,
                                            rarity: rarity,
                                            quality: quality,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              if (!hasMultipleDetails &&
                                                  count > 1)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 3,
                                                      ),
                                                  child: Text(
                                                    'x$count',
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasMultipleDetails)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'x$count',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (showCountdown)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF3E0),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  size: 11,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 3),
                                                _PendingShipmentCountdown(
                                                  endTimeMs: deadlineMs,
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currency.format(totalPrice),
                                          style: textTheme.titleSmall?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 2),
                      Divider(
                        height: 10,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: _buildPendingBuyerInfo(order),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 34,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _buildPendingStatusAction(order),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSellRecordTab(CurrencyController currency) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (salesController.sellRecords.isEmpty &&
                salesController.isLoadingRecords.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (salesController.sellRecords.isEmpty) {
              return _buildPullToRefreshEmpty(
                onRefresh: salesController.refreshSellRecords,
              );
            }
            final sellRecords = salesController.sellRecords;
            final showLoadingFooter =
                salesController.isLoadingRecords.value &&
                sellRecords.isNotEmpty;
            final showNoMoreFooter =
                sellRecords.isNotEmpty &&
                !salesController.isLoadingRecords.value &&
                !salesController.recordHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return RefreshIndicator(
              onRefresh: salesController.refreshSellRecords,
              child: ListView.separated(
                controller: _recordScroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: sellRecords.length + (showFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= sellRecords.length) {
                    return _buildListFooter(
                      showLoading: showLoadingFooter,
                      showNoMore: showNoMoreFooter,
                    );
                  }
                  final record = sellRecords[index];
                  final primary = record.details.isNotEmpty
                      ? record.details.first
                      : null;
                  final schema = primary == null
                      ? null
                      : _lookupSchema(
                          salesController.schemas,
                          primary.marketHashName,
                          primary.schemaId,
                        );
                  final title =
                      primary?.marketName ?? schema?.marketName ?? '-';
                  final totalPrice = _sumOrderPrice(record);
                  final wearValue =
                      primary?.paintWear ??
                      (primary == null
                          ? null
                          : _detailDouble(primary, [
                              'paint_wear',
                              'paintWear',
                            ]));
                  final wearText = primary == null
                      ? null
                      : _detailText(primary, ['paint_wear', 'paintWear']) ??
                            wearValue?.toString();
                  final hasMultipleDetails = record.details.length > 1;
                  final showCountdown = _showRecordCountdown(record);
                  const maxVisibleDetails = 3;
                  final visibleDetailItems = record.details
                      .take(maxVisibleDetails)
                      .toList(growable: false);
                  final hiddenDetailCount =
                      record.details.length - visibleDetailItems.length;
                  final colorScheme = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;
                  final statusText = _buildRecordStatusText(record);
                  final statusColor = [5, 6].contains(record.status)
                      ? const Color(0xFF008000)
                      : [2, 3, 4].contains(record.status)
                      ? const Color(0xFFC22121)
                      : colorScheme.onSurfaceVariant;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openSellRecordDetail(record),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatTime(record.createTime),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!hasMultipleDetails)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (primary != null)
                                    _buildSellRecordDetailImage(
                                      detail: primary,
                                      schemas: salesController.schemas,
                                    )
                                  else
                                    Container(
                                      width: 72,
                                      height: 43,
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 18,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              if (wearValue != null &&
                                                  wearText != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${'app.market.csgo.abradability'.tr}: $wearText',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                WearProgressBar(
                                                  paintWear: wearValue,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (showCountdown) ...[
                                              _RecordProtectionCountdownText(
                                                endTimeSeconds:
                                                    record.protectionTime!,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors
                                                          .orange
                                                          .shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Obx(
                                              () => Text(
                                                currency.format(totalPrice),
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ...visibleDetailItems.map(
                                          (detail) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: _buildSellRecordDetailImage(
                                              detail: detail,
                                              schemas: salesController.schemas,
                                            ),
                                          ),
                                        ),
                                        if (hiddenDetailCount > 0)
                                          Text(
                                            '+$hiddenDetailCount',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showCountdown) ...[
                                        _RecordProtectionCountdownText(
                                          endTimeSeconds:
                                              record.protectionTime!,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.orange.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Obx(
                                        () => Text(
                                          currency.format(totalPrice),
                                          style: textTheme.titleSmall?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOnSaleActions() {
    final selectableIds = salesController.onSaleItems
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();
    final selectableTotal = selectableIds.length;
    final allSelected =
        selectableTotal > 0 && selectableIds.every(_selectedIds.contains);

    Future<void> openBatchPriceChange() async {
      final selectedItems = salesController.onSaleItems
          .where((item) => _selectedIds.contains(item.id ?? -1))
          .toList();
      if (selectedItems.isEmpty) {
        return;
      }
      final changed = await Get.toNamed(
        Routers.SHOP_PRICE_CHANGE,
        arguments: {
          'items': selectedItems,
          'schemas': salesController.schemas,
          'appId': GameStorage.getGameType(),
        },
      );
      if (changed == true) {
        await salesController.refreshOnSale();
      }
      if (!mounted) {
        return;
      }
      setState(_selectedIds.clear);
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxWidth < 520;
          final theme = Theme.of(context);
          final actionButtons = <Widget>[
            OutlinedButton(
              onPressed: () {
                setState(() => _selectedIds.clear());
              },
              child: Text(
                'app.common.cancel'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: _selectedIds.isEmpty ? null : openBatchPriceChange,
              child: Text(
                'app.inventory.price_change'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: _confirmDelist,
              child: Text(
                'app.inventory.delist'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: compactLayout
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _buildOnSaleSelectAllToggle(
                            selected: allSelected,
                            enabled: selectableTotal > 0,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedIds.length}/$selectableTotal',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: actionButtons,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildOnSaleSelectAllToggle(
                        selected: allSelected,
                        enabled: selectableTotal > 0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedIds.length}/$selectableTotal',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      ..._withSpacing(actionButtons),
                    ],
                  ),
          );
        },
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children, {double spacing = 8}) {
    return [
      for (int index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(width: spacing),
        children[index],
      ],
    ];
  }

  Future<void> _openDeliverSheet(ShopOrderItem order) async {
    final buyerId = (order.buyerId ?? '').trim();
    if (buyerId.isEmpty) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }

    await showNotifyTradeDeliverSheet(
      context,
      buyerId: buyerId,
      status: order.status,
      onDelivered: () {
        orderController.refreshPending();
        shippingNoticeController.refreshPendingTotals();
      },
    );
  }

  Future<void> _openSellRecordDetail(ShopOrderItem record) async {
    await Get.toNamed(
      Routers.SHOP_ORDER_DETAIL,
      arguments: {
        'order': record,
        'schemas': Map<String, ShopSchemaInfo>.from(salesController.schemas),
        'users': Map<String, ShopUserInfo>.from(salesController.users),
        'stickers': Map<String, dynamic>.from(salesController.stickers),
      },
    );
  }
}

Future<_ShopTabFilter?> _showShopTabSwitchMenu({
  required BuildContext iconContext,
  required _ShopTabFilter currentFilter,
  required int pendingTotal,
}) {
  final overlay =
      Overlay.of(iconContext).context.findRenderObject() as RenderBox;
  final box = iconContext.findRenderObject() as RenderBox;
  final iconRect = box.localToGlobal(Offset.zero) & box.size;
  final screenSize = overlay.size;
  final alignX = ((iconRect.center.dx / screenSize.width) * 2 - 1).clamp(
    -1.0,
    1.0,
  );
  final alignment = Alignment(alignX.toDouble(), -1);
  final panelTop = (iconRect.bottom + 8)
      .clamp(0.0, screenSize.height)
      .toDouble();

  return showGeneralDialog<_ShopTabFilter>(
    context: iconContext,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(
      iconContext,
    ).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, __, ___) {
      return _ShopTabSwitchOverlay(
        animation: animation,
        alignment: alignment,
        top: panelTop,
        currentFilter: currentFilter,
        pendingTotal: pendingTotal,
      );
    },
  );
}

class _ShopTabSwitchOverlay extends StatelessWidget {
  const _ShopTabSwitchOverlay({
    required this.animation,
    required this.alignment,
    required this.top,
    required this.currentFilter,
    required this.pendingTotal,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final _ShopTabFilter currentFilter;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                alignment: alignment,
                scale: Tween<double>(begin: 0.2, end: 1).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: _ShopTabSwitchPanel(
                    currentFilter: currentFilter,
                    pendingTotal: pendingTotal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTabSwitchPanel extends StatelessWidget {
  const _ShopTabSwitchPanel({
    required this.currentFilter,
    required this.pendingTotal,
  });

  final _ShopTabFilter currentFilter;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor;
    return Material(
      color: surface,
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.onSale,
            icon: Icons.storefront_outlined,
            labelKey: 'app.trade.onSale.text',
            selected: currentFilter == _ShopTabFilter.onSale,
          ),
          Divider(height: 1, color: divider),
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.pending,
            icon: Icons.local_shipping_outlined,
            labelKey: 'app.market.product.wait_for_sending',
            selected: currentFilter == _ShopTabFilter.pending,
            pendingTotal: pendingTotal,
          ),
          Divider(height: 1, color: divider),
          _ShopTabSwitchOption(
            filter: _ShopTabFilter.saleRecord,
            icon: Icons.receipt_long_outlined,
            labelKey: 'app.user.menu.sale',
            selected: currentFilter == _ShopTabFilter.saleRecord,
          ),
        ],
      ),
    );
  }
}

class _ShopTabSwitchOption extends StatelessWidget {
  const _ShopTabSwitchOption({
    required this.filter,
    required this.icon,
    required this.labelKey,
    required this.selected,
    this.pendingTotal = 0,
  });

  final _ShopTabFilter filter;
  final IconData icon;
  final String labelKey;
  final bool selected;
  final int pendingTotal;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFFFFB800);
    const pendingColor = Color(0xFFFF9800);
    final hasPendingHint = filter == _ShopTabFilter.pending && pendingTotal > 0;
    final dividerColor = Theme.of(context).dividerColor;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).pop(filter),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? selectedColor : null),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                labelKey.tr,
                style: TextStyle(
                  color: selected ? selectedColor : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (hasPendingHint)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: pendingColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: Text(
                        'app.system.tips.pending'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pendingColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pendingTotal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (selected)
              const Icon(Icons.check, color: selectedColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PendingShipmentCountdown extends StatefulWidget {
  const _PendingShipmentCountdown({required this.endTimeMs, this.style});

  final int endTimeMs;
  final TextStyle? style;

  @override
  State<_PendingShipmentCountdown> createState() =>
      _PendingShipmentCountdownState();
}

class _PendingShipmentCountdownState extends State<_PendingShipmentCountdown> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _PendingShipmentCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeMs != widget.endTimeMs) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final next = _format(widget.endTimeMs);
    if (!mounted) {
      return;
    }
    if (_text != next) {
      setState(() => _text = next);
    }
    if (next.isEmpty) {
      _timer?.cancel();
    }
  }

  String _format(int endTimeMs) {
    final remainMs = endTimeMs - DateTime.now().millisecondsSinceEpoch;
    if (remainMs <= 0) {
      return '';
    }
    final totalSeconds = remainMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(_text, style: widget.style);
  }
}

class _RecordProtectionCountdownText extends StatefulWidget {
  const _RecordProtectionCountdownText({
    required this.endTimeSeconds,
    this.style,
  });

  final int endTimeSeconds;
  final TextStyle? style;

  @override
  State<_RecordProtectionCountdownText> createState() =>
      _RecordProtectionCountdownTextState();
}

class _RecordProtectionCountdownTextState
    extends State<_RecordProtectionCountdownText> {
  Timer? _timer;
  String _remainText = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _RecordProtectionCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeSeconds != widget.endTimeSeconds) {
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final next = _formatRemainText(widget.endTimeSeconds);
    if (!mounted) {
      return;
    }
    if (_remainText != next) {
      setState(() => _remainText = next);
    }
    if (next.isEmpty) {
      _timer?.cancel();
    }
  }

  String _formatRemainText(int endTimeSeconds) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final totalTimeLeft = endTimeSeconds - nowSeconds;
    if (totalTimeLeft <= 0) {
      return '';
    }

    var days = totalTimeLeft ~/ (24 * 60 * 60);
    final hoursTotal = totalTimeLeft ~/ (60 * 60);
    final minutes = (totalTimeLeft % (60 * 60)) ~/ 60;
    final formattedMinutes = minutes.toString().padLeft(2, '0');
    var remainingHours = hoursTotal - days * 24 + (minutes > 0 ? 1 : 0);

    if (remainingHours % 24 == 0) {
      days += 1;
      remainingHours -= 24;
    }

    final localeTag = Get.locale?.toLanguageTag().toLowerCase() ?? '';
    final isCjkLocale =
        localeTag.startsWith('zh') ||
        localeTag.startsWith('ja') ||
        localeTag.startsWith('zh-hk');

    if (days > 0) {
      if (isCjkLocale) {
        return '$days${'app.common.day'.tr}$remainingHours${'app.common.hours'.tr}';
      }
      final dayKey = days > 1 ? 'app.common.days' : 'app.common.day';
      final hourKey = remainingHours > 1
          ? 'app.common.hours'
          : 'app.common.hour';
      return '$days${dayKey.tr}$remainingHours${hourKey.tr}';
    }

    if (remainingHours > 0) {
      if (isCjkLocale) {
        return '$remainingHours${'app.common.hours'.tr}$formattedMinutes${'app.common.minutes'.tr}';
      }
      final hourKey = remainingHours > 1
          ? 'app.common.hours'
          : 'app.common.hour';
      final minuteKey = minutes > 1
          ? 'app.common.minutes'
          : 'app.common.minute';
      return '$remainingHours${hourKey.tr}$formattedMinutes${minuteKey.tr}';
    }

    if (minutes > 0) {
      if (isCjkLocale) {
        return '$formattedMinutes${'app.common.minutes'.tr}';
      }
      final minuteKey = minutes > 1
          ? 'app.common.minutes'
          : 'app.common.minute';
      return '$formattedMinutes ${minuteKey.tr}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_remainText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(_remainText, style: widget.style);
  }
}
