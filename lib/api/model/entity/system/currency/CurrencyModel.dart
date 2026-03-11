// ignore_for_file: file_names

class CurrencyModel {
  final String code; // 如：CNY、EUR_DE
  final String symbol; // 货币符号
  final double rate; // 汇率（相对于 USD）
  final String name; // 货币名称（英文）
  final String icon; // 国旗 emoji —— 超好看！

  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.rate,
    required this.name,
    required this.icon,
  });
}
