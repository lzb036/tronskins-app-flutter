import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/help/feedback_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/pages/help/widgets/help_ui.dart';
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
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  void _createFeedback() {
    if (!userController.isLoggedIn.value) {
      return;
    }
    if (controller.hasUnfinishedFeedback) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.feedback.have_unfinished_feedback'.tr,

        titleText: const SizedBox.shrink(),
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
        backgroundColor: HelpUi.pageBackground(context),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: HelpUi.cardDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('app.system.message.nologin'.tr),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Get.toNamed(Routers.LOGIN),
              child: Text('app.user.login.nologin'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(BuildContext context) {
    return Obx(() {
      final loading = controller.listLoading.value;
      final list = controller.tickets;
      final total = controller.total.value == 0
          ? list.length
          : controller.total.value;
      final openCount = list.where((item) => item.status != 2).length;
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: HelpUi.cardDecoration(
              context,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                ],
              ),
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
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
                : RefreshIndicator(
                    onRefresh: () => controller.loadTickets(refresh: true),
                    child: list.isEmpty
                        ? ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              const SizedBox(height: 180),
                              Center(child: Text('app.common.no_data'.tr)),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: list.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= list.length) {
                                return _buildLoadMoreFooter(
                                  loading: loading,
                                  hasMore: controller.hasMore,
                                );
                              }
                              final item = list[index];
                              final status = item.status ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: HelpUi.cardDecoration(
                                  context,
                                  radius: 18,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => Get.toNamed(
                                      Routers.FEEDBACK_DETAIL,
                                      arguments: {
                                        'id': item.id,
                                        'status': item.status,
                                        'statusName': item.statusName,
                                      },
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              _StatusChip(
                                                status: status,
                                                label: item.statusName ?? '',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatTime(item.createTime),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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

  Widget _buildLoadMoreFooter({required bool loading, required bool hasMore}) {
    if (loading && hasMore) {
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

    if (!hasMore) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }

    return const SizedBox(height: 4);
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
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
  const _StatusChip({required this.status, required this.label});

  final int status;
  final String label;

  @override
  Widget build(BuildContext context) =>
      HelpUi.statusChip(context, status: status, label: label);
}
