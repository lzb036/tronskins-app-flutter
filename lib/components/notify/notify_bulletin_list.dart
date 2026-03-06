import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/notify/notify_models.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/user/notify_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class NotifyBulletinList extends StatefulWidget {
  final NotifyController controller;

  const NotifyBulletinList({super.key, required this.controller});

  @override
  State<NotifyBulletinList> createState() => _NotifyBulletinListState();
}

class _NotifyBulletinListState extends State<NotifyBulletinList> {
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
      widget.controller.loadNoticeList();
    }
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  Widget _buildNoticeCard(
    BuildContext context,
    NoticeMessageItem item,
    String time,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !item.isRead;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.2 : 0.6);
    final iconBg = isUnread
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 0.8);
    final iconColor = isUnread
        ? colorScheme.onTertiaryContainer
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
          onTap: () async {
            await widget.controller.readNotice(item);
            final id = item.id;
            if (id != null) {
              Get.toNamed(Routers.NOTICE_DETAIL, arguments: id);
            }
          },
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
                    Icons.campaign_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          _ReadDot(read: item.isRead),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ],
                      ),
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
      final list = widget.controller.noticeList;
      final loading = widget.controller.noticeLoading.value;
      if (list.isEmpty && loading) {
        return const Center(child: CircularProgressIndicator());
      }
      final showLoadingFooter = loading && list.isNotEmpty;
      final showNoMoreFooter =
          list.isNotEmpty && !loading && !widget.controller.noticeHasMore;
      final showFooter = showLoadingFooter || showNoMoreFooter;
      return RefreshIndicator(
        onRefresh: () => widget.controller.loadNoticeList(refresh: true),
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
            : ListView.builder(
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNoticeCard(context, item, time),
                  );
                },
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
