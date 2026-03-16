// lib/pages/user/setting/user_setting.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/common/hooks/theme/use_theme.dart';
import 'package:tronskins_app/common/widgets/avatar_preview_dialog.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

const _avatarHeroTag = 'user-avatar-hero-setting';

class UserSetting extends StatelessWidget {
  const UserSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserController>();
    final useTheme = Get.find<UseTheme>();
    final useLocale = Get.find<UseLocale>();
    final currencyCtrl = Get.find<CurrencyController>();

    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        appBar: AppBar(title: Text('app.user.setting.title'.tr)),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _buildSection(
              children: [
                Obx(() => _buildAvatarItem(context, userCtrl)),
                Obx(() {
                  final loggedIn = userCtrl.isLoggedIn.value;
                  final nickname = userCtrl.nickname;
                  final value = loggedIn
                      ? (nickname.isNotEmpty
                            ? nickname
                            : 'app.user.setting.nickname_not_set'.tr)
                      : 'app.user.login.nologin'.tr;
                  return _buildInfoItem(
                    'app.user.setting.nickname'.tr,
                    value,
                    onTap: loggedIn ? null : () => Get.toNamed(Routers.LOGIN),
                  );
                }),
                Obx(() {
                  final loggedIn = userCtrl.isLoggedIn.value;
                  final email = userCtrl.email;
                  final value = loggedIn && email.isNotEmpty
                      ? email
                      : 'app.user.login.nologin'.tr;
                  return _buildInfoItem(
                    'app.user.setting.email'.tr,
                    value,
                    onTap: loggedIn ? null : () => Get.toNamed(Routers.LOGIN),
                  );
                }),
              ],
            ),
            _buildSection(
              children: [
                _buildActionItem(
                  'app.user.setting.nickname_change'.tr,
                  onTap: () => Get.toNamed(Routers.USER_EDIT_NICKNAME),
                ),
                _buildActionItem(
                  'app.user.setting.password_change'.tr,
                  onTap: () => Get.toNamed(Routers.USER_EDIT_PASSWORD),
                ),
                _buildActionItem(
                  'app.user.menu.guard'.tr,
                  onTap: () => Get.toNamed(Routers.USER_GUARD),
                ),
                _buildActionItem(
                  'app.user.setting.steam_management'.tr,
                  onTap: () => Get.toNamed(Routers.STEAM_SETTING),
                ),
                _buildActionItem(
                  'app.user.setting.multilingual'.tr,
                  trailing: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          useLocale.getCurrentLanguageIcon(),
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          useLocale.getLanguageName(useLocale.currentLocale),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showLanguageSheet(context, useLocale),
                ),
                _buildActionItem(
                  'app.user.setting.exchange_rate'.tr,
                  trailing: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          currencyCtrl.currentCurrencyIcon,
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8),
                        Text(currencyCtrl.code),
                      ],
                    ),
                  ),
                  onTap: () => Get.toNamed(Routers.USER_SETTING_RATE),
                ),
                _buildActionItem(
                  'app.user.setting.theme'.tr,
                  trailing: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_themeModeIcon(useTheme.themeMode), size: 20),
                        const SizedBox(width: 8),
                        Text(_themeModeLabel(useTheme.themeMode)),
                      ],
                    ),
                  ),
                  onTap: () => _showThemeSheet(context, useTheme),
                ),
                _buildActionItem(
                  'app.user.setting.server'.tr,
                  onTap: () => Get.toNamed(Routers.USER_SETTING_SERVER),
                ),
                _buildActionItem(
                  'app.user.setting.about'.tr,
                  onTap: () => Get.toNamed(Routers.USER_ABOUT),
                ),
                _buildActionItem(
                  '认证测试中心',
                  onTap: () => Get.toNamed(Routers.USER_AUTH_TEST),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() {
                final loggedIn = userCtrl.isLoggedIn.value;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final error = theme.colorScheme.error;
                final errorContainer = theme.colorScheme.errorContainer;
                final disabledBg = isDark
                    ? const Color(0xFF2A2D33)
                    : const Color(0xFFF1F2F4);
                final disabledBorder = isDark
                    ? const Color(0xFF3A3E45)
                    : const Color(0xFFE0E3E8);
                final disabledFg = isDark
                    ? const Color(0xFF8A8F98)
                    : const Color(0xFF8C9199);
                final activeGradient = isDark
                    ? const LinearGradient(
                        colors: [Color(0xFFE98773), Color(0xFFC95A47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Color.lerp(error, const Color(0xFFB00020), 0.15) ??
                              error,
                          Color.lerp(error, errorContainer, 0.35) ?? error,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                final activeBorder = isDark
                    ? Border.all(
                        color: const Color(0xFFFFD2C6).withValues(alpha: 0.18),
                      )
                    : null;
                return SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: loggedIn ? activeGradient : null,
                      color: loggedIn ? null : disabledBg,
                      borderRadius: BorderRadius.circular(14),
                      border: loggedIn
                          ? activeBorder
                          : Border.all(color: disabledBorder),
                      boxShadow: loggedIn
                          ? [
                              BoxShadow(
                                color: isDark
                                    ? const Color(
                                        0xFFB94B3E,
                                      ).withValues(alpha: 0.34)
                                    : error.withValues(alpha: 0.25),
                                blurRadius: isDark ? 24 : 16,
                                offset: const Offset(0, 8),
                              ),
                              if (isDark)
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFC6B5,
                                  ).withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                            ]
                          : null,
                    ),
                    child: FilledButton(
                      style:
                          FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: disabledFg,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white.withValues(alpha: 0.12);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.white.withValues(alpha: 0.06);
                              }
                              return null;
                            }),
                          ),
                      onPressed: loggedIn ? userCtrl.logout : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            loggedIn
                                ? Icons.logout_rounded
                                : Icons.lock_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text('app.user.login.logout'.tr),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 统一的分组 ====================
  Widget _buildSection({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(children: children),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==================== 头像项 ====================
  Widget _buildAvatarItem(BuildContext context, UserController ctrl) {
    return ListTile(
      title: Text('app.user.setting.avatar'.tr),
      trailing: Hero(
        tag: _avatarHeroTag,
        child: Material(
          color: Colors.transparent,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: ctrl.avatarProvider,
          ),
        ),
      ),
      onTap: () => showAvatarPreviewDialog(
        context,
        imageProvider: ctrl.avatarProvider,
        heroTag: _avatarHeroTag,
      ),
    );
  }

  // ==================== 信息项（不可点） ====================
  Widget _buildInfoItem(String title, String value, {VoidCallback? onTap}) {
    final trailing = Text(
      value,
      style: TextStyle(
        color: onTap != null ? Get.theme.colorScheme.primary : Colors.grey[600],
        fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    return ListTile(title: Text(title), trailing: trailing, onTap: onTap);
  }

  // ==================== 可点击项（统一风格） ====================
  Widget _buildActionItem(
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap:
          onTap ??
          () => Get.snackbar(
            'app.system.tips.title'.tr,
            'app.system.message.not_open'.tr,

            titleText: const SizedBox.shrink(),
          ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'app.user.setting.theme_light'.tr;
      case ThemeMode.dark:
        return 'app.user.setting.theme_dark'.tr;
      case ThemeMode.system:
        return 'app.user.setting.theme_system'.tr;
    }
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.settings_suggest_outlined;
    }
  }

  void _showLanguageSheet(BuildContext context, UseLocale useLocale) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: useLocale.supportedLanguages.length,
            itemBuilder: (context, index) {
              final lang = useLocale.supportedLanguages[index];
              final isSelected =
                  lang['code'] == useLocale.currentLocale.languageCode &&
                  lang['country'] == useLocale.currentLocale.countryCode;
              return ListTile(
                leading: Image.asset(
                  useLocale.getLanguageIcon(lang),
                  width: 32,
                  height: 32,
                ),
                title: Text(useLocale.getLocalizedLanguageName(lang)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  useLocale.changeLanguage(
                    lang['code'] ?? 'en',
                    lang['country'] ?? 'US',
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showThemeSheet(BuildContext context, UseTheme useTheme) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Obx(() {
            final current = useTheme.themeMode;
            final isSystemSelected = current == ThemeMode.system;
            final isLightSelected = current == ThemeMode.light;
            final isDarkSelected = current == ThemeMode.dark;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_suggest_outlined),
                  title: Text('app.user.setting.theme_system'.tr),
                  trailing: isSystemSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    useTheme.changeThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_outlined),
                  title: Text('app.user.setting.theme_light'.tr),
                  trailing: isLightSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    useTheme.changeThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text('app.user.setting.theme_dark'.tr),
                  trailing: isDarkSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    useTheme.changeThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        );
      },
    );
  }
}
