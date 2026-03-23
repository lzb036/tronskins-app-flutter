import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/steam_auth.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/controllers/auth/steam_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.testMode = true;
  });

  group('SteamSessionController', () {
    test('startLogin enters verification flow after session begins', () async {
      final steamApi = _FakeSteamApi();
      final authClient = _FakeSteamAuthClient();
      final controller = SteamSessionController(
        steamApi: steamApi,
        authClient: authClient,
        pollInterval: const Duration(milliseconds: 20),
        maxPollAttempts: 2,
      );

      controller.accountController.text = 'steam-user';
      controller.passwordController.text = 'steam-pass';

      await controller.startLogin();

      expect(controller.isAwaitingVerification.value, isTrue);
      expect(controller.isCodeDialogVisible.value, isTrue);
      expect(controller.errorMessage.value, isEmpty);
      expect(authClient.beginAuthSessionCalls, 1);

      controller.onClose();
      await Future<void>.delayed(const Duration(milliseconds: 25));
    });

    test(
      'submitCode completes verification when refresh token is returned directly',
      () async {
        final steamApi = _FakeSteamApi();
        final authClient = _FakeSteamAuthClient()
          ..updateCodeResponse = {
            'response': {'refresh_token': 'refresh-from-code'},
          };
        final controller = SteamSessionController(
          steamApi: steamApi,
          authClient: authClient,
          pollInterval: const Duration(milliseconds: 20),
          maxPollAttempts: 2,
        );

        controller.accountController.text = 'steam-user';
        controller.passwordController.text = 'steam-pass';
        await controller.startLogin();

        controller.codeController.text = 'abc12';
        await controller.submitCode();

        expect(controller.verificationSucceeded.value, isTrue);
        expect(controller.isAwaitingVerification.value, isFalse);
        expect(controller.accountController.text, isEmpty);
        expect(controller.passwordController.text, isEmpty);
        expect(steamApi.lastFreshToken, 'refresh-from-code');

        controller.onClose();
        await Future<void>.delayed(const Duration(milliseconds: 25));
      },
    );

    test(
      'submitCode keeps waiting state until polling returns refresh token',
      () async {
        final steamApi = _FakeSteamApi();
        final authClient = _FakeSteamAuthClient()
          ..pollResponses.addAll([
            {'response': <String, dynamic>{}},
            {
              'response': {'refresh_token': 'refresh-from-delayed-poll'},
            },
          ]);
        final controller = SteamSessionController(
          steamApi: steamApi,
          authClient: authClient,
          pollInterval: const Duration(milliseconds: 30),
          maxPollAttempts: 3,
        );

        controller.accountController.text = 'steam-user';
        controller.passwordController.text = 'steam-pass';
        await controller.startLogin();

        controller.codeController.text = 'ABC12';
        await controller.submitCode();

        expect(controller.isCodeSubmitting.value, isFalse);
        expect(controller.isWaitingForVerificationResult.value, isTrue);
        expect(controller.verificationSucceeded.value, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 45));

        expect(controller.verificationSucceeded.value, isTrue);
        expect(controller.isWaitingForVerificationResult.value, isFalse);
        expect(steamApi.lastFreshToken, 'refresh-from-delayed-poll');

        controller.onClose();
      },
    );

    test('polling can complete verification without code submission', () async {
      final steamApi = _FakeSteamApi();
      final authClient = _FakeSteamAuthClient()
        ..pollResponses.add({
          'response': {'refresh_token': 'refresh-from-poll'},
        });
      final controller = SteamSessionController(
        steamApi: steamApi,
        authClient: authClient,
        pollInterval: const Duration(milliseconds: 1),
        maxPollAttempts: 2,
      );

      controller.accountController.text = 'steam-user';
      controller.passwordController.text = 'steam-pass';
      await controller.startLogin();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.verificationSucceeded.value, isTrue);
      expect(controller.isAwaitingVerification.value, isFalse);
      expect(steamApi.lastFreshToken, 'refresh-from-poll');

      controller.onClose();
    });

    test(
      'token refresh failure clears credentials and keeps verification unsuccessful',
      () async {
        final steamApi = _FakeSteamApi()
          ..tokenFreshResponse = BaseHttpResponse<dynamic>(
            code: 500,
            message: 'refresh failed',
            datas: 'unbind steam',
          );
        final authClient = _FakeSteamAuthClient()
          ..updateCodeResponse = {
            'response': {'refresh_token': 'refresh-from-code'},
          };
        final controller = SteamSessionController(
          steamApi: steamApi,
          authClient: authClient,
          pollInterval: const Duration(milliseconds: 20),
          maxPollAttempts: 2,
        );

        controller.accountController.text = 'steam-user';
        controller.passwordController.text = 'steam-pass';
        await controller.startLogin();

        controller.codeController.text = 'ZZ999';
        await controller.submitCode();

        expect(controller.verificationSucceeded.value, isFalse);
        expect(controller.isAwaitingVerification.value, isFalse);
        expect(controller.accountController.text, isEmpty);
        expect(controller.passwordController.text, isEmpty);
        expect(controller.errorMessage.value, 'app.steam.message.unbind');

        controller.onClose();
        await Future<void>.delayed(const Duration(milliseconds: 25));
      },
    );
  });
}

class _FakeSteamApi extends ApiSteamServer {
  BaseHttpResponse<String> decryptResponse = BaseHttpResponse<String>(
    code: 200,
    message: '',
    datas: 'encrypted-password',
  );
  BaseHttpResponse<dynamic> tokenFreshResponse = BaseHttpResponse<dynamic>(
    code: 200,
    message: '',
    datas: null,
  );
  String? lastSteamId;
  String? lastFreshToken;

  @override
  Future<BaseHttpResponse<String>> decryptSteamPassword({
    required String account,
    required String password,
    required String publicKeyMod,
    required String publicKeyExp,
  }) async {
    return decryptResponse;
  }

  @override
  Future<BaseHttpResponse<dynamic>> steamTokenFresh({
    required String steamId,
    required String freshToken,
  }) async {
    lastSteamId = steamId;
    lastFreshToken = freshToken;
    return tokenFreshResponse;
  }
}

class _FakeSteamAuthClient extends SteamAuthClient {
  _FakeSteamAuthClient();

  Map<String, dynamic> passwordKeyResponse = {
    'response': {
      'publickey_mod': 'mod',
      'publickey_exp': 'exp',
      'timestamp': 'time',
    },
  };
  Map<String, dynamic> beginSessionResponse = {
    'response': {
      'client_id': 'client-id',
      'request_id': 'request-id',
      'steamid': 'steam-id',
    },
  };
  Map<String, dynamic> updateCodeResponse = {'response': <String, dynamic>{}};
  final Queue<Map<String, dynamic>> pollResponses =
      Queue<Map<String, dynamic>>();
  int beginAuthSessionCalls = 0;

  @override
  Future<Map<String, dynamic>> getPasswordKey(String accountName) async {
    return passwordKeyResponse;
  }

  @override
  Future<Map<String, dynamic>> beginAuthSession(
    Map<String, dynamic> data,
  ) async {
    beginAuthSessionCalls += 1;
    return beginSessionResponse;
  }

  @override
  Future<Map<String, dynamic>> updateAuthSessionWithSteamGuardCode(
    Map<String, dynamic> data,
  ) async {
    return updateCodeResponse;
  }

  @override
  Future<Map<String, dynamic>> pollAuthSessionStatus(
    Map<String, dynamic> data,
  ) async {
    if (pollResponses.isEmpty) {
      return {'response': <String, dynamic>{}};
    }
    return pollResponses.removeFirst();
  }
}
