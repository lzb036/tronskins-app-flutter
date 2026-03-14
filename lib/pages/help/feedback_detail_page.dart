import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/feedback/feedback_models.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/help/feedback_controller.dart';
import 'package:tronskins_app/pages/help/widgets/help_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class FeedbackDetailPage extends StatefulWidget {
  const FeedbackDetailPage({super.key});

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  final FeedbackController controller = Get.isRegistered<FeedbackController>()
      ? Get.find<FeedbackController>()
      : Get.put(FeedbackController());
  final ScrollController _scrollController = ScrollController();

  String _ticketId = '';
  int? _status;
  String? _statusLabel;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _ticketId = args['id']?.toString() ?? '';
      _status = args['status'] is int
          ? args['status'] as int
          : int.tryParse(args['status']?.toString() ?? '');
      _statusLabel = args['statusName']?.toString();
    } else {
      _ticketId = args?.toString() ?? '';
    }
    if (_ticketId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.replies.clear();
        controller.detail.value = null;
        controller.loadDetail(_ticketId);
        controller.loadReplies(ticketId: _ticketId, refresh: true);
      });
    }
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
      controller.loadReplies(ticketId: _ticketId);
    }
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  String? _resolveStatusLabel(FeedbackDetail detail) {
    final detailLabel = detail.statusName?.trim();
    if (detailLabel != null && detailLabel.isNotEmpty) {
      return detailLabel;
    }
    final routeLabel = _statusLabel?.trim();
    if (routeLabel != null && routeLabel.isNotEmpty) {
      return routeLabel;
    }
    return null;
  }

  Future<void> _solveTicket() async {
    try {
      final res = await controller.solveFeedback(_ticketId);
      if (res.success) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.feedback.message.solve_success'.tr,

          titleText: const SizedBox.shrink(),
        );
        controller.loadTickets(refresh: true);
        _backToList();
        return;
      }
      final message = res.message.isNotEmpty
          ? res.message
          : 'app.system.message.not_open'.tr;
      Get.snackbar(
        'app.system.tips.title'.tr,
        message,
        titleText: const SizedBox.shrink(),
      );
    } catch (_) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.login.message.error'.tr,

        titleText: const SizedBox.shrink(),
      );
    }
  }

  void _backToList() {
    var found = false;
    Get.until((route) {
      if (route.settings.name == Routers.FEEDBACK_LIST) {
        found = true;
        return true;
      }
      return false;
    });
    if (!found) {
      Get.offNamed(Routers.FEEDBACK_LIST);
    }
  }

  Future<void> _confirmSolveTicket() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.user.feedback.message.solve_confirm'.tr),
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
    if (confirmed == true && mounted) {
      await _solveTicket();
    }
  }

  void _addReply() {
    Get.toNamed(
      Routers.FEEDBACK_CREATE,
      arguments: {'type': 'addFeedback', 'id': _ticketId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final closed = _status == 2 || _status == 3;
    return Scaffold(
      backgroundColor: HelpUi.pageBackground(context),
      appBar: AppBar(title: Text('app.user.feedback.details'.tr)),
      bottomNavigationBar: closed
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _confirmSolveTicket,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text('app.user.feedback.solved'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addReply,
                        icon: const Icon(Icons.add_comment_outlined),
                        label: Text('app.user.feedback.additional'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Obx(() {
        final loading = controller.replyLoading.value;
        final detailLoading = controller.detailLoading.value;
        final list = controller.replies;
        final detail = controller.detail.value;
        final showLoadingFooter = loading && list.isNotEmpty;
        final showNoMoreFooter =
            list.isNotEmpty && !loading && !controller.repliesHasMore;
        return RefreshIndicator(
          onRefresh: () =>
              controller.loadReplies(ticketId: _ticketId, refresh: true),
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (detail != null)
                _buildHeader(context, detail)
              else if (detailLoading)
                _buildHeaderLoading(context),
              if (detail != null || detailLoading) const SizedBox(height: 12),
              if (loading && list.isEmpty)
                _buildConversationLoading(context)
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('app.common.no_data'.tr)),
                )
              else
                ...list.map((item) => _buildReplyBubble(context, item)),
              _buildLoadMoreFooter(
                showLoading: showLoadingFooter,
                showNoMore: showNoMoreFooter,
              ),
            ],
          ),
        );
      }),
    );
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

  Widget _buildHeaderLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: HelpUi.cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLoadingLine(
            context,
            width: 180,
            height: theme.textTheme.titleMedium?.fontSize ?? 18,
          ),
          const SizedBox(height: 10),
          _buildLoadingLine(context, width: 140, height: 12),
          const SizedBox(height: 14),
          _buildLoadingLine(context, width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildLoadingLine(context, width: 220, height: 14),
        ],
      ),
    );
  }

  Widget _buildConversationLoading(BuildContext context) {
    return Column(
      children: const [
        _FeedbackLoadingBubble(isAdmin: false),
        _FeedbackLoadingBubble(isAdmin: true),
        _FeedbackLoadingBubble(isAdmin: false),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, FeedbackDetail detail) {
    final statusLabel = _resolveStatusLabel(detail);
    return Container(
      decoration: HelpUi.cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title ?? '',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(detail.createTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (statusLabel != null)
                _StatusChip(
                  status: detail.status ?? _status ?? -1,
                  label: statusLabel,
                ),
            ],
          ),
          if ((detail.context ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(detail.context ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBubble(BuildContext context, FeedbackReply item) {
    final isAdmin = item.isAdmin == true;
    final theme = Theme.of(context);
    final bubbleColor = isAdmin
        ? theme.colorScheme.surface
        : theme.colorScheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
          );
    final textColor = isAdmin
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    final align = isAdmin ? Alignment.centerLeft : Alignment.centerRight;
    final title = isAdmin
        ? 'app.user.feedback.customer_service_reply'.tr
        : 'app.user.feedback.text_before'.tr;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdmin
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.26)
                : theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(item.createTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.context ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            if (item.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.images.map<Widget>((url) {
                  return GestureDetector(
                    onTap: () => _previewImage(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => const SizedBox(
                          width: 86,
                          height: 86,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, _, __) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _previewImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, _) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, _, __) =>
                  const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingLine(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final color = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
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

class _FeedbackLoadingBubble extends StatelessWidget {
  const _FeedbackLoadingBubble({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = isAdmin ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isAdmin
        ? theme.colorScheme.surface
        : theme.colorScheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
          );
    final borderColor = isAdmin
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.26)
        : theme.colorScheme.primary.withValues(alpha: 0.22);
    final lineColor = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: isAdmin ? 0.9 : 0.78,
    );

    Widget loadingLine(double width, double height) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                loadingLine(96, 12),
                const SizedBox(width: 8),
                loadingLine(72, 10),
              ],
            ),
            const SizedBox(height: 10),
            loadingLine(double.infinity, 14),
            const SizedBox(height: 8),
            loadingLine(240, 14),
          ],
        ),
      ),
    );
  }
}
