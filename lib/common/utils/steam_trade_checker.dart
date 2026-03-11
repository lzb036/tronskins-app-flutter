import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Steam Trade Offer Checker
/// Similar to config/SteamCheckOffer.js in the uni-app version
///
/// Usage:
/// ```dart
/// final checker = SteamTradeChecker(
///   onConfirmationRequired: () { ... },
///   onError: (msg) { ... },
/// );
/// await checker.checkOffer('https://steamcommunity.com/tradeoffer/...');
/// ```
class SteamTradeChecker {
  final VoidCallback? onConfirmationRequired;
  final Function(String)? onError;
  final VoidCallback? onSuccess;

  SteamTradeChecker({
    this.onConfirmationRequired,
    this.onError,
    this.onSuccess,
  });

  /// Check trade offer status
  /// Returns true if confirmation is needed, false otherwise
  Future<bool> checkOffer(
    WebViewController controller,
    String tradeOfferUrl,
  ) async {
    try {
      // Check if URL is a trade offer page
      if (!tradeOfferUrl.contains('/tradeoffer/')) {
        return false;
      }

      // Load the trade offer page
      await controller.loadRequest(Uri.parse(tradeOfferUrl));

      // Wait for page to load and check for confirmation message
      return await _checkForConfirmation(controller);
    } catch (e) {
      onError?.call('Error checking trade offer: $e');
      return false;
    }
  }

  /// Inject JavaScript to check for confirmation message
  Future<bool> _checkForConfirmation(WebViewController controller) async {
    const script = '''
      (function() {
        // Check for confirmation message
        const confirmMsg = document.querySelector('#trade_confirm_message');
        const errorMsg = document.querySelector('#error_msg');
        
        if (confirmMsg) {
          // Check if title indicates additional confirmation needed
          const titleText = document.querySelector('.title_text');
          if (titleText && titleText.innerHTML.includes('需要额外确认')) {
            return 'CONFIRMATION_REQUIRED';
          }
          return 'HAS_CONFIRM_MSG';
        }
        
        if (errorMsg) {
          return 'ERROR';
        }
        
        return 'OK';
      })();
    ''';

    try {
      final result = await controller.runJavaScriptReturningResult(script);
      final resultStr = result.toString().replaceAll('"', '');

      switch (resultStr) {
        case 'CONFIRMATION_REQUIRED':
          onConfirmationRequired?.call();
          return true;
        case 'ERROR':
          onError?.call('Trade offer error');
          return false;
        case 'HAS_CONFIRM_MSG':
        case 'OK':
        default:
          onSuccess?.call();
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Inject continuous checking script (to be used with NavigationDelegate)
  String getContinuousCheckScript() {
    return '''
      (function() {
        if (window.__tradeCheckInjected) return;
        window.__tradeCheckInjected = true;

        let canCall = true;
        
        if (location.href && location.pathname.indexOf('/tradeoffer/') > -1) {
          const checkInterval = setInterval(() => {
            const confirmMsg = document.querySelector('#trade_confirm_message');
            const errorMsg = document.querySelector('#error_msg');
            
            if (confirmMsg || errorMsg) {
              clearInterval(checkInterval);
              
              if (confirmMsg) {
                const checkConfirmInterval = setInterval(() => {
                  const pp = document.querySelector('.title_text');
                  if (pp && pp.innerHTML === '需要额外确认' && canCall) {
                    // Send message to Flutter
                    if (window.TradeCheckChannel) {
                      window.TradeCheckChannel.postMessage('CONFIRMATION_REQUIRED');
                    }
                    canCall = false;
                    clearInterval(checkConfirmInterval);
                  }
                }, 800);
              } else {
                if (window.TradeCheckChannel) {
                  window.TradeCheckChannel.postMessage('ERROR');
                }
              }
            }
          }, 500);
        }
      })();
    ''';
  }
}

/// JavaScript channel handler for trade checking
class SteamTradeCheckChannel {
  static const String channelName = 'TradeCheckChannel';

  final Function(String) onMessage;

  SteamTradeCheckChannel({required this.onMessage});
}

/// Extension to simplify WebView setup for trade checking
extension SteamTradeWebViewExtension on WebViewController {
  /// Add JavaScript channel for trade checking
  void addSteamTradeCheckChannel(Function(String) onMessage) {
    addJavaScriptChannel(
      SteamTradeCheckChannel.channelName,
      onMessageReceived: (JavaScriptMessage message) {
        onMessage(message.message);
      },
    );
  }

  /// Inject trade checking script
  Future<void> injectTradeCheckScript() async {
    const script = '''
      (function() {
        if (window.__tradeCheckInjected) return;
        window.__tradeCheckInjected = true;

        let canCall = true;
        
        if (location.href && location.pathname.indexOf('/tradeoffer/') > -1) {
          const checkInterval = setInterval(() => {
            const confirmMsg = document.querySelector('#trade_confirm_message');
            const errorMsg = document.querySelector('#error_msg');
            
            if (confirmMsg || errorMsg) {
              clearInterval(checkInterval);
              
              if (confirmMsg) {
                const checkConfirmInterval = setInterval(() => {
                  const pp = document.querySelector('.title_text');
                  if (pp && (pp.innerHTML === '需要额外确认' || 
                      pp.innerHTML === 'Additional confirmation required' ||
                      pp.innerHTML.includes('确认')) && canCall) {
                    if (window.TradeCheckChannel) {
                      window.TradeCheckChannel.postMessage('CONFIRMATION_REQUIRED');
                    }
                    canCall = false;
                    clearInterval(checkConfirmInterval);
                  }
                }, 800);
              } else {
                if (window.TradeCheckChannel) {
                  window.TradeCheckChannel.postMessage('ERROR');
                }
              }
            }
          }, 500);
        }
      })();
    ''';
    await runJavaScript(script);
  }
}
