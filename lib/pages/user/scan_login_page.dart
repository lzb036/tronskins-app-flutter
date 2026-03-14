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
  bool _submitting = false;
  String? _pendingQrCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || _pendingQrCode != null || _submitting) {
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
    if (mounted) {
      setState(() {
        _pendingQrCode = qrCode;
      });
    }
    _handling = false;
  }

  Future<void> _confirmScan(String qrCode) async {
    setState(() {
      _submitting = true;
    });
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
        if (mounted) {
          Navigator.of(context).maybePop();
        }
        return;
      }

      final message = _resolveErrorMessage(res);
      AppSnackbar.error(message);
      await _resumeScanner();
    } catch (_) {
      AppSnackbar.error('app.user.login.message.error'.tr);
      await _resumeScanner();
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _cancelScan(String qrCode) async {
    setState(() {
      _submitting = true;
    });
    try {
      final res = await _api.cancelScanConfirm(qrCode: qrCode);
      if (res.success) {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
        return;
      }
      AppSnackbar.error(_resolveErrorMessage(res));
      await _resumeScanner();
    } catch (_) {
      AppSnackbar.error('app.user.login.message.error'.tr);
      await _resumeScanner();
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _resumeScanner() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingQrCode = null;
      _handling = false;
    });
    await _scannerController.start();
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
    return PopScope(
      canPop: _pendingQrCode == null || _submitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _pendingQrCode == null || _submitting) {
          return;
        }
        await _resumeScanner();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('app.user.login.scan_title'.tr),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _pendingQrCode == null
              ? _buildScannerView(colorScheme)
              : _buildConfirmView(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildScannerView(ColorScheme colorScheme) {
    return Stack(
      key: const ValueKey('scan'),
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
            child: Text(
              'app.user.login.scan_prompt'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmView(BuildContext context, ColorScheme colorScheme) {
    return Container(
      key: const ValueKey('confirm'),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.primaryContainer.withValues(alpha: 0.36),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDesktopPreview(colorScheme),
                    const SizedBox(height: 22),
                    Text(
                      'app.user.login.browser_confirm'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => _cancelScan(_pendingQrCode!),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text('app.common.cancel'.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting
                                ? null
                                : () => _confirmScan(_pendingQrCode!),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('app.user.login.title'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPreview(ColorScheme colorScheme) {
    return SizedBox(
      width: 170,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 152,
              height: 98,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      Icons.desktop_windows_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PC',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              width: 44,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 78,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
