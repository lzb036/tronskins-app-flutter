import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiSteamServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<String>> getTemporaryToken() async {
    final response = await http.get('api/app/user/get/token');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json?.toString() ?? '',
    );
  }

  Future<BaseHttpResponse<bool>> steamOnlineState() async {
    final response = await http.get('api/app/steam/online/state');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _asBool(json),
    );
  }

  Future<BaseHttpResponse<bool>> steamTradingState() async {
    final response = await http.get('api/app/steam/trade_status/state');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _asBool(json),
    );
  }

  Future<BaseHttpResponse<String>> steamUnbindCheck() async {
    final response = await http.get('api/app/user/steam/unbind/check');
    final raw = response.data as Map<String, dynamic>;
    final code =
        raw['code'] as int? ??
        raw['statusCode'] as int? ??
        raw['status'] as int? ??
        200;
    final message = (raw['message'] ?? raw['msg'] ?? raw['datas'] ?? '')
        .toString();
    final datas = raw['datas']?.toString();
    return BaseHttpResponse<String>(code: code, message: message, datas: datas);
  }

  Future<BaseHttpResponse<dynamic>> setTradeUrl({
    required String tradeUrl,
  }) async {
    final response = await http.post(
      'api/app/user/set/url',
      data: {'tradeUrl': tradeUrl},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> setApiKey({
    required String accessKey,
  }) async {
    final response = await http.post(
      'api/app/user/set/key',
      data: {'accessKey': accessKey},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> getTradeUrlOrApiKey({
    required String type,
    Map<String, dynamic>? params,
  }) async {
    final response = await http.get(
      'api/app/steam/$type/get',
      queryParameters: params,
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<bool>> getSteamSetPrivacy() async {
    final response = await http.get('api/app/steam/get_privacy');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _asBool(json),
    );
  }

  Future<BaseHttpResponse<dynamic>> steamTokenFresh({
    required String steamId,
    required String freshToken,
  }) async {
    final response = await http.post(
      'api/app/steam/auth/token/fresh',
      data: {'steamId': steamId, 'freshToken': freshToken},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<Map<String, dynamic>>> getSteamUserInfo({
    required String id,
  }) async {
    final response = await http.post('api/app/steam/refresh/$id/steam/level');
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
      return {'_message': json?.toString() ?? ''};
    });
  }

  Future<BaseHttpResponse<String>> decryptSteamPassword({
    required String account,
    required String password,
    required String publicKeyMod,
    required String publicKeyExp,
  }) async {
    final response = await http.post(
      'api/app/steam/decrypt_password',
      data: {
        'account': account,
        'password': password,
        'publickey_mod': publicKeyMod,
        'publickey_exp': publicKeyExp,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as Map<String, dynamic>)['password']?.toString() ?? '',
    );
  }
}

bool _asBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}
