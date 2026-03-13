import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/notify/notify_models.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/user/notify_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class NotifyTradeList extends StatefulWidget {
  final NotifyController controller;

  const NotifyTradeList({super.key, required this.controller});

  @override
  State<NotifyTradeList> createState() => _NotifyTradeListState();
}

class _NotifyTradeListState extends State<NotifyTradeList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      widget.controller.loadTradeList();
    }
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  Future<void> _handleRead(TradeNotifyItem item) async {
    final message = await widget.controller.readTrade(item);
    if (message == null || message.isEmpty) {
      return;
    }
    if (item.status == 2) {
      return;
    }
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      snackPosition: SnackPosition.TOP,

      titleText: const SizedBox.shrink(),
    );
  }

  Future<void> _openDetail(TradeNotifyItem item) async {
    await _handleRead(item);
    Get.toNamed(Routers.TRADE_NOTICE_DETAIL, arguments: item);
  }

  Future<void> _handleDelete(TradeNotifyItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) {
      return;
    }
    final list = widget.controller.tradeList;
    final index = list.indexWhere((element) => element.id == id);
    if (index < 0) {
      return;
    }
    final removed = list.removeAt(index);
    final total = widget.controller.tradeTotal.value;
    if (total > 0) {
      widget.controller.tradeTotal.value = total - 1;
    }
    try {
      final message = await widget.controller.deleteTrade(id);
      if (message == null) {
        final insertIndex = index.clamp(0, list.length);
        list.insert(insertIndex, removed);
        if (total > 0) {
          widget.controller.tradeTotal.value = total;
        }
        return;
      }
      Get.snackbar(
        'app.system.tips.title'.tr,
        message.isNotEmpty ? message : 'app.system.message.success'.tr,
        snackPosition: SnackPosition.TOP,

        titleText: const SizedBox.shrink(),
      );
    } catch (_) {
      final insertIndex = index.clamp(0, list.length);
      list.insert(insertIndex, removed);
      if (total > 0) {
        widget.controller.tradeTotal.value = total;
      }
    }
  }

  Widget _buildMessage(BuildContext context, TradeNotifyItem item) {
    final message = item.message ?? '';
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
    final textStyle = Theme.of(context).textTheme.bodyMedium;
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

  Widget _buildTradeCard(
    BuildContext context,
    TradeNotifyItem item,
    String time,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !item.read;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.2 : 0.6);
    final iconBg = isUnread
        ? colorScheme.primaryContainer
        : colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 0.8);
    final iconColor = isUnread
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final gradient = LinearGradient(
      colors: [
        colorScheme.surface,
        colorScheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.65),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          _ReadDot(read: item.read),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMessage(context, item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = widget.controller.tradeList;
      final loading = widget.controller.tradeLoading.value;
      if (list.isEmpty && loading) {
        return const Center(child: CircularProgressIndicator());
      }
      final showLoadingFooter = loading && list.isNotEmpty;
      final showNoMoreFooter =
          list.isNotEmpty && !loading && !widget.controller.tradeHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;
      return RefreshIndicator(
        onRefresh: () => widget.controller.loadTradeList(refresh: true),
        child: list.isEmpty
            ? ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text('app.common.no_data'.tr)),
                ],
              )
            : SlidableAutoCloseBehavior(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length + (showFooter ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= list.length) {
                      return _buildLoadMoreFooter(
                        showLoading: showLoadingFooter,
                        showNoMore: showNoMoreFooter,
                      );
                    }
                    final item = list[index];
                    final time = _formatTime(item.createTime);
                    final canDelete = item.id != null && item.id!.isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(
                          item.id ?? 'trade-$index-${item.createTime ?? ''}',
                        ),
                        enabled: canDelete,
                        endActionPane: canDelete
                            ? ActionPane(
                                motion: const StretchMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _handleDelete(item),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                    icon: Icons.delete_outline,
                                    label: 'app.common.delete'.tr,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) {
                                      Slidable.of(context)?.close();
                                    },
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    icon: Icons.close,
                                    label: 'app.common.cancel'.tr,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(16),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                        child: _buildTradeCard(context, item, time),
                      ),
                    );
                  },
                ),
              ),
      );
    });
  }

  Widget _buildLoadMoreFooter({
    required bool showLoading,
    required bool showNoMore,
  }) {
    if (showLoading) {
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
    if (showNoMore) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }
    return const SizedBox(height: 4);
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
