import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';

class ExchangeRatePage extends StatefulWidget {
  const ExchangeRatePage({super.key});

  @override
  State<ExchangeRatePage> createState() => _ExchangeRatePageState();
}

class _ExchangeRatePageState extends State<ExchangeRatePage> {
  @override
  void initState() {
    super.initState();
    Get.find<CurrencyController>().fetchRealRates(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CurrencyController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.setting.exchange_rate'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ctrl.fetchRealRates(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (!ctrl.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => ctrl.fetchRealRates(force: true),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: ctrl.allRates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = ctrl.allRates[i];
              final code = item['code'] as String;
              final symbol = item['symbol'] as String? ?? '';
              final rate = (item['rate'] as num?)?.toDouble() ?? 1.0;
              final usdAmount = rate > 0 ? 1 / rate : 0.0;
              final currentCode = ctrl.code;
              final isCurrent = item['isCurrent'] == true;
              return ListTile(
                leading: Image.asset(
                  CurrencyController.getCurrencyIcon(code),
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                title: Text('$code  $symbol'),
                subtitle: Text(
                  '1 $code ≈ ${ctrl.format(usdAmount)} $currentCode',
                ),
                trailing: isCurrent
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: isCurrent,
                onTap: () => ctrl.setCurrency(code),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatRate(double rate) {
    if (rate >= 100) return rate.toStringAsFixed(0);
    if (rate >= 10) return rate.toStringAsFixed(2);
    if (rate >= 1) return rate.toStringAsFixed(4);
    return rate.toStringAsFixed(6);
  }
}
