// ignore_for_file: file_names

class LoginParams {
  final String username;
  final String password;
  final String? udid;
  final bool? rememberMe;
  final String? code;
  final int? verifyType;
  final String? authToken;

  LoginParams({
    required this.username,
    required this.password,
    this.udid,
    this.rememberMe,
    this.code,
    this.verifyType,
    this.authToken,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{"username": username, "password": password};
    if (udid != null && udid!.isNotEmpty) {
      data["udid"] = udid;
    }
    if (rememberMe != null) {
      data["rememberMe"] = rememberMe;
    }
    if (code != null && code!.isNotEmpty) {
      data["code"] = code;
    }
    if (verifyType != null) {
      data["verifyType"] = verifyType;
    }
    if (authToken != null && authToken!.isNotEmpty) {
      data["authToken"] = authToken;
    }
    return data;
  }
}
