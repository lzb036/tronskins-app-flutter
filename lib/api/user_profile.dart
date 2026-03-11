import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiUserProfileServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<dynamic>> editNickname({
    required String nickname,
  }) async {
    final response = await http.post(
      'api/app/user/set/nickname',
      data: {'nickname': nickname},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> editPassword({
    required String id,
    required String password,
    required String newPassword,
  }) async {
    final response = await http.post(
      'api/app/user/set/password',
      data: {'id': id, 'password': password, 'newPassword': newPassword},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }
}
