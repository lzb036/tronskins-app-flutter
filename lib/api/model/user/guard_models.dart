class GuardStatus {
  final String? email;
  final bool? twoFa;

  const GuardStatus({this.email, this.twoFa});

  factory GuardStatus.fromJson(Map<String, dynamic> json) {
    return GuardStatus(
      email: json['email']?.toString(),
      twoFa: json['twoFa'] == true || json['two_fa'] == true,
    );
  }
}

class GuardInfo {
  final String? userId;
  final String? appUse;
  final String? secret;
  final String? showEmail;
  final String? loggerShowName;

  const GuardInfo({
    this.userId,
    this.appUse,
    this.secret,
    this.showEmail,
    this.loggerShowName,
  });

  factory GuardInfo.fromJson(Map<String, dynamic> json) {
    return GuardInfo(
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      appUse: json['appUse']?.toString() ?? json['app_use']?.toString(),
      secret: json['secret']?.toString(),
      showEmail:
          json['showEmail']?.toString() ?? json['show_email']?.toString(),
      loggerShowName:
          json['loggerShowName']?.toString() ??
          json['logger_show_name']?.toString(),
    );
  }
}
