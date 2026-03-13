import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/wallet/integral_controller.dart';

class IntegralDrawPage extends StatefulWidget {
  const IntegralDrawPage({super.key});

  @override
  State<IntegralDrawPage> createState() => _IntegralDrawPageState();
}

class _IntegralDrawPageState extends State<IntegralDrawPage> {
  final IntegralController controller = Get.isRegistered<IntegralController>()
      ? Get.find<IntegralController>()
      : Get.put(IntegralController());

  final List<int> _gridOrder = const [0, 1, 2, 7, -1, 3, 6, 5, 4];
  bool _isUnavailableDialogVisible = false;

  @override
  void initState() {
    super.initState();
    controller.refreshUser();
    controller.loadLotteryPrizes();
  }

  List<WalletLotteryPrize> _buildPrizes() {
    final prizes = List<WalletLotteryPrize>.from(controller.lotteryPrizes);
    prizes.sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));
    if (prizes.length >= 8) {
      return prizes.take(8).toList();
    }
    while (prizes.length < 8) {
      prizes.add(WalletLotteryPrize(raw: const {}));
    }
    return prizes;
  }

  Future<void> _showUnavailableDialog() async {
    if (_isUnavailableDialogVisible) {
      return;
    }
    _isUnavailableDialogVisible = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'integral_draw_unavailable',
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const _IntegralDrawUnavailableDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (mounted) {
      setState(() {
        _isUnavailableDialogVisible = false;
      });
      return;
    }
    _isUnavailableDialogVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        appBar: AppBar(title: Text('app.user.integral.draw_weekly'.tr)),
        body: Obx(() {
          final prizes = _buildPrizes();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${'app.user.integral.unit'.tr}: ${controller.integralValue}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'app.user.integral.draw'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildGrid(prizes),
              const SizedBox(height: 16),
              _buildRules(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGrid(List<WalletLotteryPrize> prizes) {
    final cells = <Widget>[];
    for (final index in _gridOrder) {
      if (index == -1) {
        cells.add(_buildDrawButton());
      } else {
        final prize = prizes[index];
        cells.add(_buildPrizeCell(prize));
      }
    }
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  Widget _buildDrawButton() {
    return GestureDetector(
      onTap: _showUnavailableDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'app.user.integral.draw'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCell(WalletLotteryPrize prize) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          prize.label ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildRules() {
    final rules = [
      'app.user.integral.intro'.tr,
      'app.user.integral.earn'.tr,
      'app.user.integral.earn_tips'.tr,
      'app.user.integral.use'.tr,
      'app.user.integral.use_tips_1'.tr,
      'app.user.integral.use_tips_2'.tr,
      'app.user.integral.deduct'.tr,
      'app.user.integral.deduct_tips'.tr,
      'app.user.integral.validity'.tr,
      'app.user.integral.validity_tips'.tr,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final text in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(text),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntegralDrawUnavailableDialog extends StatefulWidget {
  const _IntegralDrawUnavailableDialog();

  @override
  State<_IntegralDrawUnavailableDialog> createState() =>
      _IntegralDrawUnavailableDialogState();
}

class _IntegralDrawUnavailableDialogState
    extends State<_IntegralDrawUnavailableDialog> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '功能暂未开放',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
