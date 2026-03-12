// lib/pages/user/user_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/user/setting/custom_animated_icon_button.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/widgets/avatar_preview_dialog.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 顶部区域（状态栏 + 头像 + 余额）
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: topPadding + 8, bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                          : [colors.primary, colors.primary.withOpacity(0.85)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: const _TopRightButtons(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(
                          () => _Header(
                            avatarProvider: userCtrl.avatarProvider,
                            nickname: userCtrl.nickname,
                            isLoggedIn: userCtrl.isLoggedIn.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                ),
                const SizedBox(height: 12),
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
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
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
                child: Text(
                  isLoggedIn ? nickname : 'app.user.login.nologin'.tr,
                  style: text.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopRightButtons extends StatelessWidget {
  const _TopRightButtons();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomAnimatedIconButton(
        icon: Icons.center_focus_weak,
        normalIconColor: Colors.white,
        onTap: () {},
      ),
      const SizedBox(width: 8),
      CustomAnimatedIconButton(
        icon: Icons.notifications,
        normalIconColor: Colors.white,
        onTap: () => Get.toNamed(Routers.MESSAGE),
      ),
      const SizedBox(width: 8),
      CustomAnimatedIconButton(
        icon: Icons.settings,
        normalIconColor: Colors.white,
        onTap: () => Get.toNamed(Routers.USER_SETTING),
      ),
    ],
  );
}

// ==================== 余额区 ====================
class _BalanceSection extends StatelessWidget {
  final String balance, gift, locked, unsettled;
  const _BalanceSection({
    required this.balance,
    required this.gift,
    required this.locked,
    required this.unsettled,
  });

  @override
  Widget build(BuildContext context) {
    // final text = Theme.of(context).extension<AppTextTheme>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(Routers.WALLET),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 15,
                child: _buildBalanceItem(
                  context,
                  'app.user.wallet.assets_total'.tr,
                  balance,
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                flex: 10,
                child: _buildBalanceItem(
                  context,
                  'app.user.wallet.gift'.tr,
                  gift,
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                flex: 10,
                child: _buildBalanceItem(
                  context,
                  'app.user.wallet.lock_amount'.tr,
                  locked,
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                flex: 10,
                child: _buildBalanceItem(
                  context,
                  'app.user.wallet.unsettled'.tr,
                  unsettled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    String value, {
    bool clickable = false,
  }) {
    return Builder(
      builder: (ctx) {
        // final text = Theme.of(ctx).extension<AppTextTheme>()!;
        final child = Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        );
        return clickable
            ? InkWell(
                onTap: () => Get.toNamed(Routers.BALANCE_DETAIL),
                child: child,
              )
            : child;
      },
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
                color: Colors.black.withOpacity(0.05),
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
