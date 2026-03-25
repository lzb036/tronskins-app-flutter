import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/tradeoffer.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

Future<void> showNotifyTradeDeliverSheet(
  BuildContext context, {
  required String buyerId,
  int? status,
  VoidCallback? onDelivered,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return NotifyTradeDeliverSheet(
        buyerId: buyerId,
        status: status,
        onDelivered: onDelivered,
      );
    },
  );
}

class NotifyTradeDeliverSheet extends StatefulWidget {
  final String buyerId;
  final int? status;
  final VoidCallback? onDelivered;

  const NotifyTradeDeliverSheet({
    super.key,
    required this.buyerId,
    this.status,
    this.onDelivered,
  });

  @override
  State<NotifyTradeDeliverSheet> createState() =>
      _NotifyTradeDeliverSheetState();
}

class _NotifyTradeDeliverSheetState extends State<NotifyTradeDeliverSheet> {
  final ApiShopProductServer _api = ApiShopProductServer();
  final ApiSteamServer _steamApi = ApiSteamServer();
  final ApiTradeOfferServer _tradeApi = ApiTradeOfferServer();

  final Map<String, ShopSchemaInfo> _schemas = {};
  final Map<String, ShopUserInfo> _users = {};
  List<ShopOrderItem> _orders = [];

  bool _loading = true;
  bool _submitting = false;
  bool _refreshingBuyer = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (widget.buyerId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'appId': GameStorage.getGameType(),
        'buyer': widget.buyerId,
        'page': 1,
        'pageSize': 50,
        'statusList': widget.status != null ? [widget.status] : [2, 3],
        'isload': true,
      };
      final res = await _api.pendingShipmentList(params: params);
      if (res.success && res.datas != null) {
        final data = res.datas!;
        _orders = data.items;
        _schemas
          ..clear()
          ..addAll(data.schemas);
        _users
          ..clear()
          ..addAll(data.users);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshBuyer() async {
    if (_refreshingBuyer || widget.buyerId.isEmpty) return;
    setState(() => _refreshingBuyer = true);
    try {
      final res = await _steamApi.getSteamUserInfo(id: widget.buyerId);
      if (res.success && res.datas != null) {
        final data = res.datas!;
        final current = _users[widget.buyerId];
        _users[widget.buyerId] = ShopUserInfo(
          id: current?.id ?? widget.buyerId,
          uuid: current?.uuid,
          avatar: data['avatar']?.toString() ?? current?.avatar,
          nickname: data['nickname']?.toString() ?? current?.nickname,
          level: _asInt(data['level']) ?? current?.level,
          yearsLevel: _asInt(data['yearsLevel']) ?? current?.yearsLevel,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingBuyer = false);
      }
    }
  }

  ShopUserInfo? _buyerInfo() {
    final direct = _users[widget.buyerId];
    if (direct != null) return direct;
    for (final order in _orders) {
      if (order.buyerId == widget.buyerId && order.user != null) {
        return order.user;
      }
    }
    return null;
  }

  int _totalItems() {
    var total = 0;
    for (final order in _orders) {
      total += order.details.length;
    }
    return total;
  }

  ShopSchemaInfo? _lookupSchema(ShopOrderDetail detail) {
    final hash = detail.marketHashName;
    if (hash != null && _schemas.containsKey(hash)) {
      return _schemas[hash];
    }
    final schemaId = detail.schemaId?.toString();
    if (schemaId != null && _schemas.containsKey(schemaId)) {
      return _schemas[schemaId];
    }
    return null;
  }

  String? _paintWearText(ShopOrderDetail detail) {
    final value = detail.raw['paint_wear'] ?? detail.raw['paintWear'];
    if (value != null) {
      return value.toString();
    }
    return detail.paintWear?.toString();
  }

  double? _paintWearValue(ShopOrderDetail detail) {
    final value = detail.raw['paint_wear'] ?? detail.raw['paintWear'];
    if (value is num) {
      return value.toDouble();
    }
    if (value != null) {
      return double.tryParse(value.toString());
    }
    return detail.paintWear;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MM-dd HH:mm').format(date);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_orders.isEmpty || _orders.first.id == null) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
      return;
    }
    setState(() => _submitting = true);
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

      final res = await _tradeApi.createTradeOffer(
        params: {'id': _orders.first.id},
      );
      if (res.success) {
        AppSnackbar.success(
          'app.trade.deliver.message.steam_trade_url_success'.tr,
        );
        widget.onDelivered?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final datas = res.datas?.toString() ?? '';
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
        final nickname = Get.find<UserController>().nickname;
        await Get.dialog<void>(
          AlertDialog(
            title: Text('app.system.tips.title'.tr),
            content: Text('app.inventory.message.privacy'.tr + nickname),
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
      AppSnackbar.error(
        res.message.isNotEmpty ? res.message : 'app.trade.filter.failed'.tr,
      );
    } catch (_) {
      AppSnackbar.error('app.trade.filter.failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerInfo = _buyerInfo();
    final status =
        widget.status ?? (_orders.isNotEmpty ? _orders.first.status : null);
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    final currency = Get.find<CurrencyController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'app.trade.order.details'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (buyerInfo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'app.trade.order.seller_tips_3'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/login/steam-icon.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_esports,
                              size: 20,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if ((buyerInfo.nickname ?? '').isNotEmpty)
                            Text(buyerInfo.nickname ?? ''),
                          const SizedBox(width: 8),
                          if (buyerInfo.level != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                '${buyerInfo.level}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (buyerInfo.yearsLevel != null)
                            Image.network(
                              'https://community.cloudflare.steamstatic.com/public/images/badges/02_years/steamyears${buyerInfo.yearsLevel}_80.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed: _refreshingBuyer ? null : _refreshBuyer,
                            icon: _refreshingBuyer
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${'app.trade.deliver.num'.tr} (${_totalItems()})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                    ? Center(child: Text('app.common.no_data'.tr))
                    : ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${'app.trade.order.number'.tr}: ${order.id ?? '--'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        _formatTime(order.createTime),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...order.details.map((detail) {
                                    final schema = _lookupSchema(detail);
                                    final imageUrl =
                                        detail.imageUrl ??
                                        schema?.imageUrl ??
                                        '';
                                    final title =
                                        detail.marketName ??
                                        schema?.marketName ??
                                        '-';
                                    final count = detail.count ?? 1;
                                    final price = detail.price ?? 0;
                                    final wearText = _paintWearText(detail);
                                    final wearValue = _paintWearValue(detail);
                                    return Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.fromLTRB(
                                        6,
                                        6,
                                        6,
                                        8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: colorScheme.outlineVariant
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  width: 66,
                                                  height: 48,
                                                  fit: BoxFit.contain,
                                                  placeholder: (context, _) =>
                                                      const SizedBox(
                                                        width: 66,
                                                        height: 48,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        _,
                                                        __,
                                                      ) => const Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                      ),
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
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${'app.inventory.count'.tr}: $count',
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
                                              Text(
                                                currency.format(price),
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (wearText != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              '${'app.market.csgo.abradability'.tr}: $wearText',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                          if (wearValue != null) ...[
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: double.infinity,
                                              child: WearProgressBar(
                                                paintWear: wearValue,
                                                height: 16,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: status == 2 && !_submitting
                      ? _submit
                      : status == 3
                      ? () => Navigator.of(context).pop()
                      : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          status == 2
                              ? 'app.market.product.deliver'.tr
                              : 'app.trade.deliver.message.go_steam'.tr,
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
