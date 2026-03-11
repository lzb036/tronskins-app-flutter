import 'dart:convert';

import 'package:otp/otp.dart';
import 'package:tronskins_app/common/security/secure_storage.dart';

class TwoFactorToken {
  final String appUse;
  final String userId;
  final String secret;
  final String showEmail;

  const TwoFactorToken({
    required this.appUse,
    required this.userId,
    required this.secret,
    required this.showEmail,
  });

  factory TwoFactorToken.fromJson(Map<String, dynamic> json) {
    return TwoFactorToken(
      appUse: json['appUse']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      secret: json['secret']?.toString() ?? '',
      showEmail: json['showEmail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appUse': appUse,
      'userId': userId,
      'secret': secret,
      'showEmail': showEmail,
    };
  }
}

class TwoFactorStorage {
  TwoFactorStorage._();

  static const String _key = 'es_2fa_list';

  static Future<List<TwoFactorToken>> getList() async {
    final raw = await SecureStorage.getItem(_key);
    if (raw == null || raw.isEmpty) {
      return <TwoFactorToken>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TwoFactorToken.fromJson)
            .toList();
      }
    } catch (_) {}
    return <TwoFactorToken>[];
  }

  static Future<void> setList(List<TwoFactorToken> list) async {
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await SecureStorage.setItem(_key, raw);
  }

  static Future<void> bindSecret({
    required String appUse,
    required String userId,
    required String secret,
    String showEmail = '',
  }) async {
    final list = await getList();
    final index = list.indexWhere(
      (item) => item.appUse == appUse && item.userId == userId,
    );
    final token = TwoFactorToken(
      appUse: appUse,
      userId: userId,
      secret: secret,
      showEmail: showEmail,
    );
    if (index >= 0) {
      list[index] = token;
    } else {
      list.add(token);
    }
    await setList(list);
  }

  static Future<void> ensureTokenEntry({
    required String appUse,
    required String userId,
    String showEmail = '',
  }) async {
    final list = await getList();
    final exists = list.any(
      (item) => item.appUse == appUse && item.userId == userId,
    );
    if (exists) {
      return;
    }
    list.add(
      TwoFactorToken(
        appUse: appUse,
        userId: userId,
        secret: '',
        showEmail: showEmail,
      ),
    );
    await setList(list);
  }

  static Future<void> removeToken({
    required String appUse,
    required String userId,
  }) async {
    final list = await getList();
    list.removeWhere((item) => item.appUse == appUse && item.userId == userId);
    await setList(list);
  }

  static Future<TwoFactorToken?> findToken({
    required String appUse,
    required String userId,
  }) async {
    final list = await getList();
    try {
      return list.firstWhere(
        (item) => item.appUse == appUse && item.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }
}

class TwoFactorHelper {
  static String generateCode(String secret) {
    if (secret.isEmpty) {
      return '';
    }
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
    );
  }

  static int remainingSeconds({int interval = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return interval - (now % interval);
  }
}
