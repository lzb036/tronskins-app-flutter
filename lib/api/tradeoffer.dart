import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiTradeOfferServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<dynamic>> createTradeOffer({
    required Map<String, dynamic> params,
  }) async {
    final response = await http.post('api/app/tradeoffer/create', data: params);
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }
}
