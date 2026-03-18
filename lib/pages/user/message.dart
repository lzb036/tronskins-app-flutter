import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/components/notify/notify_bulletin_list.dart';
import 'package:tronskins_app/components/notify/notify_trade_list.dart';
import 'package:tronskins_app/controllers/user/notify_controller.dart';

class UserMessage extends StatefulWidget {
  const UserMessage({super.key});

  @override
  State<UserMessage> createState() => _UserMessageState();
}

class _UserMessageState extends State<UserMessage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotifyController _controller = Get.isRegistered<NotifyController>()
      ? Get.find<NotifyController>()
      : Get.put(NotifyController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _controller.loadTradeList(refresh: true);
    _controller.loadNoticeList(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _readAll() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('${'app.system.notice.readall'.tr}?'),
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
    if (confirm != true) {
      return;
    }
    final ok = _tabController.index == 0
        ? await _controller.readAllTrade()
        : await _controller.readAllNotice();
    if (ok) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.system.notice.readall'.tr,
        titleText: const SizedBox.shrink(),
      );
    }
  }

  Future<void> _clearTrade() async {
    if (_tabController.index != 0) return;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.system.notice.clear_tips'.tr),
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
    if (confirm == true) {
      final message = await _controller.clearTrade();
      if (message != null) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          message.isNotEmpty ? message : 'app.system.message.success'.tr,

          titleText: const SizedBox.shrink(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'app.system.notice.title'.tr;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceVariant.withOpacity(0.35)
                    : colorScheme.surfaceVariant.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.6),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(
                  isDark ? 0.7 : 0.8,
                ),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'app.system.notice.transaction'.tr),
                  Tab(text: 'app.system.notice.announcement'.tr),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _readAll,
            tooltip: 'app.system.notice.readall'.tr,
          ),
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearTrade,
              tooltip: 'app.system.notice.clear_tips'.tr,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotifyTradeList(controller: _controller),
          NotifyBulletinList(controller: _controller),
        ],
      ),
    );
  }
}
