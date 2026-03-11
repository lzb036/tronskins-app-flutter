// lib/common/http/model/base_response.dart
class BaseHttpResponse<T> {
  final int code;
  final String message;
  final T? datas;

  BaseHttpResponse({required this.code, required this.message, this.datas});

  factory BaseHttpResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return BaseHttpResponse(
      code: json['code'] as int? ?? -1,
      message: (json['message'] ?? json['msg'] ?? '') as String,
      datas: json['datas'] != null ? fromJsonT(json['datas']) : null,
    );
  }

  bool get success => code == 200 || code == 0;
}
