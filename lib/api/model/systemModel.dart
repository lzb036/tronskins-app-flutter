// ignore_for_file: file_names

class SystemCurrencyModel {
  final int id;
  final String currencyCode;
  final double rate;
  final String createTime;
  final String updateTime;

  SystemCurrencyModel({
    required this.id,
    required this.currencyCode,
    required this.rate,
    required this.createTime,
    required this.updateTime,
  });

  factory SystemCurrencyModel.fromJson(Map<String, dynamic> json) {
    return SystemCurrencyModel(
      id: json['id'],
      currencyCode: json['currencyCode'],
      rate: json['rate'],
      createTime: json['createTime'],
      updateTime: json['updateTime'],
    );
  }
}
