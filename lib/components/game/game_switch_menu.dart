import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<int?> showGameSwitchMenu({
  required BuildContext iconContext,
  required int currentAppId,
  Map<int, int>? pendingTotalsByAppId,
}) {
  final overlay = Overlay.of(iconContext).context.findRenderObject() as RenderBox;
  final box = iconContext.findRenderObject() as RenderBox;
  final iconRect = box.localToGlobal(Offset.zero) & box.size;
  final screenSize = overlay.size;
  final alignX =
      ((iconRect.center.dx / screenSize.width) * 2 - 1).clamp(-1.0, 1.0);
  final alignment = Alignment(alignX.toDouble(), -1);
  final panelTop =
      (iconRect.bottom + 8).clamp(0.0, screenSize.height).toDouble();

  return showGeneralDialog<int>(
    context: iconContext,
    barrierDismissible: true,
    barrierLabel:
        MaterialLocalizations.of(iconContext).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, __, ___) {
      return _GameSwitchOverlay(
        animation: animation,
        alignment: alignment,
        top: panelTop,
        currentAppId: currentAppId,
        pendingTotalsByAppId: pendingTotalsByAppId,
      );
    },
  );
}

class _GameSwitchOverlay extends StatelessWidget {
  const _GameSwitchOverlay({
    required this.animation,
    required this.alignment,
    required this.top,
    required this.currentAppId,
    required this.pendingTotalsByAppId,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final int currentAppId;
  final Map<int, int>? pendingTotalsByAppId;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                alignment: alignment,
                scale: Tween<double>(begin: 0.2, end: 1).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: _GameSwitchPanel(
                    currentAppId: currentAppId,
                    pendingTotalsByAppId: pendingTotalsByAppId,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameSwitchPanel extends StatelessWidget {
  const _GameSwitchPanel({
    required this.currentAppId,
    required this.pendingTotalsByAppId,
  });

  final int currentAppId;
  final Map<int, int>? pendingTotalsByAppId;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor;
    return Material(
      color: surface,
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GameOption(
            appId: 730,
            name: 'CS2',
            selected: currentAppId == 730,
            pendingTotal: pendingTotalsByAppId?[730] ?? 0,
            dividerColor: divider,
          ),
          Divider(height: 1, color: divider),
          _GameOption(
            appId: 440,
            name: 'TF2',
            selected: currentAppId == 440,
            pendingTotal: pendingTotalsByAppId?[440] ?? 0,
            dividerColor: divider,
          ),
          Divider(height: 1, color: divider),
          _GameOption(
            appId: 570,
            name: 'DOTA2',
            selected: currentAppId == 570,
            pendingTotal: pendingTotalsByAppId?[570] ?? 0,
            dividerColor: divider,
          ),
        ],
      ),
    );
  }
}

class _GameOption extends StatelessWidget {
  const _GameOption({
    required this.appId,
    required this.name,
    required this.selected,
    required this.pendingTotal,
    required this.dividerColor,
  });

  final int appId;
  final String name;
  final bool selected;
  final int pendingTotal;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingTotal > 0;
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).pop(appId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              'assets/images/game/icon/$appId.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: selected ? const Color(0xFFFFB800) : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            if (hasPending)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 88),
                      child: Text(
                        'app.system.tips.pending'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pendingTotal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (selected)
              const Icon(Icons.check, color: Color(0xFFFFB800), size: 18),
          ],
        ),
      ),
    );
  }
}
