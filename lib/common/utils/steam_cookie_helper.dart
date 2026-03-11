import 'dart:convert';
import 'package:dio/dio.dart';

/// Helper class to get Steam Cookie/Session information
/// Similar to utils/dq/steam.js in the uni-app version
class SteamCookieHelper {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// Get Steam info (steamId and sessionId) from inventory history page
  /// Returns null if not logged in or error occurs
  static Future<SteamCookieInfo?> getSteamInfo(String steamId) async {
    try {
      final url =
          'https://steamcommunity.com/profiles/$steamId/inventoryhistory';

      final response = await _dio.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.data == null) {
        return null;
      }

      final String html = response.data.toString();

      // Extract g_steamID
      final steamIdMatch = _extractSteamId(html);
      if (steamIdMatch == null) {
        return SteamCookieInfo(
          status: false,
          message: 'Steam account not logged in',
        );
      }

      // Check if steamId matches
      if (steamIdMatch != steamId) {
        // Extract sessionId even if mismatch
        final sessionId = _extractSessionId(html);
        return SteamCookieInfo(
          status: false,
          steamId: steamIdMatch,
          steamIdCookie: steamId,
          sessionId: sessionId,
          message: 'app.steam.message.account_inconsistent',
          isLoginSteam: true,
        );
      }

      // Extract g_sessionID
      final sessionId = _extractSessionId(html);

      return SteamCookieInfo(
        status: true,
        steamId: steamIdMatch,
        sessionId: sessionId,
        message: '',
      );
    } on DioException catch (e) {
      return SteamCookieInfo(
        status: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return SteamCookieInfo(status: false, message: 'Error: $e');
    }
  }

  /// Extract steamID from HTML content
  static String? _extractSteamId(String html) {
    // Try different patterns to find steamID
    String? result;

    // Pattern for g_steamID = "123" or g_steamID = '123' or g_steamID = 123
    // Using single quotes for outer string since pattern contains double quotes
    final regex1 = RegExp(r'g_steamID\s*=\s*["\x27]?([0-9]+)["\x27]?');
    final match1 = regex1.firstMatch(html);
    if (match1 != null) {
      result = match1.group(1);
      if (result != null && result != 'false') return result;
    }

    // Pattern for g_steamID: "123" or g_steamID: '123'
    final regex2 = RegExp(r'g_steamID\s*:\s*["\x27]?([0-9]+)["\x27]?');
    final match2 = regex2.firstMatch(html);
    if (match2 != null) {
      result = match2.group(1);
      if (result != null && result != 'false') return result;
    }

    // Pattern for "steamid": "123"
    final regex3 = RegExp(r'"steamid"\s*:\s*["\x27]?([0-9]+)["\x27]?');
    final match3 = regex3.firstMatch(html);
    if (match3 != null) {
      result = match3.group(1);
      if (result != null && result != 'false') return result;
    }

    // Check for false value (not logged in)
    if (html.contains('g_steamID = false')) return null;
    if (html.contains('g_steamID: false')) return null;

    return null;
  }

  /// Extract sessionID from HTML content
  static String? _extractSessionId(String html) {
    String? result;

    // Pattern for g_sessionID = "abc" or g_sessionID = 'abc'
    final regex1 = RegExp(r'g_sessionID\s*=\s*["\x27]([^"\x27]+)["\x27]');
    final match1 = regex1.firstMatch(html);
    if (match1 != null) {
      result = match1.group(1);
      if (result != null) return result;
    }

    // Pattern for g_sessionID: "abc" or g_sessionID: 'abc'
    final regex2 = RegExp(r'g_sessionID\s*:\s*["\x27]([^"\x27]+)["\x27]');
    final match2 = regex2.firstMatch(html);
    if (match2 != null) {
      result = match2.group(1);
      if (result != null) return result;
    }

    // Pattern for "sessionid": "abc"
    final regex3 = RegExp(r'"sessionid"\s*:\s*["\x27]([^"\x27]+)["\x27]');
    final match3 = regex3.firstMatch(html);
    if (match3 != null) {
      result = match3.group(1);
      if (result != null) return result;
    }

    return null;
  }

  /// Check if Steam session is valid by making a request to inventory page
  static Future<bool> isSessionValid(String steamId) async {
    final info = await getSteamInfo(steamId);
    return info?.status ?? false;
  }

  /// Get Steam cookies from WebView (to be used with WebView cookie manager)
  static Future<Map<String, String>> getCookiesForDomain(String domain) async {
    // This would need to be implemented with WebView cookie manager
    // For now, return empty map
    return {};
  }
}

/// Model for Steam Cookie Info
class SteamCookieInfo {
  final bool status;
  final String? sessionId;
  final String? steamId;
  final String? steamIdCookie;
  final String message;
  final bool isLoginSteam;

  SteamCookieInfo({
    required this.status,
    this.sessionId,
    this.steamId,
    this.steamIdCookie,
    required this.message,
    this.isLoginSteam = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'sessionId': sessionId,
      'steamId': steamId,
      'steamIdCookie': steamIdCookie,
      'message': message,
      'isLoginSteam': isLoginSteam,
    };
  }

  @override
  String toString() {
    return 'SteamCookieInfo(${jsonEncode(toJson())})';
  }
}
