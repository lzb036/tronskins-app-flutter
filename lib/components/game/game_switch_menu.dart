import 'package:flutter/material.dart';

Future<int?> showGameSwitchMenu({
  required BuildContext iconContext,
  required int currentAppId,
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
  });

  final Animation<double> animation;
  final Alignment alignment;
  final double top;
  final int currentAppId;

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
                  child: _GameSwitchPanel(currentAppId: currentAppId),
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
  const _GameSwitchPanel({required this.currentAppId});

  final int currentAppId;

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
          _GameOption(appId: 730, name: 'CS2', selected: currentAppId == 730),
          Divider(height: 1, color: divider),
          _GameOption(appId: 440, name: 'TF2', selected: currentAppId == 440),
          Divider(height: 1, color: divider),
          _GameOption(appId: 570, name: 'DOTA2', selected: currentAppId == 570),
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
  });

  final int appId;
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
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
            if (selected)
              const Icon(Icons.check, color: Color(0xFFFFB800), size: 18),
          ],
        ),
      ),
    );
  }
}
