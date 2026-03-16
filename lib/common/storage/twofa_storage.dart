import 'dart:convert';

import 'package:otp/otp.dart';
import 'package:tronskins_app/common/security/secure_storage.dart';

class TwoFactorToken {
  final String server;
  final String appUse;
  final String userId;
  final String secret;
  final String showEmail;

  const TwoFactorToken({
    required this.server,
    required this.appUse,
    required this.userId,
    required this.secret,
    required this.showEmail,
  });

  factory TwoFactorToken.fromJson(Map<String, dynamic> json) {
    return TwoFactorToken(
      server: json['server']?.toString() ?? '',
      appUse: json['appUse']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      secret: json['secret']?.toString() ?? '',
      showEmail: json['showEmail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': server,
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

  static String _normalizeText(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  static String _normalizeServer(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  static bool _matchesServer(
    TwoFactorToken token,
    String normalizedServer, {
    bool allowLegacy = false,
  }) {
    final tokenServer = _normalizeServer(token.server);
    if (tokenServer.isEmpty) {
      return allowLegacy;
    }
    return tokenServer == normalizedServer;
  }

  static int _findIndex(
    List<TwoFactorToken> list, {
    required String appUse,
    required String userId,
    required String server,
  }) {
    final normalizedServer = _normalizeServer(server);
    final exactIndex = list.indexWhere(
      (item) =>
          item.appUse == appUse &&
          item.userId == userId &&
          _matchesServer(item, normalizedServer),
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }
    if (normalizedServer.isEmpty) {
      return -1;
    }
    return list.indexWhere(
      (item) =>
          item.appUse == appUse &&
          item.userId == userId &&
          _matchesServer(item, normalizedServer, allowLegacy: true),
    );
  }

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
    String server = '',
    required String appUse,
    required String userId,
    required String secret,
    String showEmail = '',
  }) async {
    final list = await getList();
    final normalizedServer = _normalizeServer(server);
    final index = _findIndex(
      list,
      appUse: appUse,
      userId: userId,
      server: normalizedServer,
    );
    final token = TwoFactorToken(
      server: normalizedServer,
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
    String server = '',
    required String appUse,
    required String userId,
    String showEmail = '',
  }) async {
    final list = await getList();
    final normalizedServer = _normalizeServer(server);
    final index = _findIndex(
      list,
      appUse: appUse,
      userId: userId,
      server: normalizedServer,
    );
    if (index >= 0) {
      final existing = list[index];
      if (_normalizeServer(existing.server) == normalizedServer) {
        return;
      }
      list[index] = TwoFactorToken(
        server: normalizedServer,
        appUse: existing.appUse,
        userId: existing.userId,
        secret: existing.secret,
        showEmail: existing.showEmail,
      );
      await setList(list);
      return;
    }
    list.add(
      TwoFactorToken(
        server: normalizedServer,
        appUse: appUse,
        userId: userId,
        secret: '',
        showEmail: showEmail,
      ),
    );
    await setList(list);
  }

  static Future<void> removeToken({
    String server = '',
    required String appUse,
    required String userId,
  }) async {
    final list = await getList();
    final index = _findIndex(
      list,
      appUse: appUse,
      userId: userId,
      server: server,
    );
    if (index >= 0) {
      list.removeAt(index);
      await setList(list);
    }
  }

  static Future<void> removePendingTokenEntry({
    String server = '',
    required String appUse,
    required String userId,
  }) async {
    final list = await getList();
    final index = _findIndex(
      list,
      appUse: appUse,
      userId: userId,
      server: server,
    );
    if (index >= 0 && list[index].secret.trim().isEmpty) {
      list.removeAt(index);
      await setList(list);
    }
  }

  static Future<TwoFactorToken?> findToken({
    String server = '',
    required String appUse,
    required String userId,
  }) async {
    final list = await getList();
    final index = _findIndex(
      list,
      appUse: appUse,
      userId: userId,
      server: server,
    );
    if (index < 0) {
      return null;
    }
    return list[index];
  }

  static Future<TwoFactorToken?> findStoredTokenForLogin({
    String server = '',
    String appUse = '',
    String userId = '',
    String showEmail = '',
    String loginAccount = '',
  }) async {
    final tokens = (await getList())
        .where((item) => item.secret.trim().isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return null;
    }

    final normalizedServer = _normalizeServer(server);
    final normalizedUserId = userId.trim();
    final normalizedAppUse = _normalizeText(appUse);
    if (normalizedUserId.isNotEmpty && normalizedAppUse.isNotEmpty) {
      for (final token in tokens) {
        if (token.userId.trim() == normalizedUserId &&
            _normalizeText(token.appUse) == normalizedAppUse &&
            _matchesServer(token, normalizedServer)) {
          return token;
        }
      }
      if (normalizedServer.isNotEmpty) {
        for (final token in tokens) {
          if (token.userId.trim() == normalizedUserId &&
              _normalizeText(token.appUse) == normalizedAppUse &&
              _matchesServer(token, normalizedServer, allowLegacy: true)) {
            return token;
          }
        }
      }
    }

    final emails = <String>{
      _normalizeText(showEmail),
      _normalizeText(loginAccount),
    }..removeWhere((item) => item.isEmpty);

    for (final email in emails) {
      final emailMatches = tokens
          .where((item) => _normalizeText(item.showEmail) == email)
          .toList();
      if (emailMatches.isEmpty) {
        continue;
      }

      if (normalizedServer.isNotEmpty) {
        final serverMatches = emailMatches
            .where((item) => _matchesServer(item, normalizedServer))
            .toList();
        if (normalizedAppUse.isNotEmpty) {
          final appUseMatches = serverMatches
              .where((item) => _normalizeText(item.appUse) == normalizedAppUse)
              .toList();
          if (appUseMatches.length == 1) {
            return appUseMatches.first;
          }
        } else if (serverMatches.length == 1) {
          return serverMatches.first;
        }

        final legacyMatches = emailMatches
            .where(
              (item) =>
                  _matchesServer(item, normalizedServer, allowLegacy: true),
            )
            .toList();
        if (normalizedAppUse.isNotEmpty) {
          final appUseMatches = legacyMatches
              .where((item) => _normalizeText(item.appUse) == normalizedAppUse)
              .toList();
          if (appUseMatches.length == 1) {
            return appUseMatches.first;
          }
        } else if (legacyMatches.length == 1) {
          return legacyMatches.first;
        }
      }

      if (normalizedAppUse.isNotEmpty) {
        final appUseMatches = emailMatches
            .where((item) => _normalizeText(item.appUse) == normalizedAppUse)
            .toList();
        if (appUseMatches.length == 1) {
          return appUseMatches.first;
        }
      } else if (emailMatches.length == 1) {
        return emailMatches.first;
      }
    }

    return null;
  }
}

class TwoFactorHelper {
  static String generateCode(String secret) {
    final normalizedSecret = secret.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalizedSecret.isEmpty) {
      return '';
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      return OTP.generateTOTPCodeString(
        normalizedSecret,
        now,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (_) {
      try {
        return OTP.generateTOTPCodeString(
          normalizedSecret,
          now,
          interval: 30,
          length: 6,
          algorithm: Algorithm.SHA1,
        );
      } catch (_) {
        return '';
      }
    }
  }

  static int remainingSeconds({int interval = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return interval - (now % interval);
  }
}
