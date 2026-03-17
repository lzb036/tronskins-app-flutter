import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/wallet/coupon_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage>
    with SingleTickerProviderStateMixin {
  final CouponController controller = Get.isRegistered<CouponController>()
      ? Get.find<CouponController>()
      : Get.put(CouponController());

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.loadCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_InterestItem> get _vested => [
    _InterestItem(
      label: 'app.user.equity.price_trend',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.price_trend_explain',
      background: const Color(0xFFFB8402),
    ),
    _InterestItem(
      label: 'app.user.equity.card',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.card_explain',
      background: const Color(0xFF752D17),
    ),
  ];

  List<_InterestItem> get _unowned => [
    _InterestItem(
      label: 'app.user.equity.price_trend',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.price_trend_explain',
      background: const Color(0xFF909090),
    ),
    _InterestItem(
      label: 'app.user.equity.identification',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.identification_explain',
      background: const Color(0xFF909090),
    ),
    _InterestItem(
      label: 'app.user.equity.card',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.card_explain',
      background: const Color(0xFF909090),
    ),
    _InterestItem(
      label: 'app.user.equity.commission_free',
      type: 'app.user.integral.exchange',
      content: 'app.user.equity.commission_free_explain',
      background: const Color(0xFF909090),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.coupon.title'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'app.user.equity.title'.tr),
            Tab(text: 'app.user.coupon.title'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInterestTab(), _buildCouponTab()],
      ),
    );
  }

  Widget _buildInterestTab() {
    return BackToTopScope(
      enabled: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'app.user.equity.vested'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._vested.map(_buildInterestCard),
          const SizedBox(height: 16),
          Text(
            'app.user.equity.not_owned'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._unowned.map(_buildInterestCard),
        ],
      ),
    );
  }

  Widget _buildInterestCard(_InterestItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.label.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.type.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.content.tr,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = controller.coupons;
      return Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (list.isEmpty)
                Center(child: Text('app.user.coupon.none'.tr))
              else
                ...list.map((item) {
                  final color = item.couponsType == 1
                      ? const Color(0xFFFB8402)
                      : item.couponsType == 2
                      ? const Color(0xFF752D17)
                      : Theme.of(context).colorScheme.primaryContainer;
                  final showExpiry = _hasExpiry(item.expireTime);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.typeName ?? '-'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('app.user.integral.exchange'.tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (showExpiry)
                                Text(
                                  '${'app.user.coupon.validity'.tr}: '
                                  '${_formatDate(item.expireTime)}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              if (showExpiry) const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                                child: Text('app.user.coupon.use'.tr),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 72),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton(
              onPressed: () => Get.toNamed(Routers.INTEGRAL),
              child: Text('app.user.coupon.exchange_go'.tr),
            ),
          ),
        ],
      );
    });
  }

  bool _hasExpiry(int? seconds) {
    return seconds != null && seconds > 0;
  }

  String _formatDate(int? seconds) {
    if (!_hasExpiry(seconds)) {
      return '-';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(seconds! * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class _InterestItem {
  final String label;
  final String type;
  final String content;
  final Color background;

  const _InterestItem({
    required this.label,
    required this.type,
    required this.content,
    required this.background,
  });
}
