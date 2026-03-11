import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/help/help_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final HelpController controller = Get.isRegistered<HelpController>()
      ? Get.find<HelpController>()
      : Get.put(HelpController());
  final List<IconData> _icons = const [
    Icons.receipt_long_outlined,
    Icons.verified_user_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.shopping_bag_outlined,
    Icons.local_shipping_outlined,
    Icons.swap_horiz_outlined,
    Icons.lock_outline,
    Icons.help_outline,
  ];

  @override
  void initState() {
    super.initState();
    controller.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        body: Obx(() {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final loading = controller.categoryLoading.value;
          final list = controller.categories;
          final gradient = LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(isDark ? 0.7 : 0.85),
              theme.colorScheme.secondary.withOpacity(isDark ? 0.45 : 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          if (loading && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                title: Text('app.user.server.help'.tr),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: BoxDecoration(gradient: gradient)),
                      Positioned(
                        right: -40,
                        top: 30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              isDark ? 0.08 : 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -50,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              isDark ? 0.06 : 0.14,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildFeedbackEntry(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final title = item.label ?? item.categoryCode ?? '';
                    return _buildCategoryCard(
                      context,
                      title: title,
                      icon: _icons[index % _icons.length],
                      onTap: () =>
                          Get.toNamed(Routers.HELP_CATEGORY, arguments: item),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFeedbackEntry(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(isDark ? 0.65 : 0.9),
        theme.colorScheme.secondary.withOpacity(isDark ? 0.5 : 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.toNamed(Routers.FEEDBACK_LIST),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'app.user.menu.feedback'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'app.user.feedback.problem'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
