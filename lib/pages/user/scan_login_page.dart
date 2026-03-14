import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';

class ScanLoginPage extends StatefulWidget {
  const ScanLoginPage({super.key});

  @override
  State<ScanLoginPage> createState() => _ScanLoginPageState();
}

class _ScanLoginPageState extends State<ScanLoginPage> {
  final ApiLoginServer _api = ApiLoginServer();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handling = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) {
      return;
    }
    final rawValue = capture.barcodes.first.rawValue?.trim() ?? '';
    final qrCode = _extractQrCode(rawValue);
    if (qrCode == null || qrCode.isEmpty) {
      _handling = true;
      AppSnackbar.error('app.user.login.message.error'.tr);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _handling = false;
      return;
    }

    _handling = true;
    await _scannerController.stop();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.user.login.confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('app.user.login.title'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _confirmScan(qrCode);
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }

    await _cancelScan(qrCode);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _confirmScan(String qrCode) async {
    try {
      final res = await _api.loginScanConfirm(qrCode: qrCode);
      final data = res.datas;
      final status = data is Map<String, dynamic>
          ? data['status']
          : (data is Map ? data['status'] : null);
      final normalizedStatus = status is num
          ? status.toInt()
          : int.tryParse(status?.toString() ?? '');

      if (res.success && normalizedStatus == 2) {
        AppSnackbar.success('app.user.login.message.success'.tr);
        return;
      }

      final message = _resolveErrorMessage(res);
      AppSnackbar.error(message);
    } catch (_) {
      AppSnackbar.error('app.user.login.message.error'.tr);
    }
  }

  Future<void> _cancelScan(String qrCode) async {
    try {
      final res = await _api.cancelScanConfirm(qrCode: qrCode);
      if (res.success) {
        AppSnackbar.success('app.system.message.success'.tr);
        return;
      }
      AppSnackbar.error(_resolveErrorMessage(res));
    } catch (_) {
      AppSnackbar.error('app.user.login.message.error'.tr);
    }
  }

  String _resolveErrorMessage(dynamic res) {
    final dataText = res.datas?.toString().trim() ?? '';
    if (dataText.isNotEmpty) {
      return dataText;
    }
    final messageText = res.message?.toString().trim() ?? '';
    if (messageText.isNotEmpty) {
      return messageText;
    }
    return 'app.user.login.message.error'.tr;
  }

  String? _extractQrCode(String rawValue) {
    if (rawValue.isEmpty) {
      return null;
    }
    final match = RegExp(r'code=([^&]+)').firstMatch(rawValue);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('扫码登录'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '请扫描 TronSkins 登录二维码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
