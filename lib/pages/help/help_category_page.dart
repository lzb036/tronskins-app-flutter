import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/help/help_models.dart';
import 'package:tronskins_app/controllers/help/help_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class HelpCategoryPage extends StatefulWidget {
  const HelpCategoryPage({super.key});

  @override
  State<HelpCategoryPage> createState() => _HelpCategoryPageState();
}

class _HelpCategoryPageState extends State<HelpCategoryPage> {
  final HelpController controller = Get.isRegistered<HelpController>()
      ? Get.find<HelpController>()
      : Get.put(HelpController());

  HelpCategory? _category;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is HelpCategory) {
      _category = arg;
    } else if (arg is Map) {
      _category = HelpCategory.fromJson(Map<String, dynamic>.from(arg));
    }
    final code = _category?.categoryCode ?? '';
    if (code.isNotEmpty) {
      controller.loadHelpList(code);
    } else {
      controller.helpItems.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _category?.label ?? 'app.user.server.help'.tr;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        final loading = controller.listLoading.value;
        final list = controller.helpItems;
        if (loading && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return Center(child: Text('app.common.no_data'.tr));
        }
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'app.inventory.count'.tr}: ${list.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(item.title ?? ''),
                      subtitle: Text(_formatTime(item.time)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Get.toNamed(Routers.HELP_DETAIL, arguments: item),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }
}
