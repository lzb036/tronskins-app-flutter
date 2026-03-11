import 'package:tronskins_app/api/model/entity/system/currency/currency_info_entity.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiSystemServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<List<CurrencyInfoEntity>>> getCurrencyList() async {
    final response = await http.get('api/public/currency/exchange/rate/list');

    return BaseHttpResponse.fromJson(response.data, (json) {
      if (json is List) {
        return json.map((e) {
          final map = e as Map<String, dynamic>;
          return CurrencyInfoEntity(
            id: _asInt(map['id']),
            currencyCode: map['currencyCode']?.toString() ?? '',
            rate: _asDouble(map['rate']),
            createTime: map['createTime']?.toString() ?? '',
            updateTime: map['updateTime']?.toString() ?? '',
          );
        }).toList();
      }
      return <CurrencyInfoEntity>[];
    });
  }
}

int _asInt(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString()) ?? 0;
}
