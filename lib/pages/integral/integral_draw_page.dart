import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/wallet/integral_controller.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';

class IntegralDrawPage extends StatefulWidget {
  const IntegralDrawPage({super.key});

  @override
  State<IntegralDrawPage> createState() => _IntegralDrawPageState();
}

class _IntegralDrawPageState extends State<IntegralDrawPage> {
  final IntegralController controller =
      Get.isRegistered<IntegralController>()
          ? Get.find<IntegralController>()
          : Get.put(IntegralController());

  final List<int> _gridOrder = const [0, 1, 2, 7, -1, 3, 6, 5, 4];
  int? _activeIndex;
  bool _isRunning = false;
  Timer? _timer;
  late DateTime _startTime;
  WalletLotteryResult? _result;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    controller.refreshUser();
    controller.loadLotteryPrizes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  Future<void> _startDraw() async {
    if (_isRunning) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.integral.draw_underway'.tr,
      );
      return;
    }
    if (controller.integralValue < 1000) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.integral.insufficient'.tr,
      );
      return;
    }
    _isRunning = true;
    _result = await controller.drawLottery();
    if (_result == null) {
      _isRunning = false;
      return;
    }
    final prizes = _buildPrizes();
    _targetIndex = _matchPrizeIndex(prizes, _result);
    _activeIndex = Random().nextInt(8);
    _startTime = DateTime.now();
    _runAnimation();
    setState(() {});
  }

  int _matchPrizeIndex(
    List<WalletLotteryPrize> prizes,
    WalletLotteryResult? result,
  ) {
    if (result == null) {
      return Random().nextInt(8);
    }
    final title = result.title?.trim().toLowerCase();
    if (title == null || title.isEmpty) {
      return Random().nextInt(8);
    }
    final index = prizes.indexWhere((item) {
      final label = item.label?.trim().toLowerCase();
      return label != null && label.isNotEmpty && label == title;
    });
    return index >= 0 ? index : Random().nextInt(8);
  }

  void _runAnimation() {
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsed >= 5000) {
      _timer?.cancel();
      _activeIndex = _targetIndex;
      _isRunning = false;
      setState(() {});
      _showResultDialog();
      return;
    }
    final speed = _calculateSpeed(elapsed);
    _timer = Timer(Duration(milliseconds: speed), () {
      setState(() {
        _activeIndex = ((_activeIndex ?? 0) + 1) % 8;
      });
      _runAnimation();
    });
  }

  int _calculateSpeed(int elapsed) {
    final progress = elapsed / 5000.0;
    if (progress < 0.3) {
      return 200;
    }
    if (progress < 0.7) {
      return 60;
    }
    return 200;
  }

  Future<void> _showResultDialog() async {
    if (_result == null) {
      return;
    }
    await Get.dialog<void>(
      AlertDialog(
        title: Text('app.user.integral.draw_congratulations'.tr),
        content: Text(_result?.title ?? ''),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.integral.draw_weekly'.tr),
      ),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'app.user.integral.draw'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
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
    );
  }

  Widget _buildGrid(List<WalletLotteryPrize> prizes) {
    final cells = <Widget>[];
    for (final index in _gridOrder) {
      if (index == -1) {
        cells.add(_buildDrawButton());
      } else {
        final prize = prizes[index];
        final isActive = _activeIndex == index;
        cells.add(_buildPrizeCell(prize, isActive));
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
      onTap: _startDraw,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            _isRunning
                ? 'app.user.integral.drawing'.tr
                : 'app.user.integral.draw'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCell(WalletLotteryPrize prize, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.tertiary
              : Colors.transparent,
          width: 2,
        ),
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
