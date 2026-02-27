import 'package:get/get.dart';
import 'package:tronskins_app/api/feedback.dart';
import 'package:tronskins_app/api/model/feedback/feedback_models.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class FeedbackController extends GetxController {
  FeedbackController({ApiFeedbackServer? api})
      : _api = api ?? ApiFeedbackServer();

  final ApiFeedbackServer _api;

  final RxList<FeedbackTicket> tickets = <FeedbackTicket>[].obs;
  final RxBool listLoading = false.obs;
  final RxInt total = 0.obs;
  int _page = 1;
  final int _pageSize = 20;
  bool _reachedEnd = false;

  final Rxn<FeedbackDetail> detail = Rxn<FeedbackDetail>();
  final RxBool detailLoading = false.obs;

  final RxList<FeedbackReply> replies = <FeedbackReply>[].obs;
  final RxBool replyLoading = false.obs;
  int _replyPage = 1;
  final int _replyPageSize = 50;
  bool _replyReachedEnd = false;

  bool get hasUnfinishedFeedback =>
      tickets.any((item) => item.status == 0 || item.status == 1);

  bool get hasMore => !_reachedEnd;
  bool get repliesHasMore => !_replyReachedEnd;

  Future<void> loadTickets({bool refresh = false}) async {
    if (listLoading.value) return;
    if (!refresh && _reachedEnd) return;
    listLoading.value = true;
    try {
      if (refresh) {
        _page = 1;
        _reachedEnd = false;
      }
      final res = await _api.ticketList(page: _page, pageSize: _pageSize);
      if (res.success && res.datas != null) {
        final data = res.datas!;
        if (refresh) {
          tickets.assignAll(data.list);
        } else {
          tickets.addAll(data.list);
        }
        if (data.pager != null) {
          total.value = data.pager!.total;
          _reachedEnd = tickets.length >= total.value;
        } else if (data.list.isEmpty) {
          _reachedEnd = true;
        }
        if (data.list.isNotEmpty) {
          _page += 1;
        }
      }
    } finally {
      listLoading.value = false;
    }
  }

  Future<void> loadDetail(String id) async {
    if (detailLoading.value) return;
    detailLoading.value = true;
    try {
      final res = await _api.ticketDetail(id: id);
      if (res.success) {
        detail.value = res.datas;
      }
    } finally {
      detailLoading.value = false;
    }
  }

  Future<void> loadReplies({
    required String ticketId,
    bool refresh = false,
  }) async {
    if (replyLoading.value) return;
    if (!refresh && _replyReachedEnd) return;
    replyLoading.value = true;
    try {
      if (refresh) {
        _replyPage = 1;
        _replyReachedEnd = false;
      }
      final res = await _api.replyList(
        ticketId: ticketId,
        page: _replyPage,
        pageSize: _replyPageSize,
      );
      if (res.success && res.datas != null) {
        final data = res.datas!;
        if (refresh) {
          replies.assignAll(data.list);
        } else {
          replies.addAll(data.list);
        }
        if (data.pager != null) {
          _replyReachedEnd = replies.length >= data.pager!.total;
        } else if (data.list.isEmpty) {
          _replyReachedEnd = true;
        }
        if (data.list.isNotEmpty) {
          _replyPage += 1;
        }
        replies.sort((a, b) =>
            (a.createTime ?? 0).compareTo(b.createTime ?? 0));
      }
    } finally {
      replyLoading.value = false;
    }
  }

  Future<bool> submitFeedback({
    required String title,
    required String context,
    String? email,
    List<String> ids = const [],
  }) async {
    final res = await _api.submitFeedback(
      title: title,
      context: context,
      email: email,
      ids: ids,
    );
    return res.success;
  }

  Future<bool> addReply({
    required String ticketId,
    required String context,
    List<String> ids = const [],
  }) async {
    final res = await _api.addReply(
      ticketId: ticketId,
      context: context,
      ids: ids,
    );
    return res.success;
  }

  Future<BaseHttpResponse<dynamic>> solveFeedback(String id) async {
    return _api.solveFeedback(id: id);
  }

  Future<String?> uploadImage({
    required String filePath,
    bool isReply = false,
  }) async {
    final res = await _api.uploadImage(
      filePath: filePath,
      isReply: isReply,
    );
    if (res.success) {
      final id = res.datas?.toString();
      return (id != null && id.isNotEmpty) ? id : null;
    }
    return null;
  }
}
