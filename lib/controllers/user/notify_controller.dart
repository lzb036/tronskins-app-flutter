import 'package:get/get.dart';
import 'package:tronskins_app/api/model/notify/notify_models.dart';
import 'package:tronskins_app/api/notify.dart';

class NotifyController extends GetxController {
  NotifyController({ApiNotifyServer? api}) : _api = api ?? ApiNotifyServer();

  final ApiNotifyServer _api;

  final RxList<TradeNotifyItem> tradeList = <TradeNotifyItem>[].obs;
  final RxList<NoticeMessageItem> noticeList = <NoticeMessageItem>[].obs;

  final RxBool tradeLoading = false.obs;
  final RxBool noticeLoading = false.obs;

  final RxInt tradeTotal = 0.obs;
  final RxInt noticeTotal = 0.obs;

  int _tradePage = 1;
  int _noticePage = 1;
  final int _pageSize = 10;
  bool _tradeReachedEnd = false;
  bool _noticeReachedEnd = false;

  bool get tradeHasMore => !_tradeReachedEnd;
  bool get noticeHasMore => !_noticeReachedEnd;

  Future<void> loadTradeList({bool refresh = false}) async {
    if (tradeLoading.value) return;
    if (!refresh && !tradeHasMore) return;

    tradeLoading.value = true;
    try {
      if (refresh) {
        _tradePage = 1;
        _tradeReachedEnd = false;
      }
      final res = await _api.tradeList(page: _tradePage, pageSize: _pageSize);
      if (res.success && res.datas != null) {
        final data = res.datas!;
        if (refresh) {
          tradeList.assignAll(data.list);
        } else {
          tradeList.addAll(data.list);
        }
        if (data.pager != null) {
          tradeTotal.value = data.pager!.total;
          _tradeReachedEnd = tradeList.length >= tradeTotal.value;
        } else if (data.list.isEmpty) {
          _tradeReachedEnd = true;
        }
        if (data.list.isNotEmpty) {
          _tradePage += 1;
        }
      }
    } finally {
      tradeLoading.value = false;
    }
  }

  Future<void> loadNoticeList({bool refresh = false}) async {
    if (noticeLoading.value) return;
    if (!refresh && !noticeHasMore) return;

    noticeLoading.value = true;
    try {
      if (refresh) {
        _noticePage = 1;
        _noticeReachedEnd = false;
      }
      final res = await _api.noticeList(page: _noticePage, pageSize: _pageSize);
      if (res.success && res.datas != null) {
        final data = res.datas!;
        if (refresh) {
          noticeList.assignAll(data.list);
        } else {
          noticeList.addAll(data.list);
        }
        if (data.pager != null) {
          noticeTotal.value = data.pager!.total;
          _noticeReachedEnd = noticeList.length >= noticeTotal.value;
        } else if (data.list.isEmpty) {
          _noticeReachedEnd = true;
        }
        if (data.list.isNotEmpty) {
          _noticePage += 1;
        }
      }
    } finally {
      noticeLoading.value = false;
    }
  }

  Future<String?> readTrade(TradeNotifyItem item) async {
    if (item.read || item.id == null) return null;
    final res = await _api.readTrade(id: item.id!);
    if (res.success) {
      item.read = true;
      tradeList.refresh();
      final message = res.datas?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      if (res.message.isNotEmpty) {
        return res.message;
      }
      return '';
    }
    return null;
  }

  Future<bool> readNotice(NoticeMessageItem item) async {
    if (item.isRead || item.id == null) return false;
    final res = await _api.readNotice(id: item.id!);
    if (res.success) {
      item.isRead = true;
      noticeList.refresh();
      return true;
    }
    return false;
  }

  Future<bool> readAllTrade() async {
    final res = await _api.readAllTrade();
    if (res.success) {
      for (final item in tradeList) {
        item.read = true;
      }
      tradeList.refresh();
      return true;
    }
    return false;
  }

  Future<String?> clearTrade() async {
    final res = await _api.clearTrade();
    if (res.success) {
      tradeList.clear();
      tradeTotal.value = 0;
      _tradePage = 1;
      _tradeReachedEnd = false;
      final message = res.datas?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      if (res.message.isNotEmpty) {
        return res.message;
      }
      return '';
    }
    return null;
  }

  Future<String?> deleteTrade(String id) async {
    final res = await _api.deleteTrade(id: id);
    if (res.success) {
      final message = res.datas?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      if (res.message.isNotEmpty) {
        return res.message;
      }
      return '';
    }
    return null;
  }

  Future<bool> readAllNotice() async {
    final res = await _api.readAllNotice();
    if (res.success) {
      for (final item in noticeList) {
        item.isRead = true;
      }
      noticeList.refresh();
      return true;
    }
    return false;
  }
}
