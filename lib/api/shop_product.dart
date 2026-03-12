import 'package:tronskins_app/api/model/user/collection_models.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiShopProductServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<ShopListResponse<ShopItemAsset>>> shopOnSaleList({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/order/mysell/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopItemAsset.fromJson,
        listKey: 'sells',
      ),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopOrderItem>>> shopSellRecord({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/mysold/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopOrderItem.fromJson,
        listKey: 'records',
      ),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopOrderItem>>> shopBuyReceiving({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/myreceive/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopOrderItem.fromJson,
        listKey: 'sends',
      ),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopOrderItem>>> shopBuyRecord({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/mybuy/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopOrderItem.fromJson,
        listKey: 'records',
      ),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<ShopOrderItem>>>
  pendingShipmentList({required Map<String, dynamic> params}) async {
    final response = await http.post('api/app/mysend/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        ShopOrderItem.fromJson,
        listKey: 'sends',
      ),
    );
  }

  Future<BaseHttpResponse<dynamic>> cancelOrder({required String id}) async {
    final response = await http.post('api/app/shop/sell/$id/cancel');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> tradeofferReceipt({
    required String id,
  }) async {
    final response = await http.get('api/app/tradeoffer/$id/accept');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemUp({
    required int appId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      'api/app/order/sell/up',
      data: {'appId': appId, 'items': items},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemRemoved({
    required List<int> ids,
  }) async {
    final response = await http.post(
      'api/app/order/sell/down',
      data: {'ids': ids},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemChangePrice({
    required int appId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      'api/app/order/sell/price/change',
      data: {'appid': appId, 'items': items},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemPurchase({
    required int appId,
    required String id,
    required double price,
  }) async {
    final response = await http.post(
      'api/app/order/sell/action',
      data: {'appid': appId, 'id': id, 'price': price},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<ShopListResponse<BuyRequestItem>>> myBuyOrderList({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/order/mybuy/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        BuyRequestItem.fromJson,
        listKey: 'assets',
      ),
    );
  }

  Future<BaseHttpResponse<dynamic>> myBuyUpdatePrice({
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.request(
      'api/app/order/buy/price/change',
      method: 'PUT',
      data: {'items': items},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemCancelBuy({
    required String id,
  }) async {
    final response = await http.request(
      'api/app/order/buy/$id/down',
      method: 'PUT',
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemSupply({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.request(
      'api/app/order/buy/action',
      method: 'PUT',
      data: params,
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemBuying({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/order/buy/up', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> orderItemBatchBuy({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post(
      'api/app/order/sell/batch/buy',
      data: params,
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<CollectionListResponse<CollectionTemplateItem>>>
  productCollectList({required Map<String, dynamic> params}) async {
    final response = await http.post('api/app/collect/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => CollectionListResponse.fromJson(
        json as Map<String, dynamic>,
        CollectionTemplateItem.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<CollectionListResponse<CollectionFavoriteItem>>>
  productFavoriteList({required Map<String, dynamic> params}) async {
    final response = await http.post('api/app/favorite/list', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => CollectionListResponse.fromJson(
        json as Map<String, dynamic>,
        CollectionFavoriteItem.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<Map<String, dynamic>>> getSysParams() async {
    final response = await http.get('api/public/shop/params/get');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<BaseHttpResponse<double>> getOrderBuyingMinPrice({
    required int appId,
    required int schemaId,
  }) async {
    final response = await http.post(
      'api/app/order/buy/min_price/get',
      data: {'appId': appId, 'schemaId': schemaId},
    );
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is num) {
        return json.toDouble();
      }
      return double.tryParse(json?.toString() ?? '') ?? 0.0;
    });
  }

  Future<BaseHttpResponse<dynamic>> submitBuyStatus() async {
    final response = await http.post('api/app/myshop/signWanted/change');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }
}
