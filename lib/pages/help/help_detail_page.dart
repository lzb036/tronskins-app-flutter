import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/help/help_models.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/pages/help/widgets/help_ui.dart';

class HelpDetailPage extends StatelessWidget {
  const HelpDetailPage({super.key});

  String _formatTime(int? value) {
    if (value == null) return '--';
    final ts = value < 1000000000000 ? value * 1000 : value;
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    HelpItem? item;
    if (arg is HelpItem) {
      item = arg;
    } else if (arg is Map) {
      item = HelpItem.fromJson(Map<String, dynamic>.from(arg));
    }
    return Scaffold(
      backgroundColor: HelpUi.pageBackground(context),
      appBar: AppBar(title: Text('app.common.details'.tr)),
      body: BackToTopScope(
        enabled: false,
        child: item == null
            ? Center(child: Text('app.common.no_data'.tr))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Container(
                    decoration: HelpUi.cardDecoration(
                      context,
                      gradient: HelpUi.heroGradient(context),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title ?? '',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if ((item.author ?? '').isNotEmpty)
                              _MetaChip(
                                icon: Icons.person_outline,
                                label:
                                    '${'app.system.notice.author'.tr}: ${item.author ?? ''}',
                              ),
                            if (item.time != null)
                              _MetaChip(
                                icon: Icons.schedule,
                                label:
                                    '${'app.system.notice.publish_time'.tr}: ${_formatTime(item.time)}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: HelpUi.cardDecoration(context),
                    padding: const EdgeInsets.all(16),
                    child: Html(
                      data: item.content ?? '',
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: FontSize(15),
                          lineHeight: const LineHeight(1.6),
                        ),
                        'h1': Style(fontSize: FontSize(22)),
                        'h2': Style(fontSize: FontSize(20)),
                        'h3': Style(fontSize: FontSize(18)),
                        'p': Style(margin: Margins.only(bottom: 10)),
                        'a': Style(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HelpUi.softFill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
