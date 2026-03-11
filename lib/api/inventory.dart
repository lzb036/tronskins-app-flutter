import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiInventoryServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<InventoryResponse>> inventoryList({
    required int appId,
    int page = 1,
    int pageSize = 20,
    String? field,
    bool? asc,
    String? keywords,
    Map<String, dynamic>? tags,
    String? itemName,
    bool? canSellOnly,
    bool? canSupply,
    int? schemaId,
    int? status,
  }) async {
    final response = await http.post(
      'api/app/inventory/$appId/list',
      data: {
        'appId': appId,
        'page': page,
        'pageSize': pageSize,
        'field': field,
        'asc': asc,
        'keywords': keywords,
        'tags': tags,
        'itemName': itemName,
        'canSellOnly': canSellOnly,
        'canSupply': canSupply,
        'schemaId': schemaId,
        'status': status,
      }..removeWhere((key, value) => value == null || value == ''),
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => InventoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<dynamic>> inventoryRefresh({
    required int appId,
  }) async {
    final response = await http.post('api/app/inventory/$appId/fresh');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> inventoryPrivacySetting() async {
    final response = await http.get('api/app/steam/set_privacy');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }
}
