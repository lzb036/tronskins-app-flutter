// ignore_for_file: file_names

import 'package:tronskins_app/api/model/loginModel.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';
import 'package:tronskins_app/api/model/loginRequest.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiLoginServer {
  final HttpHelper http = HttpHelper.getInstance();

  /// 登录
  Future<BaseHttpResponse<LoginEntity>> loginApi(LoginParams params) async {
    final response = await http.post('/api/app/auth', data: params.toJson());
    final raw = response.data as Map<String, dynamic>;
    final code = raw['code'] as int? ?? -1;
    final datasMessage = raw['datas'];
    final messageValue =
        raw['message'] ??
        raw['msg'] ??
        (datasMessage is String ? datasMessage : '');
    final message = messageValue is String
        ? messageValue
        : messageValue.toString();
    final rawDatas = raw['datas'];
    final LoginEntity? datas = rawDatas is Map<String, dynamic>
        ? LoginEntity.fromJson(rawDatas)
        : null;
    return BaseHttpResponse<LoginEntity>(
      code: code,
      message: message,
      datas: datas,
    );
  }

  /// 登录前获取公钥
  Future<BaseHttpResponse<String>> getLoginPubKey({
    required String username,
  }) async {
    final response = await http.post(
      '/api/public/app/user/pubKey',
      data: {'username': username},
    );
    final raw = response.data as Map<String, dynamic>;
    final code = raw['code'] as int? ?? -1;
    final messageValue = raw['message'] ?? raw['msg'] ?? '';
    final message = messageValue is String
        ? messageValue
        : messageValue.toString();
    final rawDatas = raw['datas'];
    final String? datas = rawDatas is String ? rawDatas : null;
    return BaseHttpResponse<String>(code: code, message: message, datas: datas);
  }

  /// 发送登录邮箱验证码
  Future<BaseHttpResponse<dynamic>> sendLoginEmailCode({
    required String email,
    required String authToken,
  }) async {
    final response = await http.post(
      '/api/public/verify-code/email/send/by-auth',
      data: {'email': email, 'authToken': authToken},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// 重置密码前邮箱校验
  Future<BaseHttpResponse<dynamic>> verifyResetEmail({
    required String email,
    String type = 'reset',
  }) async {
    final response = await http.get(
      '/api/public/user/email/verify',
      queryParameters: {'email': email, 'type': type},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// 发送邮箱验证码（提交类）
  Future<BaseHttpResponse<dynamic>> sendEmailCodeBySubmit({
    required String email,
    required int purpose,
  }) async {
    final response = await http.post(
      '/api/public/verify-code/email/send/by-submit',
      data: {'email': email, 'purpose': purpose},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// 重置密码
  Future<BaseHttpResponse<dynamic>> resetPassword({
    required String email,
    required String captcha,
  }) async {
    final response = await http.get(
      '/api/public/user/password/reset',
      queryParameters: {'email': email, 'captcha': captcha},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// 2FA 令牌遗失提交
  Future<BaseHttpResponse<dynamic>> tokenLostSubmit({
    required String username,
    required String password,
    required String code,
    int userType = 0,
  }) async {
    final response = await http.post(
      '/api/public/2fa/lost',
      data: {
        'username': username,
        'password': password,
        'code': code,
        'userType': userType,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// Steam SSO 登录
  Future<BaseHttpResponse<Map<String, dynamic>>> loginSsoSteam({
    required String callback,
    required String udid,
  }) async {
    final response = await http.post(
      '/api/public/sso/login_sso',
      data: {'callback': callback, 'udid': udid},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );
  }

  /// 退出
  Future<BaseHttpResponse<dynamic>> logoutApi() async {
    final response = await http.post('api/app/user/logout');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  /// 获取用户信息
  Future<BaseHttpResponse<UserInfoEntity>> getUserApi() async {
    final response = await http.get('/api/app/user/get');

    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserInfoEntity.fromJson(json as Map<String, dynamic>),
    );
  }
}
