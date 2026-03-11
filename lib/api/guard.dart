import 'package:tronskins_app/api/model/user/guard_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiGuardServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<GuardStatus>> guardStatus() async {
    final response = await http.get('api/app/user/validate');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GuardStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<GuardInfo>> guardInfo({
    required String emailCode,
  }) async {
    final response = await http.post('api/app/auth-token/$emailCode/bindapp');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => GuardInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<dynamic>> bindGuard({required String code}) async {
    final response = await http.post('api/app/auth-token/$code/bind');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> sendEmailCodeSubmit() async {
    Future<BaseHttpResponse<dynamic>> doRequest({
      required bool rawAuthorization,
      required bool skipCookie,
    }) async {
      final response = await http.get(
        'api/app/user/email/token/captcha',
        rawAuthorization: rawAuthorization,
        skipCookie: skipCookie,
      );
      return BaseHttpResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    }

    final first = await doRequest(rawAuthorization: true, skipCookie: false);
    final firstData = first.datas;
    final firstDataString = firstData == null ? '' : firstData.toString();
    if (first.success) {
      return first;
    }

    final needFallback =
        first.code == -1 &&
        firstDataString.isNotEmpty &&
        firstDataString.toLowerCase() == 'error';
    if (!needFallback) {
      return first;
    }

    final second = await doRequest(rawAuthorization: true, skipCookie: true);
    if (second.success) {
      return second;
    }

    return doRequest(rawAuthorization: false, skipCookie: true);
  }
}
