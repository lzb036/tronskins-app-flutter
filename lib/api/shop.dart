import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiShopServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<Map<String, dynamic>>> getUserShopInfo({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/public/shop/get', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<BaseHttpResponse<dynamic>> changeShopName({
    required String shopName,
  }) async {
    final response = await http.post(
      'api/app/myshop/name/set',
      data: {'name': shopName},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> changeShopStatus() async {
    final response = await http.post('api/app/myshop/online/change');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> changeAutoOffline({
    required bool openAutoClose,
  }) async {
    final response = await http.post(
      'api/app/myshop/open_auto_close/set',
      data: {'flag': openAutoClose},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> setAutoCloseTime({
    required int hour,
    required int minute,
  }) async {
    final response = await http.post(
      'api/app/myshop/auto_close_time/set',
      data: {'hour': hour, 'minute': minute},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopItemAsset>>> shopSellList({
    required int appId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.post(
      'api/app/shop/sell/$appId/list',
      data: {'appId': appId, 'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopItemAsset.fromJson,
        listKey: 'sells',
      ),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopItemAsset>>>
  shopTransactionList({int page = 1, int pageSize = 20}) async {
    final response = await http.post(
      'api/public/shop/sell/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopItemAsset.fromJson,
        listKey: 'list',
      ),
    );
  }
}
