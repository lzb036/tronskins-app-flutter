// lib/components/layout/custom_navbar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/controllers/home/home_controller.dart';
import 'package:tronskins_app/controllers/inventory/inventory_controller.dart';
import 'package:tronskins_app/controllers/market/market_list_controller.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_order_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_sales_controller.dart';
import 'package:tronskins_app/controllers/shop/shop_shipping_notice_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/pages/home/index.dart';
import 'package:tronskins_app/pages/navbar/market.dart';
import 'package:tronskins_app/pages/navbar/inventory.dart';
import 'package:tronskins_app/pages/navbar/shop.dart';
import 'package:tronskins_app/pages/user/index.dart'; // 你的 UserPage

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  static const int _tabCount = 5;
  late final NavController navController;
  late final ShopShippingNoticeController shippingNoticeController;
  late final Worker _navWorker;
  late final Worker _localeWorker;

  late final UseLocale useLocale;
  final List<bool> _needsRefresh = List<bool>.filled(_tabCount, false);

  // Lazy-init tab pages to avoid firing all requests on cold start.
  final List<Widget?> _pages = List<Widget?>.filled(_tabCount, null);

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const MarketPage();
      case 2:
        return const InventoryPage();
      case 3:
        return const ShopPage();
      case 4:
        return const UserPage();
      default:
        return const SizedBox.shrink();
    }
  }

  void _ensurePage(int index) {
    if (_pages[index] == null) {
      _pages[index] = _createPage(index);
    }
  }

  bool _shouldAutoRefresh(int index) {
    return index >= 0 && index <= 3;
  }

  void _markLocaleChanged() {
    for (var i = 0; i < _tabCount; i++) {
      if (_pages[i] != null && _shouldAutoRefresh(i)) {
        _needsRefresh[i] = true;
      }
    }
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refreshAll();
        }
        break;
      case 1:
        if (Get.isRegistered<MarketListController>()) {
          Get.find<MarketListController>().refresh(reset: true);
        }
        break;
      case 2:
        if (Get.isRegistered<InventoryController>()) {
          Get.find<InventoryController>().refreshList();
        }
        break;
      case 3:
        if (!Get.isRegistered<UserController>()) {
          return;
        }
        final userCtrl = Get.find<UserController>();
        if (!userCtrl.isLoggedIn.value) {
          return;
        }
        if (Get.isRegistered<ShopSalesController>()) {
          final salesCtrl = Get.find<ShopSalesController>();
          salesCtrl.refreshOnSale();
          salesCtrl.refreshSellRecords();
        }
        if (Get.isRegistered<ShopOrderController>()) {
          Get.find<ShopOrderController>().refreshPending();
        }
        shippingNoticeController.refreshPendingTotals();
        break;
      default:
        break;
    }
  }

  Widget _buildNavIconWithBadge({
    required IconData icon,
    required int badgeCount,
  }) {
    final showBadge = badgeCount > 0;
    final badgeText = badgeCount > 99 ? '99+' : '$badgeCount';
    final badgeColor = Colors.orange.shade600;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -13,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                badgeText,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    useLocale = Get.find<UseLocale>();
    navController = Get.isRegistered<NavController>()
        ? Get.find<NavController>()
        : Get.put(NavController(), permanent: true);
    shippingNoticeController = Get.isRegistered<ShopShippingNoticeController>()
        ? Get.find<ShopShippingNoticeController>()
        : Get.put(ShopShippingNoticeController(), permanent: true);
    _ensurePage(navController.currentIndex.value);
    _navWorker = ever<int>(navController.currentIndex, (index) {
      _ensurePage(index);
      if (_needsRefresh[index]) {
        _needsRefresh[index] = false;
        _refreshTab(index);
      }
      if (index == 4) {
        final userCtrl = Get.find<UserController>();
        if (userCtrl.isLoggedIn.value && !userCtrl.isLoading.value) {
          userCtrl.fetchUserData(showLoading: false);
        }
      }
    });

    _localeWorker = ever<Locale>(useLocale.localeRx, (_) {
      _markLocaleChanged();
      final current = navController.currentIndex.value;
      if (_needsRefresh[current]) {
        _needsRefresh[current] = false;
        _refreshTab(current);
      }
    });
  }

  @override
  void dispose() {
    _navWorker.dispose();
    _localeWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final index = navController.currentIndex.value;
        _ensurePage(index);
        return IndexedStack(
          index: index,
          children: List.generate(_pages.length, (pageIndex) {
            final page = _pages[pageIndex];
            if (page == null) {
              return const SizedBox.shrink();
            }
            return KeepAliveWrapper(child: page);
          }),
        );
      }),
      bottomNavigationBar: Obx(() {
        // 监听语言变化，触发底部导航重建
        useLocale.currentLocale;
        final index = navController.currentIndex.value;
        final userCtrl = Get.find<UserController>();
        final pendingTotals = shippingNoticeController.pendingTotalsByGame;
        final sellBadgeCount = userCtrl.isLoggedIn.value
            ? pendingTotals.values.fold<int>(
                0,
                (total, count) => total + (count > 0 ? count : 0),
              )
            : 0;
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: (index) {
            navController.switchTo(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: 'app.tabbar.home'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_outlined),
              label: 'app.tabbar.market'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.backpack_outlined),
              label: 'app.tabbar.inventory'.tr,
            ),
            BottomNavigationBarItem(
              icon: _buildNavIconWithBadge(
                icon: Icons.shopping_cart_outlined,
                badgeCount: sellBadgeCount,
              ),
              label: 'app.tabbar.sell'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: 'app.tabbar.mine'.tr,
            ),
          ],
        );
      }),
    );
  }
}

// 保持页面状态（完美封装）
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({required this.child, super.key});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用！
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
