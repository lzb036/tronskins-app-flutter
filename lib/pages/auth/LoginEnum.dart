// ignore_for_file: file_names 登录方式枚举

enum LoginTypeEnum {
  // 0:未验证
  notVerify(0),
  // 1:QQ
  qq(1),
  // 2:2fa令牌
  guard(2),
  // 6:忘记密码

  forgetPassword(6);

  const LoginTypeEnum(this.value);
  final int value;
}
