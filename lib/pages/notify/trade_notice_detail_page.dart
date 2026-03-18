import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/notify/notify_models.dart';
import 'package:tronskins_app/components/notify/notify_trade_deliver_sheet.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/user/notify_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class TradeNoticeDetailPage extends StatefulWidget {
  const TradeNoticeDetailPage({super.key});

  @override
  State<TradeNoticeDetailPage> createState() => _TradeNoticeDetailPageState();
}

class _TradeNoticeDetailPageState extends State<TradeNoticeDetailPage> {
  final NotifyController _notifyController =
      Get.isRegistered<NotifyController>()
      ? Get.find<NotifyController>()
      : Get.put(NotifyController());

  TradeNotifyItem? _item;

  @override
  void initState() {
    super.initState();
    _resolveItem();
    _markRead();
  }

  void _resolveItem() {
    final arg = Get.arguments;
    if (arg is TradeNotifyItem) {
      _item = arg;
      return;
    }
    if (arg is Map<String, dynamic>) {
      _item = TradeNotifyItem.fromJson(arg);
      return;
    }
    if (arg is String) {
      for (final element in _notifyController.tradeList) {
        if (element.id == arg) {
          _item = element;
          break;
        }
      }
    }
  }

  Future<void> _markRead() async {
    final item = _item;
    if (item == null) return;
    await _notifyController.readTrade(item);
    if (mounted) {
      setState(() {});
    }
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  Future<void> _handleTradeAction(TradeNotifyItem item) async {
    final status = item.status;
    final buyerId = item.buyerId ?? '';
    if (buyerId.isNotEmpty && (status == 2 || status == 3)) {
      await showNotifyTradeDeliverSheet(
        context,
        buyerId: buyerId,
        status: status,
        onDelivered: () => _notifyController.loadTradeList(refresh: true),
      );
      return;
    }
    if (status == 4) {
      Get.toNamed(Routers.SHOP_PURCHASE, arguments: {'initialTab': 1});
      return;
    }
    final type = item.type ?? -1;
    if (type == 1) {
      _switchToTab(3);
      return;
    }
    if (type == 3) {
      Get.toNamed(Routers.SHOP_PURCHASE);
    }
  }

  void _switchToTab(int index) {
    final navCtrl = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    navCtrl.switchTo(index);
    if (Get.currentRoute != Routers.HOME) {
      Get.offAllNamed(Routers.HOME);
    }
  }

  String? _actionLabel(TradeNotifyItem item) {
    final status = item.status;
    final buyerId = item.buyerId ?? '';
    if (buyerId.isNotEmpty && (status == 2 || status == 3)) {
      return 'app.trade.deliver.go'.tr;
    }
    if (status == 4) {
      return 'app.user.menu.buy'.tr;
    }
    final type = item.type ?? -1;
    if (type == 1) {
      return 'app.tabbar.sell'.tr;
    }
    if (type == 3) {
      return 'app.user.menu.buy'.tr;
    }
    return null;
  }

  Widget _buildMessage(BuildContext context, TradeNotifyItem item) {
    final message = item.message ?? '';
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    if (message.isEmpty) {
      return Text(
        'app.common.no_data'.tr,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Html(
      data: message,
      style: {
        '*': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: textStyle?.color,
          fontSize: FontSize(textStyle?.fontSize ?? 14),
          fontWeight: textStyle?.fontWeight,
          lineHeight: LineHeight.number(1.4),
        ),
        'body': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      },
    );
  }

  Widget _buildHeader(BuildContext context, TradeNotifyItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.2 : 0.6);
    final gradient = LinearGradient(
      colors: [
        colorScheme.surface,
        colorScheme.primary.withOpacity(isDark ? 0.18 : 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app.system.notice.transaction'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTime(item.createTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ReadDot(read: item.read),
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

  Widget _buildContentCard(BuildContext context, TradeNotifyItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.subject_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'app.system.notice.transaction'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMessage(context, item),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final actionLabel = item == null ? null : _actionLabel(item);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('app.system.notice.transaction'.tr)),
      body: item == null
          ? Center(child: Text('app.common.no_data'.tr))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildHeader(context, item),
                const SizedBox(height: 16),
                _buildContentCard(context, item),
              ],
            ),
      bottomNavigationBar: actionLabel == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _handleTradeAction(item!),
                    child: Text(actionLabel),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ReadDot extends StatelessWidget {
  final bool read;

  const _ReadDot({required this.read});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: read ? Colors.transparent : Theme.of(context).colorScheme.error,
        shape: BoxShape.circle,
      ),
    );
  }
}
