import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/model/market/market_filter_models.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiMarketServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<List<MarketItemEntity>>> marketNews({
    required int appId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      'api/public/mall/sell/$appId/news',
      data: {
        'appId': appId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(MarketItemEntity.fromJson)
          .toList(),
    );
  }

  Future<BaseHttpResponse<List<MarketItemEntity>>> marketHotItems({
    required int appId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.post(
      'api/public/mall/hots',
      data: {
        'appId': appId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(MarketItemEntity.fromJson)
          .toList(),
    );
  }

  Future<BaseHttpResponse<MarketSchemaListResponse>> marketGameList({
    required int appId,
    int page = 1,
    int pageSize = 20,
    String? field,
    bool? asc,
    String? keywords,
    String? itemName,
    Map<String, dynamic>? tags,
    double? minPrice,
    double? maxPrice,
  }) async {
    final response = await http.post(
      'api/public/mall/$appId/schemas',
      data: {
        'appId': appId,
        'page': page,
        'pageSize': pageSize,
        'field': field,
        'asc': asc,
        'keywords': keywords,
        'itemName': itemName,
        'tags': tags,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      }..removeWhere((key, value) => value == null || value == ''),
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketSchemaListResponse.fromJson(
        json as Map<String, dynamic>,
      ),
    );
  }

  Future<BaseHttpResponse<List<MarketNameSuggestion>>> marketQueryItemName({
    required int appId,
    required String keywords,
  }) async {
    final response = await http.post(
      'api/public/schema/item/language/list',
      data: {
        'appId': appId,
        'keywords': keywords,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(MarketNameSuggestion.fromJson)
          .toList(),
    );
  }

  Future<BaseHttpResponse<MarketAttributePayload>> marketAttributeList({
    required int appId,
  }) async {
    final response = await http.get(
      'api/public/schema/attribute/$appId/list',
      queryParameters: {'appId': appId},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketAttributePayload.fromJson(
        json as Map<String, dynamic>,
      ),
    );
  }

  Future<BaseHttpResponse<MarketListResponse>> onSaleList({
    required int appId,
    required int schemaId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.post(
      'api/app/order/sell/details/list',
      data: {
        'appId': appId,
        'schemaId': schemaId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketListResponse.fromJson(
        json as Map<String, dynamic>,
        listKey: 'sells',
      ),
    );
  }

  Future<BaseHttpResponse<MarketListResponse>> transactionList({
    required int appId,
    required int schemaId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      'api/public/sell/record/list',
      data: {
        'appId': appId,
        'schemaId': schemaId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketListResponse.fromJson(
        json as Map<String, dynamic>,
        listKey: 'details',
      ),
    );
  }

  Future<BaseHttpResponse<MarketPriceTrendData>> priceTrend({
    required int appId,
    required String marketHashName,
    int days = 30,
    String market = 'steam',
    bool useAuth = false,
  }) async {
    final path = useAuth
        ? 'api/app/goods/price/history/list'
        : 'api/public/goods/price/history/list';
    final response = await http.post(
      path,
      data: {
        'appId': appId,
        'marketHashName': marketHashName,
        'days': days,
        'market': market,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketPriceTrendData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<MarketTemplateDetail>> marketTemplateDetail({
    required int appId,
    required int schemaId,
    bool useAuth = false,
  }) async {
    final path = useAuth
        ? 'api/app/goods/$appId/$schemaId/show'
        : 'api/public/goods/$appId/$schemaId/show';
    final response = await http.get(path);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MarketTemplateDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<ShopListResponse<BuyRequestItem>>> buyRequestList({
    required int appId,
    required int schemaId,
    int page = 1,
    int pageSize = 20,
    bool useAuth = false,
  }) async {
    final path = useAuth
        ? 'api/app/order/buy/details/list'
        : 'api/public/order/buy/details/list';
    final response = await http.post(
      path,
      data: {
        'appId': appId,
        'schemaId': schemaId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ShopListResponse.fromJson(
        json as Map<String, dynamic>,
        BuyRequestItem.fromJson,
        listKey: 'assets',
      ),
    );
  }

  Future<BaseHttpResponse<BuyRemainInfo>> buyRemainNum({
    required int schemaId,
  }) async {
    final response =
        await http.get('api/app/mall/tobuy/buynum/$schemaId/limit');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => BuyRemainInfo.fromJson(json as Map<String, dynamic>),
    );
  }
}
