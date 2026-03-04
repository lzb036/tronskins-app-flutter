// lib/pages/user/user_menu_config.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class UserMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const UserMenuItem(this.title, this.icon, [this.onTap]);
}

final userMenuItems = [
  UserMenuItem(
    'app.user.menu.buy',
    Icons.shopping_bag_outlined,
    () => Get.toNamed(Routers.SHOP_PURCHASE),
  ),
  UserMenuItem('app.user.menu.sale', Icons.receipt_long_outlined, () {
    final navCtrl = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    navCtrl.switchToShopTab(NavController.shopTabSaleRecord);
  }),
  UserMenuItem(
    'app.user.menu.purchase',
    Icons.search,
    () => Get.toNamed(Routers.BUYING),
  ),
  UserMenuItem('app.user.menu.collection', Icons.favorite_border),
  UserMenuItem(
    'app.user.menu.guard',
    Icons.security_outlined,
    () => Get.toNamed(Routers.USER_GUARD),
  ),
  UserMenuItem(
    'app.user.menu.shop',
    Icons.store_outlined,
    () => Get.toNamed(Routers.SHOP_SETTING),
  ),
  UserMenuItem(
    'app.user.wallet.title',
    Icons.account_balance_wallet_outlined,
    () => Get.toNamed(Routers.WALLET),
  ),
  UserMenuItem(
    'app.user.server.help',
    Icons.menu_book,
    () => Get.toNamed(Routers.HELP_CENTER),
  ),
  UserMenuItem(
    'app.user.server.coupon',
    Icons.card_giftcard,
    () => Get.toNamed(Routers.COUPON),
  ),
  UserMenuItem(
    'app.user.integral.title',
    Icons.stars_outlined,
    () => Get.toNamed(Routers.INTEGRAL),
  ),
];
