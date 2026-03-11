import 'package:tronskins_app/api/model/notify/notify_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiNotifyServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<NotifyListResponse<TradeNotifyItem>>> tradeList({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      'api/app/mytrade/log/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => NotifyListResponse.fromJson(
        json as Map<String, dynamic>,
        TradeNotifyItem.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<NotifyListResponse<NoticeMessageItem>>> noticeList({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      'api/app/notice/message/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => NotifyListResponse.fromJson(
        json as Map<String, dynamic>,
        NoticeMessageItem.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<NoticeDetail>> noticeDetail({
    required String id,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.get(
      'api/notice/detail.do?id=$id&page=$page&pageSize=$pageSize',
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => NoticeDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<dynamic>> readTrade({required String id}) async {
    final response = await http.post('api/app/mytrade/log/$id/read');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> deleteTrade({required String id}) async {
    final response = await http.post('api/app/mytrade/log/$id/delete');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> readAllTrade() async {
    final response = await http.post('api/app/mytrade/log/read_all');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> clearTrade() async {
    final response = await http.post('api/app/mytrade/log/clear');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> readNotice({required String id}) async {
    final response = await http.post('api/app/notice/read', data: {'id': id});
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> readAllNotice() async {
    final response = await http.post('api/app/notice/read_all');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }
}
