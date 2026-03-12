import 'package:get/get.dart';
import 'package:tronskins_app/bindings/user/user_binding.dart';
import 'package:tronskins_app/components/layout/navbar/NavBarPage.dart';
import 'package:tronskins_app/pages/auth/login.dart';
import 'package:tronskins_app/pages/auth/forget_password_page.dart';
import 'package:tronskins_app/pages/auth/steam_login.dart';
import 'package:tronskins_app/pages/auth/token_recovery_page.dart';
import 'package:tronskins_app/pages/market/market_detail_page.dart';
import 'package:tronskins_app/pages/market/market_item_detail_page.dart';
import 'package:tronskins_app/pages/steam/bind_steam_page.dart';
import 'package:tronskins_app/pages/steam/inventory_setting_page.dart';
import 'package:tronskins_app/pages/steam/steam_api_key_page.dart';
import 'package:tronskins_app/pages/steam/steam_setting_page.dart';
import 'package:tronskins_app/pages/steam/steam_session_page.dart';
import 'package:tronskins_app/pages/steam/steam_trade_url_page.dart';
import 'package:tronskins_app/pages/steam/unbind_steam_page.dart';
import 'package:tronskins_app/pages/shop/inventory_up_shop_page.dart';
import 'package:tronskins_app/pages/shop/buying_page.dart';
import 'package:tronskins_app/pages/shop/buying_supply_page.dart';
import 'package:tronskins_app/pages/shop/buying_update_price_page.dart';
import 'package:tronskins_app/pages/shop/bulk_buying_page.dart';
import 'package:tronskins_app/pages/shop/my_purchase_page.dart';
import 'package:tronskins_app/pages/shop/product_buying_page.dart';
import 'package:tronskins_app/pages/shop/purchase_setting_page.dart';
import 'package:tronskins_app/pages/shop/receive_goods_page.dart';
import 'package:tronskins_app/pages/shop/shop_order_detail_page.dart';
import 'package:tronskins_app/pages/shop/shop_price_change_page.dart';
import 'package:tronskins_app/pages/shop/shop_rename_page.dart';
import 'package:tronskins_app/pages/shop/shop_setting_page.dart';
import 'package:tronskins_app/pages/user/setting/exchange_rate.dart';
import 'package:tronskins_app/pages/user/setting/edit_nickname_page.dart';
import 'package:tronskins_app/pages/user/setting/edit_password_page.dart';
import 'package:tronskins_app/pages/user/guard/twofa_token_page.dart';
import 'package:tronskins_app/pages/user/my_collection_page.dart';
import 'package:tronskins_app/pages/notify/notice_detail_page.dart';
import 'package:tronskins_app/pages/notify/trade_notice_detail_page.dart';
import 'package:tronskins_app/pages/help/help_center_page.dart';
import 'package:tronskins_app/pages/help/help_category_page.dart';
import 'package:tronskins_app/pages/help/help_detail_page.dart';
import 'package:tronskins_app/pages/help/feedback_list_page.dart';
import 'package:tronskins_app/pages/help/feedback_detail_page.dart';
import 'package:tronskins_app/pages/help/feedback_create_page.dart';
import 'package:tronskins_app/pages/system/server_list_page.dart';
import 'package:tronskins_app/pages/system/auth_test_page.dart';
import 'package:tronskins_app/pages/system/about_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_flow_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_locked_detail_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_locked_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_recharge_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_recharge_record_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_settlement_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_withdraw_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_withdraw_record_page.dart';
import 'package:tronskins_app/pages/wallet/wallet_integral_record_page.dart';
import 'package:tronskins_app/pages/integral/integral_page.dart';
import 'package:tronskins_app/pages/integral/integral_draw_page.dart';
import 'package:tronskins_app/pages/coupon/coupon_page.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:tronskins_app/pages/user/setting/index.dart';
import 'package:tronskins_app/pages/user/message.dart';

class RoutersConfig {
  static List<GetPage> list = [
    GetPage(
      name: Routers.HOME,
      page: () => NavBarPage(),
      binding: UserBinding(),
      transition: Transition.fade,
    ),
    GetPage(name: Routers.USER_COLLECTION, page: () => MyCollectionPage()),
    GetPage(name: Routers.USER_SETTING, page: () => UserSetting()),
    GetPage(name: Routers.USER_SETTING_RATE, page: () => ExchangeRatePage()),
    GetPage(name: Routers.USER_EDIT_NICKNAME, page: () => EditNicknamePage()),
    GetPage(name: Routers.USER_EDIT_PASSWORD, page: () => EditPasswordPage()),
    GetPage(name: Routers.USER_GUARD, page: () => TwoFaTokenPage()),
    GetPage(name: Routers.MESSAGE, page: () => UserMessage()),
    GetPage(name: Routers.NOTICE_DETAIL, page: () => NoticeDetailPage()),
    GetPage(
      name: Routers.TRADE_NOTICE_DETAIL,
      page: () => TradeNoticeDetailPage(),
    ),
    GetPage(name: Routers.HELP_CENTER, page: () => HelpCenterPage()),
    GetPage(name: Routers.HELP_CATEGORY, page: () => HelpCategoryPage()),
    GetPage(name: Routers.HELP_DETAIL, page: () => HelpDetailPage()),
    GetPage(name: Routers.FEEDBACK_LIST, page: () => FeedbackListPage()),
    GetPage(name: Routers.FEEDBACK_DETAIL, page: () => FeedbackDetailPage()),
    GetPage(name: Routers.FEEDBACK_CREATE, page: () => FeedbackCreatePage()),
    GetPage(name: Routers.USER_SETTING_SERVER, page: () => ServerListPage()),
    GetPage(name: Routers.USER_ABOUT, page: () => AboutPage()),
    GetPage(name: Routers.USER_AUTH_TEST, page: () => AuthTestPage()),
    GetPage(name: Routers.LOGIN, page: () => LoginScreen()),
    GetPage(name: Routers.FORGET_PASSWORD, page: () => ForgetPasswordPage()),
    GetPage(name: Routers.TOKEN_RECOVERY, page: () => TokenRecoveryPage()),
    GetPage(name: Routers.STEAM_LOGIN, page: () => SteamLoginPage()),
    GetPage(name: Routers.STEAM_SETTING, page: () => SteamSettingPage()),
    GetPage(name: Routers.STEAM_BIND, page: () => BindSteamPage()),
    GetPage(name: Routers.STEAM_UNBIND, page: () => UnbindSteamPage()),
    GetPage(
      name: Routers.STEAM_INVENTORY_SETTING,
      page: () => InventorySettingPage(),
    ),
    GetPage(name: Routers.STEAM_TRADE_URL, page: () => SteamTradeUrlPage()),
    GetPage(name: Routers.STEAM_API_KEY, page: () => SteamApiKeyPage()),
    GetPage(name: Routers.STEAM_SESSION, page: () => SteamSessionPage()),
    GetPage(name: Routers.MARKET_DETAIL, page: () => MarketDetailPage()),
    GetPage(
      name: Routers.MARKET_ITEM_DETAIL,
      page: () => MarketItemDetailPage(),
    ),
    GetPage(name: Routers.SHOP_SETTING, page: () => ShopSettingPage()),
    GetPage(name: Routers.SHOP_RENAME, page: () => ShopRenamePage()),
    GetPage(name: Routers.SHOP_PRICE_CHANGE, page: () => ShopPriceChangePage()),
    GetPage(name: Routers.SHOP_ORDER_DETAIL, page: () => ShopOrderDetailPage()),
    GetPage(name: Routers.INVENTORY_UPSHOP, page: () => InventoryUpShopPage()),
    GetPage(name: Routers.SHOP_PURCHASE, page: () => MyPurchasePage()),
    GetPage(name: Routers.BUYING, page: () => BuyingPage()),
    GetPage(
      name: Routers.BUYING_UPDATE_PRICE,
      page: () => BuyingUpdatePricePage(),
    ),
    GetPage(name: Routers.PURCHASE_SETTING, page: () => PurchaseSettingPage()),
    GetPage(name: Routers.PRODUCT_BUYING, page: () => ProductBuyingPage()),
    GetPage(name: Routers.BULK_BUYING, page: () => BulkBuyingPage()),
    GetPage(name: Routers.BUYING_SUPPLY, page: () => BuyingSupplyPage()),
    GetPage(name: Routers.RECEIVE_GOODS, page: () => ReceiveGoodsPage()),
    GetPage(name: Routers.BALANCE_DETAIL, page: () => WalletPage()),
    GetPage(name: Routers.WALLET, page: () => WalletPage()),
    GetPage(name: Routers.WALLET_RECHARGE, page: () => WalletRechargePage()),
    GetPage(name: Routers.WALLET_WITHDRAW, page: () => WalletWithdrawPage()),
    GetPage(name: Routers.WALLET_FLOW, page: () => WalletFlowPage()),
    GetPage(name: Routers.WALLET_LOCKED, page: () => WalletLockedPage()),
    GetPage(
      name: Routers.WALLET_LOCKED_DETAIL,
      page: () => WalletLockedDetailPage(),
    ),
    GetPage(
      name: Routers.WALLET_RECHARGE_RECORD,
      page: () => WalletRechargeRecordPage(),
    ),
    GetPage(
      name: Routers.WALLET_WITHDRAW_RECORD,
      page: () => WalletWithdrawRecordPage(),
    ),
    GetPage(
      name: Routers.WALLET_INTEGRAL_RECORD,
      page: () => WalletIntegralRecordPage(),
    ),
    GetPage(
      name: Routers.WALLET_SETTLEMENT,
      page: () => WalletSettlementPage(),
    ),
    GetPage(name: Routers.INTEGRAL, page: () => IntegralPage()),
    GetPage(name: Routers.INTEGRAL_DRAW, page: () => IntegralDrawPage()),
    GetPage(name: Routers.COUPON, page: () => CouponPage()),
  ];
}
