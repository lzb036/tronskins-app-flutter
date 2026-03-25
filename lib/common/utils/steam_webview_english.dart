import 'package:webview_flutter/webview_flutter.dart';

class SteamWebViewEnglish {
  static const String _steamLanguage = 'english';
  static const Map<String, String> requestHeaders = <String, String>{
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static Future<void> apply(WebViewCookieManager cookieManager) async {
    for (final domain in <String>['steamcommunity.com']) {
      try {
        await cookieManager.setCookie(
          WebViewCookie(
            name: 'Steam_Language',
            value: _steamLanguage,
            domain: domain,
            path: '/',
          ),
        );
      } catch (_) {}
    }
  }

  static Uri ensureEnglishUri(String rawUrl) =>
      ensureEnglishUriFromUri(Uri.parse(rawUrl));

  static Uri ensureEnglishUriFromUri(Uri uri) {
    if (!uri.host.toLowerCase().contains('steamcommunity.com')) {
      return uri;
    }

    final params = Map<String, String>.from(uri.queryParameters);
    params['l'] = _steamLanguage;
    return uri.replace(queryParameters: params);
  }

  static Future<void> load(
    WebViewController controller,
    WebViewCookieManager cookieManager,
    String rawUrl,
  ) async {
    await apply(cookieManager);
    await controller.loadRequest(
      ensureEnglishUri(rawUrl),
      headers: requestHeaders,
    );
  }
}
