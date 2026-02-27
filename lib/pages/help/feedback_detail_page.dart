import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/feedback/feedback_models.dart';
import 'package:tronskins_app/controllers/help/feedback_controller.dart';
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

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _ticketId = args['id']?.toString() ?? '';
      _status = args['status'] is int
          ? args['status'] as int
          : int.tryParse(args['status']?.toString() ?? '');
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

  Future<void> _solveTicket() async {
    try {
      final res = await controller.solveFeedback(_ticketId);
      if (res.success) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.feedback.message.solve_success'.tr,
        );
        controller.loadTickets(refresh: true);
        _backToList();
        return;
      }
      final message = res.message.isNotEmpty
          ? res.message
          : 'app.system.message.not_open'.tr;
      Get.snackbar('app.system.tips.title'.tr, message);
    } catch (_) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.login.message.error'.tr,
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
                      color: Colors.black.withOpacity(0.06),
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
        final list = controller.replies;
        final detail = controller.detail.value;
        if (loading && list.isEmpty && detail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () =>
              controller.loadReplies(ticketId: _ticketId, refresh: true),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (detail != null) _buildHeader(context, detail),
              if (detail != null) const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('app.common.no_data'.tr)),
                )
              else
                ...list.map((item) => _buildReplyBubble(context, item)),
              if (controller.repliesHasMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, FeedbackDetail detail) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.title ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 6),
                Text(
                  _formatTime(detail.createTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                _StatusChip(
                  status: detail.status ?? -1,
                  label: detail.statusName ?? '',
                ),
              ],
            ),
            if ((detail.context ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(detail.context ?? ''),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBubble(BuildContext context, FeedbackReply item) {
    final isAdmin = item.isAdmin == true;
    final theme = Theme.of(context);
    final bubbleColor = isAdmin
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.primaryContainer;
    final textColor = isAdmin
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimaryContainer;
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
          borderRadius: BorderRadius.circular(14),
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
                    color: textColor.withOpacity(0.8),
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
      case 0:
        bgColor = Colors.orange.withOpacity(isDark ? 0.28 : 0.18);
        textColor = isDark ? Colors.orange.shade200 : Colors.orange.shade700;
        break;
      case 1:
        bgColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case 2:
        bgColor = Colors.green.withOpacity(isDark ? 0.28 : 0.18);
        textColor = isDark ? Colors.green.shade200 : Colors.green.shade700;
        break;
      case 3:
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
