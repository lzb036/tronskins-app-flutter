import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/common/widgets/login_required_prompt.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/controllers/wallet/integral_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class IntegralPage extends StatefulWidget {
  const IntegralPage({super.key});

  @override
  State<IntegralPage> createState() => _IntegralPageState();
}

class _IntegralPageState extends State<IntegralPage> {
  final IntegralController controller = Get.isRegistered<IntegralController>()
      ? Get.find<IntegralController>()
      : Get.put(IntegralController());
  final UserController userController = Get.find<UserController>();
  Worker? _loginWorker;

  @override
  void initState() {
    super.initState();
    if (userController.isLoggedIn.value) {
      controller.refreshUser();
      controller.loadCouponsList();
    }
    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        controller.refreshUser();
        controller.loadCouponsList();
      } else {
        controller.userInfo.value = null;
        controller.couponItems.clear();
      }
    });
  }

  @override
  void dispose() {
    _loginWorker?.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    await Future.wait<void>([
      controller.refreshUser(),
      controller.loadCouponsList(),
    ]);
  }

  Future<void> _exchange(int type) async {
    final ok = await controller.exchangeCoupon(type);
    if (ok) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.system.message.success'.tr,
        titleText: const SizedBox.shrink(),
      );
    }
  }

  bool _shouldShowCouponValidity(WalletCouponItem item) {
    final validity = item.validate;
    return validity != null && validity > 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompactTopBar = MediaQuery.sizeOf(context).width < 420;
    return Obx(() {
      final loggedIn = userController.isLoggedIn.value;
      return Scaffold(
        backgroundColor: WalletUi.pageBackground(context),
        appBar: AppBar(
          centerTitle: false,
          leadingWidth: 40,
          titleSpacing: 4,
          title: Text(
            'app.user.integral.title'.tr,
            maxLines: 1,
            softWrap: false,
          ),
          actions: loggedIn
              ? [
                  Padding(
                    padding: EdgeInsets.only(right: isCompactTopBar ? 6 : 8),
                    child: isCompactTopBar
                        ? IconButton(
                            onPressed: () =>
                                Get.toNamed(Routers.WALLET_INTEGRAL_RECORD),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                            ),
                            tooltip: 'app.user.wallet.integral_details'.tr,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 40,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: () =>
                                Get.toNamed(Routers.WALLET_INTEGRAL_RECORD),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 18,
                            ),
                            label: Text('app.user.wallet.integral_details'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ]
              : const [],
        ),
        body: loggedIn
            ? BackToTopScope(
                enabled: false,
                child: Obx(() {
                  final integral = controller.integralValue;
                  final coupons = controller.couponItems;
                  final isLoading = controller.isLoadingCoupons.value;
                  return RefreshIndicator(
                    onRefresh: _refreshPage,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _buildHeroCard(context, integral: integral),
                        const SizedBox(height: 16),
                        _buildDrawEntry(context),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, count: coupons.length),
                        const SizedBox(height: 12),
                        if (isLoading && coupons.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (coupons.isEmpty)
                          _buildEmptyState(context)
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 12.0;
                              final columns = constraints.maxWidth >= 340
                                  ? 2
                                  : 1;
                              final itemWidth =
                                  (constraints.maxWidth -
                                      spacing * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final item in coupons)
                                    SizedBox(
                                      width: itemWidth,
                                      child: _buildCouponCard(context, item),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
              )
            : const LoginRequiredPrompt(),
      );
    });
  }

  Widget _buildHeroCard(BuildContext context, {required int integral}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: WalletUi.primaryGradient(context),
        borderRadius: WalletUi.cardRadius,
        boxShadow: WalletUi.gradientShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'app.user.integral.title'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '$integral',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawEntry(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: WalletUi.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: WalletUi.cardRadius,
          onTap: () => Get.toNamed(Routers.INTEGRAL_DRAW),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.casino_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'app.user.integral.draw'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'app.user.integral.draw_weekly'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required int count}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'app.user.equity.card'.tr,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: WalletUi.cardDecoration(context),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.redeem_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'app.common.no_data'.tr,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, WalletCouponItem item) {
    final palette = _couponPalette(context, item.couponsType);
    final colorScheme = Theme.of(context).colorScheme;
    final showValidity = _shouldShowCouponValidity(item);
    return Container(
      decoration: WalletUi.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.top, palette.bottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'app.user.integral.exchange'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.desc ?? item.typeName ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.value ?? 0} ${'app.user.integral.unit'.tr}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showValidity)
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${'app.user.coupon.validity'.tr}: ${item.validate}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                if (showValidity) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: item.type == null
                        ? null
                        : () => _exchange(item.type!),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.button,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colorScheme.surfaceContainerHigh,
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: Text('app.user.coupon.exchange'.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({Color top, Color bottom, Color button}) _couponPalette(
    BuildContext context,
    int? couponsType,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (couponsType == 1) {
      return (
        top: const Color(0xFFFFA43A),
        bottom: const Color(0xFFF06A1D),
        button: const Color(0xFFF06A1D),
      );
    }
    if (couponsType == 2) {
      return (
        top: const Color(0xFF8F4E2B),
        bottom: const Color(0xFF6D311B),
        button: const Color(0xFF7A3B22),
      );
    }
    return (
      top: colorScheme.primary.withValues(alpha: 0.90),
      bottom: colorScheme.secondary.withValues(alpha: 0.76),
      button: colorScheme.primary,
    );
  }
}
