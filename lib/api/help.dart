import 'package:tronskins_app/api/model/help/help_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiHelpServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<List<HelpCategory>>> categoryList() async {
    final response = await http.get('api/public/help/center/category/list');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(HelpCategory.fromJson)
          .toList(),
    );
  }

  Future<BaseHttpResponse<List<HelpItem>>> helpList({
    required String categoryCode,
  }) async {
    final response = await http.post(
      'api/public/help/center/list',
      data: {'categoryCode': categoryCode},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(HelpItem.fromJson)
          .toList(),
    );
  }

  Future<BaseHttpResponse<List<HelpItem>>> helpItemList({
    required String title,
  }) async {
    final response = await http.get(
      'api/public/help/center/title/list',
      queryParameters: {'title': title},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(HelpItem.fromJson)
          .toList(),
    );
  }
}
