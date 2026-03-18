import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/common/widgets/glass_notice_dialog.dart';
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
    await showGlassNoticeDialog(
      context,
      message: 'app.system.message.not_open'.tr,
      icon: Icons.lock_clock_outlined,
      barrierLabel: 'integral_draw_unavailable',
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
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_RuleQaItem>[
      _RuleQaItem(
        question: 'app.user.integral.earn'.tr,
        answers: ['app.user.integral.earn_tips'.tr],
      ),
      _RuleQaItem(
        question: 'app.user.integral.use'.tr,
        answers: [
          'app.user.integral.use_tips_1'.tr,
          'app.user.integral.use_tips_2'.tr,
        ],
      ),
      _RuleQaItem(
        question: 'app.user.integral.deduct'.tr,
        answers: ['app.user.integral.deduct_tips'.tr],
      ),
      _RuleQaItem(
        question: 'app.user.integral.validity'.tr,
        answers: ['app.user.integral.validity_tips'.tr],
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.user.integral.intro'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              _buildRuleQaCard(
                index: i + 1,
                item: items[i],
                colorScheme: colorScheme,
              ),
              if (i != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleQaCard({
    required int index,
    required _RuleQaItem item,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$index',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    item.question,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < item.answers.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == item.answers.length - 1 ? 0 : 6,
              ),
              child: Text(
                item.answers[i],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RuleQaItem {
  const _RuleQaItem({required this.question, required this.answers});

  final String question;
  final List<String> answers;
}
