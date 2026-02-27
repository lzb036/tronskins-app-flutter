import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/controllers/help/feedback_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({super.key});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  final FeedbackController controller = Get.isRegistered<FeedbackController>()
      ? Get.find<FeedbackController>()
      : Get.put(FeedbackController());
  final UserController userController = Get.find<UserController>();
  final ScrollController _scrollController = ScrollController();
  Worker? _loginWorker;

  @override
  void initState() {
    super.initState();
    if (userController.isLoggedIn.value) {
      controller.loadTickets(refresh: true);
    }
    _scrollController.addListener(_handleScroll);
    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        controller.loadTickets(refresh: true);
      } else {
        controller.tickets.clear();
        controller.total.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loginWorker?.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      controller.loadTickets();
    }
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  void _createFeedback() {
    if (!userController.isLoggedIn.value) {
      return;
    }
    if (controller.hasUnfinishedFeedback) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.feedback.have_unfinished_feedback'.tr,
      );
      return;
    }
    Get.toNamed(Routers.FEEDBACK_CREATE);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = userController.isLoggedIn.value;
      return Scaffold(
        appBar: AppBar(
          title: Text('app.user.menu.feedback'.tr),
          actions: loggedIn
              ? [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _createFeedback,
                  ),
                ]
              : const [],
        ),
        body: loggedIn ? _buildFeedbackList(context) : _buildLoginPrompt(),
      );
    });
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

  Widget _buildFeedbackList(BuildContext context) {
    return Obx(() {
      final loading = controller.listLoading.value;
      final list = controller.tickets;
      final total = controller.total.value == 0 ? list.length : controller.total.value;
      final openCount = list.where((item) => item.status != 2).length;
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'app.user.feedback.count'.tr,
                    value: total.toString(),
                    icon: Icons.forum_outlined,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _StatTile(
                    label: 'app.user.feedback.unresolved'.tr,
                    value: openCount.toString(),
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(child: Text('app.common.no_data'.tr))
                    : RefreshIndicator(
                        onRefresh: () => controller.loadTickets(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: list.length + (controller.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= list.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final item = list[index];
                            final status = item.status ?? 0;
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Get.toNamed(
                                  Routers.FEEDBACK_DETAIL,
                                  arguments: {
                                    'id': item.id,
                                    'status': item.status,
                                  },
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          _StatusChip(status: status, label: item.statusName ?? ''),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatTime(item.createTime),
                                            style:
                                                Theme.of(context).textTheme.bodySmall,
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Theme.of(context).dividerColor,
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
                      ),
          ),
        ],
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.label,
  });

  final int status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    switch (status) {
      case 0: // 待回复
        bgColor = Colors.orange.withOpacity(isDark ? 0.28 : 0.18);
        textColor = isDark ? Colors.orange.shade200 : Colors.orange.shade700;
        break;
      case 1: // 已回复
        bgColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case 2: // 已解决
        bgColor = Colors.green.withOpacity(isDark ? 0.28 : 0.18);
        textColor = isDark ? Colors.green.shade200 : Colors.green.shade700;
        break;
      case 3: // 已关闭
        bgColor = theme.colorScheme.outlineVariant.withOpacity(0.45);
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
      default:
        bgColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
