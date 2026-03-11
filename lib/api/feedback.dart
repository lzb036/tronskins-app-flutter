import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tronskins_app/api/model/feedback/feedback_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiFeedbackServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<FeedbackListResponse<FeedbackTicket>>> ticketList({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.post(
      'api/app/ticket/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FeedbackListResponse.fromJson(
        json as Map<String, dynamic>,
        FeedbackTicket.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<FeedbackDetail>> ticketDetail({
    required String id,
  }) async {
    final response = await http.post('api/app/ticket/$id/show');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FeedbackDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<FeedbackListResponse<FeedbackReply>>> replyList({
    required String ticketId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await http.post(
      'api/app/ticket/reply/list',
      data: {'ticketId': ticketId, 'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FeedbackListResponse.fromJson(
        json as Map<String, dynamic>,
        FeedbackReply.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<dynamic>> submitFeedback({
    required String title,
    required String context,
    String? email,
    List<String> ids = const [],
  }) async {
    final response = await http.post(
      'api/app/ticket/add',
      data: {
        'email': email ?? '',
        'title': title,
        'context': context,
        'ids': ids,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> addReply({
    required String ticketId,
    required String context,
    List<String> ids = const [],
  }) async {
    final response = await http.post(
      'api/app/ticket/reply/add',
      data: {'ticketId': ticketId, 'context': context, 'ids': ids},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> solveFeedback({required String id}) async {
    final response = await http.post('api/app/ticket/$id/solve');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<String>> uploadImage({
    required String filePath,
    bool isReply = false,
  }) async {
    final file = File(filePath);
    final name = filePath.split(RegExp(r'[\\/]+')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: name),
    });
    final response = await http.request(
      isReply ? 'api/app/ticket/reply/upload' : 'api/app/ticket/upload',
      data: formData,
      options: Options(method: 'POST', contentType: 'multipart/form-data'),
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json?.toString() ?? '',
    );
  }
}
