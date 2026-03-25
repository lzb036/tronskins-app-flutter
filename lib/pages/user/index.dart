// lib/pages/user/user_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/user/setting/custom_animated_icon_button.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/widgets/avatar_preview_dialog.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/pages/user/scan_login_page.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:tronskins_app/common/theme/app_colors.dart';
import 'package:tronskins_app/common/theme/app_text_theme.dart';
import 'user_menu_config.dart';

const _avatarHeroTag = 'user-avatar-hero-user';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserController>();
    final currency = Get.find<CurrencyController>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        backgroundColor: colors.scaffoldBackground,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _HeroSection(
                      topPadding: topPadding,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: const _TopRightButtons(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Obx(
                              () => _Header(
                                avatarProvider: userCtrl.avatarProvider,
                                nickname: userCtrl.nickname,
                                isLoggedIn: userCtrl.isLoggedIn.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -44,
                      child: Obx(
                        () => _BalanceSection(
                          balance: currency.formatUsd(userCtrl.balanceValue),
                          gift: currency.formatUsd(userCtrl.giftValue),
                          locked: currency.formatUsd(userCtrl.lockedValue),
                          unsettled: currency.formatUsd(
                            userCtrl.settlementValue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 58),
                // 菜单区
                _MenuSection(itemConfigs: userMenuItems),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 头部 ====================
class _HeroSection extends StatelessWidget {
  final double topPadding;
  final Widget child;

  const _HeroSection({required this.topPadding, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startColor = isDark
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: 0.12),
            const Color(0xFF111414),
          )
        : Color.alphaBlend(
            colors.primary.withValues(alpha: 0.12),
            const Color(0xFFF7FBFB),
          );
    final endColor = isDark ? const Color(0xFF1A1714) : const Color(0xFFF3E6D2);
    final shadowColor = isDark
        ? colors.primary.withValues(alpha: 0.10)
        : colors.primary.withValues(alpha: 0.16);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(0, topPadding + 10, 0, 88),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -12,
            child: _HeroGlow(
              size: 160,
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.52),
            ),
          ),
          Positioned(
            left: -18,
            top: 92,
            child: _HeroGlow(
              size: 112,
              color: isDark
                  ? const Color(0xFFF2D7AF).withValues(alpha: 0.05)
                  : colors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.03 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ImageProvider avatarProvider;
  final String nickname;
  final bool isLoggedIn;

  const _Header({
    required this.avatarProvider,
    required this.nickname,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).extension<AppTextTheme>()!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF4E7CF)
        : const Color(0xFF154F55);

    return Row(
      children: [
        GestureDetector(
          onTap: () => showAvatarPreviewDialog(
            context,
            imageProvider: avatarProvider,
            heroTag: _avatarHeroTag,
          ),
          behavior: HitTestBehavior.opaque,
          child: Hero(
            tag: _avatarHeroTag,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            colors.primary.withValues(alpha: 0.32),
                            Colors.white.withValues(alpha: 0.10),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.96),
                            colors.primary.withValues(alpha: 0.26),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarProvider,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isLoggedIn ? null : () => Get.toNamed(Routers.LOGIN),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? nickname : 'app.user.login.nologin'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark
        ? const Color(0xFFF4E7CF)
        : const Color(0xFF16565C);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.56),
        ),
      ),
      child: CustomAnimatedIconButton(
        icon: icon,
        onTap: onTap,
        padding: const EdgeInsets.all(8),
        borderRadius: 14,
        normalColor: Colors.transparent,
        pressedColor: colors.primary,
        normalIconColor: foregroundColor,
        pressedIconColor: foregroundColor,
      ),
    );
  }
}

class _TopRightButtons extends StatelessWidget {
  const _TopRightButtons();

  Future<void> _scanCode() async {
    final userCtrl = Get.find<UserController>();
    if (!userCtrl.isLoggedIn.value) {
      AppSnackbar.info('app.system.message.nologin'.tr);
      return;
    }
    await Get.to(() => const ScanLoginPage());
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _TopActionButton(icon: Icons.center_focus_weak, onTap: _scanCode),
      const SizedBox(width: 10),
      _TopActionButton(
        icon: Icons.notifications_none_rounded,
        onTap: () => Get.toNamed(Routers.MESSAGE),
      ),
      const SizedBox(width: 10),
      _TopActionButton(
        icon: Icons.settings_outlined,
        onTap: () => Get.toNamed(Routers.USER_SETTING),
      ),
    ],
  );
}

// ==================== 余额区 ====================
class _BalanceSection extends StatelessWidget {
  static const List<int> _metricFlexes = <int>[6, 4, 4, 6];
  static const double _dividerSpacing = 3;
  static const double _dividerWidth = 1;

  final String balance, gift, locked, unsettled;
  const _BalanceSection({
    required this.balance,
    required this.gift,
    required this.locked,
    required this.unsettled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppColors>()!;
    final text = Theme.of(context).extension<AppTextTheme>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startColor = isDark
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: 0.08),
            const Color(0xFF0E1213),
          )
        : Colors.white.withValues(alpha: 0.97);
    final endColor = isDark ? const Color(0xFF111716) : const Color(0xFFFFFAF2);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: () => Get.toNamed(Routers.WALLET),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.primary.withValues(alpha: 0.12)
                          : colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: isDark
                          ? const Color(0xFFF4E7CF)
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'app.user.wallet.title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall.copyWith(
                        color: isDark
                            ? const Color(0xFFF4E7CF)
                            : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : colors.textSecondary.withValues(alpha: 0.9),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidths = _resolveMetricWidths(constraints.maxWidth);
                  final valueFontSize = _resolveSharedFontSize(
                    context,
                    texts: <String>[balance, locked, gift, unsettled],
                    widths: itemWidths,
                    maxFontSize: 16,
                    minFontSize: 10,
                    fontWeight: FontWeight.w700,
                  );
                  final labelFontSize = _resolveSharedFontSize(
                    context,
                    texts: <String>[
                      'app.user.wallet.assets_total'.tr,
                      'app.user.wallet.lock_amount'.tr,
                      'app.user.wallet.gift'.tr,
                      'app.user.wallet.unsettled'.tr,
                    ],
                    widths: itemWidths,
                    maxFontSize: 11,
                    minFontSize: 9,
                    fontWeight: FontWeight.w500,
                  );
                  return Row(
                    children: [
                      Expanded(
                        flex: _metricFlexes[0],
                        child: _buildBalanceItem(
                          context,
                          'app.user.wallet.assets_total'.tr,
                          balance,
                          valueFontSize: valueFontSize,
                          labelFontSize: labelFontSize,
                          emphasize: true,
                        ),
                      ),
                      _buildVerticalDivider(context),
                      Expanded(
                        flex: _metricFlexes[1],
                        child: _buildBalanceItem(
                          context,
                          'app.user.wallet.lock_amount'.tr,
                          locked,
                          valueFontSize: valueFontSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      _buildVerticalDivider(context),
                      Expanded(
                        flex: _metricFlexes[2],
                        child: _buildBalanceItem(
                          context,
                          'app.user.wallet.gift'.tr,
                          gift,
                          valueFontSize: valueFontSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      _buildVerticalDivider(context),
                      Expanded(
                        flex: _metricFlexes[3],
                        child: _buildBalanceItem(
                          context,
                          'app.user.wallet.unsettled'.tr,
                          unsettled,
                          valueFontSize: valueFontSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 34,
      width: _dividerWidth,
      margin: const EdgeInsets.symmetric(horizontal: _dividerSpacing),
      color: Theme.of(
        context,
      ).dividerColor.withValues(alpha: isDark ? 0.22 : 0.55),
    );
  }

  List<double> _resolveMetricWidths(double totalWidth) {
    final totalFlex = _metricFlexes.reduce((sum, item) => sum + item);
    final dividerFootprint = _metricFlexes.length > 1
        ? (_metricFlexes.length - 1) * (_dividerWidth + (_dividerSpacing * 2))
        : 0;
    final usableWidth = (totalWidth - dividerFootprint).clamp(0.0, totalWidth);
    return _metricFlexes
        .map((flex) => usableWidth * flex / totalFlex)
        .toList(growable: false);
  }

  double _resolveSharedFontSize(
    BuildContext context, {
    required List<String> texts,
    required List<double> widths,
    required double maxFontSize,
    required double minFontSize,
    required FontWeight fontWeight,
  }) {
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: fontWeight,
          height: 1.0,
        ) ??
        TextStyle(fontWeight: fontWeight, height: 1.0);

    for (
      double fontSize = maxFontSize;
      fontSize >= minFontSize;
      fontSize -= 0.25
    ) {
      var fitsAll = true;
      for (var index = 0; index < texts.length; index++) {
        final painter = TextPainter(
          text: TextSpan(
            text: texts[index],
            style: baseStyle.copyWith(fontSize: fontSize),
          ),
          textDirection: direction,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        if (painter.width > widths[index]) {
          fitsAll = false;
          break;
        }
      }
      if (fitsAll) {
        return fontSize;
      }
    }
    return minFontSize;
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    String value, {
    required double valueFontSize,
    required double labelFontSize,
    bool emphasize = false,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = emphasize
        ? (isDark ? const Color(0xFFF4E7CF) : const Color(0xFF15575E))
        : (isDark ? Colors.white.withValues(alpha: 0.90) : colors.textPrimary);

    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: valueFontSize,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: labelFontSize,
            color: isDark
                ? Colors.white.withValues(alpha: 0.60)
                : colors.textSecondary.withValues(alpha: 0.88),
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ==================== 菜单区 ====================
class _MenuSection extends StatelessWidget {
  final List<UserMenuItem> itemConfigs;
  const _MenuSection({required this.itemConfigs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGroupCard(
          context,
          'app.user.menu.deal'.tr,
          itemConfigs.take(6).toList(),
        ),
        const SizedBox(height: 16),
        _buildGroupCard(
          context,
          'app.user.server.title'.tr,
          itemConfigs.skip(6).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    String title,
    List<UserMenuItem> items,
  ) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final text = Theme.of(context).extension<AppTextTheme>()!;
    const horizontalPadding = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - horizontalPadding * 2) / 4;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  title,
                  style: text.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 0,
                runSpacing: 0,
                children: items.map((e) {
                  return SizedBox(
                    width: itemWidth,
                    child: _menuItem(context, e),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(BuildContext context, UserMenuItem item) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: colors.textPrimary, size: 28),
            const SizedBox(height: 8),
            Text(
              item.title.tr,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
