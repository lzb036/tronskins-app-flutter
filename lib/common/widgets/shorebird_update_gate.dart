import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:tronskins_app/common/theme/app_colors.dart';
import 'package:tronskins_app/common/theme/app_text_theme.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';

/// Wraps the app and manages Shorebird hot-update checks plus update UI.
class ShorebirdUpdateGate extends StatefulWidget {
  const ShorebirdUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ShorebirdUpdateGate> createState() => _ShorebirdUpdateGateState();
}

enum _UpdateOverlayPhase { hidden, downloading, restartReady }

class _ShorebirdUpdateGateState extends State<ShorebirdUpdateGate>
    with WidgetsBindingObserver {
  // Android cold start often triggers an extra resumed callback right away.
  static const Duration _resumeCheckThrottle = Duration(seconds: 3);
  static const Duration _restartDelay = Duration(milliseconds: 1200);

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  _UpdateOverlayPhase _phase = _UpdateOverlayPhase.hidden;
  bool _isChecking = false;
  bool _hasPendingPatchForColdStart = false;
  DateTime? _lastCheckAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdates(force: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdates());
    }
  }

  Future<void> _checkForUpdates({bool force = false}) async {
    if (!_shouldCheckForUpdates(force: force)) {
      return;
    }

    _isChecking = true;
    _lastCheckAt = DateTime.now();

    try {
      final status = await _updater.checkForUpdate();
      if (!mounted) {
        return;
      }

      switch (status) {
        case UpdateStatus.outdated:
          await _downloadAndApplyUpdate();
          break;
        case UpdateStatus.restartRequired:
          await _showRestartReadyNotice();
          break;
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          _hideOverlay();
          break;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to check for a Shorebird update.',
        name: 'shorebird.update',
        error: error,
        stackTrace: stackTrace,
      );
      _hideOverlay();
    } finally {
      _isChecking = false;
    }
  }

  bool _shouldCheckForUpdates({required bool force}) {
    if (!mounted || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (!_updater.isAvailable || _isChecking) {
      return false;
    }
    if (_hasPendingPatchForColdStart) {
      return false;
    }
    if (_phase != _UpdateOverlayPhase.hidden) {
      return false;
    }
    if (force) {
      return true;
    }

    final lastCheckAt = _lastCheckAt;
    return lastCheckAt == null ||
        DateTime.now().difference(lastCheckAt) >= _resumeCheckThrottle;
  }

  Future<void> _downloadAndApplyUpdate() async {
    _setPhase(_UpdateOverlayPhase.downloading);

    try {
      await _updater.update();
      if (!mounted) {
        return;
      }
      await _showRestartReadyNotice();
    } on UpdateException catch (error, stackTrace) {
      developer.log(
        'Failed to download or install a Shorebird update.',
        name: 'shorebird.update',
        error: error,
        stackTrace: stackTrace,
      );
      _hideOverlay();
      final copy = _copyForLocale();
      AppSnackbar.error(copy.downloadFailedMessage, title: copy.failureTitle);
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected failure while applying a Shorebird update.',
        name: 'shorebird.update',
        error: error,
        stackTrace: stackTrace,
      );
      _hideOverlay();
      final copy = _copyForLocale();
      AppSnackbar.error(copy.downloadFailedMessage, title: copy.failureTitle);
    }
  }

  Future<void> _showRestartReadyNotice() async {
    _hasPendingPatchForColdStart = true;
    _setPhase(_UpdateOverlayPhase.restartReady);
    await Future<void>.delayed(_restartDelay);
    if (!mounted) {
      return;
    }

    developer.log(
      'A Shorebird patch is ready and requires a cold start. '
      'Skipping in-app restart to avoid a restart loop.',
      name: 'shorebird.update',
    );

    final copy = _copyForLocale();
    _hideOverlay();
    AppSnackbar.info(copy.manualRestartMessage, title: copy.restartTitle);
  }

  void _setPhase(_UpdateOverlayPhase phase) {
    if (!mounted || _phase == phase) {
      return;
    }
    setState(() {
      _phase = phase;
    });
  }

  void _hideOverlay() {
    if (!mounted || _phase == _UpdateOverlayPhase.hidden) {
      return;
    }
    setState(() {
      _phase = _UpdateOverlayPhase.hidden;
    });
  }

  _UpdateCopy _copyForLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isChinese = locale.languageCode.toLowerCase().startsWith('zh');
    return isChinese ? _UpdateCopy.zh() : _UpdateCopy.en();
  }

  @override
  Widget build(BuildContext context) {
    final overlayVisible = _phase != _UpdateOverlayPhase.hidden;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !overlayVisible,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: overlayVisible
                ? _ShorebirdUpdateOverlay(
                    key: ValueKey(_phase),
                    phase: _phase,
                    copy: _copyForLocale(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _ShorebirdUpdateOverlay extends StatelessWidget {
  const _ShorebirdUpdateOverlay({
    super.key,
    required this.phase,
    required this.copy,
  });

  final _UpdateOverlayPhase phase;
  final _UpdateCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors =
        theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
    final textTheme =
        theme.extension<AppTextTheme>() ??
        (theme.brightness == Brightness.dark
            ? AppTextTheme.dark()
            : AppTextTheme.light());
    final isRestarting = phase == _UpdateOverlayPhase.restartReady;
    final accent = isRestarting ? appColors.success : appColors.primary;
    final title = isRestarting ? copy.restartTitle : copy.downloadingTitle;
    final message = isRestarting
        ? copy.restartMessage
        : copy.downloadingMessage;
    final badge = isRestarting ? copy.restartBadge : copy.downloadingBadge;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      appColors.surface.withValues(alpha: 0.94),
                      appColors.surfaceVariant.withValues(alpha: 0.9),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.38),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 36,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16),
                      blurRadius: 46,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PatchSpinner(accent: accent, isRestarting: isRestarting),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            badge,
                            style: textTheme.labelSmall.copyWith(
                              color: accent,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge.copyWith(
                          color: appColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium.copyWith(
                          color: appColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: accent.withValues(alpha: 0.14),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        copy.footer,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall.copyWith(
                          color: appColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatchSpinner extends StatefulWidget {
  const _PatchSpinner({required this.accent, required this.isRestarting});

  final Color accent;
  final bool isRestarting;

  @override
  State<_PatchSpinner> createState() => _PatchSpinnerState();
}

class _PatchSpinnerState extends State<_PatchSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, _) {
        final glowScale = 0.92 + (_pulseController.value * 0.14);
        final glowOpacity = 0.16 + (_pulseController.value * 0.16);

        return SizedBox(
          width: 142,
          height: 142,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(alpha: glowOpacity),
                        widget.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 116,
                height: 116,
                child: CircularProgressIndicator(
                  strokeWidth: 5.2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
                  backgroundColor: widget.accent.withValues(alpha: 0.12),
                ),
              ),
              RotationTransition(
                turns: Tween<double>(
                  begin: 1,
                  end: 0,
                ).animate(_rotationController),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.26),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.accent.withValues(alpha: 0.9),
                      ),
                      backgroundColor: widget.accent.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent.withValues(alpha: 0.14),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  widget.isRestarting
                      ? Icons.rocket_launch_rounded
                      : Icons.system_update_alt_rounded,
                  color: widget.accent,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpdateCopy {
  const _UpdateCopy({
    required this.downloadingBadge,
    required this.restartBadge,
    required this.downloadingTitle,
    required this.restartTitle,
    required this.downloadingMessage,
    required this.restartMessage,
    required this.footer,
    required this.failureTitle,
    required this.downloadFailedMessage,
    required this.manualRestartMessage,
    required this.restartNotificationTitle,
    required this.restartNotificationBody,
  });

  factory _UpdateCopy.zh() {
    return const _UpdateCopy(
      downloadingBadge: 'HOT UPDATE',
      restartBadge: 'READY',
      downloadingTitle: '检测到热更新，正在加载最新内容',
      restartTitle: '热更新已完成，请重新打开应用',
      downloadingMessage: '请稍候，补丁正在下载并安装。更新期间请不要关闭应用。',
      restartMessage: '补丁已经准备就绪，请完全关闭应用后重新打开，以切换到最新版本。',
      footer: '补丁就绪后，本次运行不会再次重复触发热更新检查。',
      failureTitle: '热更新失败',
      downloadFailedMessage: '补丁下载失败，本次将继续使用当前版本。',
      manualRestartMessage: '补丁已下载完成，请完全关闭应用后重新打开以使用最新版本。',
      restartNotificationTitle: 'Tronskins 更新已就绪',
      restartNotificationBody: '请完全关闭应用后重新打开，以加载最新版本。',
    );
  }

  factory _UpdateCopy.en() {
    return const _UpdateCopy(
      downloadingBadge: 'HOT UPDATE',
      restartBadge: 'READY',
      downloadingTitle: 'Hot update found. Loading the latest patch',
      restartTitle: 'Hot update is ready. Reopen the app',
      downloadingMessage:
          'Please wait while the patch is downloaded and installed.',
      restartMessage:
          'The patch is ready. Fully close and reopen the app to load the latest version.',
      footer:
          'Once the patch is ready, this app session will stop re-checking for updates.',
      failureTitle: 'Hot Update Failed',
      downloadFailedMessage:
          'The patch could not be downloaded. The current version will stay active.',
      manualRestartMessage:
          'The patch is ready. Fully close and reopen the app to use the latest version.',
      restartNotificationTitle: 'Tronskins update is ready',
      restartNotificationBody:
          'Fully close and reopen the app to load the latest version.',
    );
  }

  final String downloadingBadge;
  final String restartBadge;
  final String downloadingTitle;
  final String restartTitle;
  final String downloadingMessage;
  final String restartMessage;
  final String footer;
  final String failureTitle;
  final String downloadFailedMessage;
  final String manualRestartMessage;
  final String restartNotificationTitle;
  final String restartNotificationBody;
}
