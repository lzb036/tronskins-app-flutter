// ignore_for_file: file_names

import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/api/system.dart';
import 'package:tronskins_app/api/model/entity/system/currency/currency_info_entity.dart';

class CurrencyController extends GetxController {
  static CurrencyController get to => Get.find();

  final _storage = GetStorage();
  static const _key = 'selected_currency';
  static const _ratesKey = 'currency_rates';

  // 当前选择的货币代码
  final _code = RxnString();
  String get code => _code.value ?? 'USD';

  // 实时汇率映射（USD 永不为 null）
  final _rates = <String, double>{'USD': 1.0}.obs;

  List<Map<String, dynamic>> get allRates =>
      CurrencyController.supportedList.map((code) {
        return {
          'code': code,
          'symbol': _symbols[code] ?? '?',
          'name': code,
          'rate': _rates[code] ?? _fallbackRate(code),
          'isCurrent': code == this.code,
        };
      }).toList();

  // 是否已完成加载
  final _loaded = false.obs;
  bool get isLoaded => _loaded.value;

  // 货币符号表
  static const _symbols = <String, String>{
    'USD': r'$',
    'CNY': '¥',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'KRW': '₩',
    'RUB': '₽',
    'VND': '₫',
    'INR': '₹',
    'IDR': 'Rp',
    'THB': '฿',
    'PHP': '₱',
    'BRL': 'R\$',
    'TRY': '₺',
    'AUD': 'A\$',
    'CAD': 'CA\$',
  };

  String get symbol => _symbols[code] ?? r'$';
  String get usdSymbol => _symbols['USD'] ?? r'$';

  // 支持的货币顺序（用于所有列表展示）
  static const supportedList = [
    'USD',
    'CNY',
    'EUR',
    'GBP',
    'JPY',
    'KRW',
    'RUB',
    'VND',
    'INR',
    'IDR',
    'THB',
    'PHP',
    'BRL',
    'TRY',
    'AUD',
    'CAD',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedCurrency();
    _loadSavedRates();
    fetchRealRates(); // 首次加载
    _startAutoRefresh(); // 新增：启动自动刷新
  }

  @override
  void onClose() {
    _stopAutoRefresh(); // 新增：页面关闭或 App 关闭时停止定时器，防止内存泄漏
    super.onClose();
  }

  /// 拉取实时汇率
  Future<void> fetchRealRates({bool force = false}) async {
    if (_loaded.value && !force) return;

    try {
      final res = await ApiSystemServer().getCurrencyList();

      if (res.success && res.datas?.isNotEmpty == true) {
        final Map<String, double> updated = {'USD': 1.0};

        for (final CurrencyInfoEntity entity in res.datas!) {
          final String rawCode = entity.currencyCode;
          final double rate = entity.rate;

          final String code = rawCode.toUpperCase();
          if (supportedList.contains(code)) {
            updated[code] = rate;
          }
        }

        _rates.assignAll(updated); // 推荐写法：一次性替换，更安全
        _loaded.value = true;
        _storage.write(_ratesKey, updated);
        update(); // 触发所有 Obx 刷新
      } else {
        _loaded.value = true; // 空数据也算“加载完成”，避免无限 loading
      }
    } catch (e) {
      _loaded.value = true; // 失败也要标记完成
    }
  }

  void _loadSavedRates() {
    final saved = _storage.read(_ratesKey);
    if (saved is! Map) {
      return;
    }
    final Map<String, double> parsed = {'USD': 1.0};
    saved.forEach((key, value) {
      if (key is! String) return;
      if (!supportedList.contains(key) && key != 'USD') return;
      double? rate;
      if (value is num) {
        rate = value.toDouble();
      } else if (value is String) {
        rate = double.tryParse(value);
      }
      if (rate != null && rate > 0) {
        parsed[key] = rate;
      }
    });
    if (parsed.length > 1) {
      _rates.assignAll(parsed);
      _loaded.value = true;
      update();
    }
  }

  void _loadSavedCurrency() {
    final saved = _storage.read<String>(_key);

    String defaultCode;
    if (saved != null && _symbols.containsKey(saved)) {
      defaultCode = saved;
    } else {
      defaultCode = (Get.locale?.languageCode == 'zh') ? 'CNY' : 'USD';
      _storage.write(_key, defaultCode);
    }

    _code.value = defaultCode;
  }

  /// 切换货币
  void setCurrency(String newCode) {
    if (newCode == code || !_symbols.containsKey(newCode)) return;

    _code.value = newCode;
    _storage.write(_key, newCode);
    update(); // 全局价格刷新
  }

  /// 格式化价格（最核心方法）
  String format(double usdAmount) {
    if (usdAmount.isNaN || usdAmount.isInfinite || usdAmount < 0) {
      return '$symbol 0';
    }

    final double rate = _rates[code] ?? _fallbackRate(code);
    final double converted = usdAmount * rate;

    const noDecimal = ['JPY', 'KRW', 'VND', 'IDR'];
    final String display = noDecimal.contains(code)
        ? converted.round().toStringAsFixed(0)
        : converted.toStringAsFixed(2);

    return '$symbol $display';
  }

  /// 固定按 USD 显示（不参与汇率换算）
  String formatUsd(double usdAmount, {int fractionDigits = 2}) {
    if (usdAmount.isNaN || usdAmount.isInfinite || usdAmount < 0) {
      return r'$ 0';
    }
    final display = usdAmount.toStringAsFixed(fractionDigits);
    return '\$ $display';
  }

  /// 兜底汇率（永远有值）
  double _fallbackRate(String code) {
    return const {
          'CNY': 7.18,
          'EUR': 0.92,
          'GBP': 0.79,
          'JPY': 149.0,
          'KRW': 1380.0,
          'RUB': 96.5,
          'VND': 25400.0,
          'INR': 83.5,
          'IDR': 16200.0,
          'THB': 36.2,
          'PHP': 58.8,
          'BRL': 5.6,
          'TRY': 34.0,
          'AUD': 1.52,
          'CAD': 1.38,
        }[code] ??
        1.0;
  }

  /// 获取当前汇率倍数（用于计算差价、折扣等）
  double get currentRate => _rates[code] ?? _fallbackRate(code);

  /// 获取货币图标路径
  static String getCurrencyIcon(String currencyCode) {
    return 'assets/images/money/$currencyCode.png';
  }

  /// 获取当前货币的图标路径
  String get currentCurrencyIcon => getCurrencyIcon(code);

  Timer? _timer;

  /// 新增：每分钟自动刷新一次汇率
  void _startAutoRefresh() {
    // 防止重复启动
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // 静默刷新，不打扰用户
      fetchRealRates(force: true);
    });
  }

  /// 新增：停止自动刷新（切到后台时调用）
  void _stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }
}
