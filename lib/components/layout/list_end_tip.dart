import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListEndTip extends StatelessWidget {
  const ListEndTip({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final rawLabel = 'app.common.no_more_data'.tr;
    final label = rawLabel == 'app.common.no_more_data'
        ? 'No more data'
        : rawLabel;
    final colors = Theme.of(context).colorScheme;
    final lineColor = colors.outlineVariant.withValues(alpha: 0.55);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant.withValues(alpha: 0.78),
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: lineColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label, style: textStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: lineColor,
            ),
          ),
        ],
      ),
    );
  }
}
