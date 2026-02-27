class NotifyPager {
  final int page;
  final int pageSize;
  final int total;

  const NotifyPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory NotifyPager.fromJson(Map<String, dynamic> json) {
    return NotifyPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 10,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class NotifyListResponse<T> {
  final List<T> list;
  final NotifyPager? pager;

  const NotifyListResponse({
    required this.list,
    this.pager,
  });

  factory NotifyListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper, {
    String listKey = 'list',
  }) {
    final rawList = json[listKey];
    final list = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(mapper).toList()
        : <T>[];
    final pager = json['pager'] is Map<String, dynamic>
        ? NotifyPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;
    return NotifyListResponse(list: list, pager: pager);
  }
}

class TradeNotifyItem {
  final String? id;
  final String? message;
  final int? type;
  final int? status;
  final int? cancelReason;
  final String? cancelDesc;
  final String? buyerId;
  final int? createTime;
  bool read;

  TradeNotifyItem({
    this.id,
    this.message,
    this.type,
    this.status,
    this.cancelReason,
    this.cancelDesc,
    this.buyerId,
    this.createTime,
    this.read = false,
  });

  factory TradeNotifyItem.fromJson(Map<String, dynamic> json) {
    return TradeNotifyItem(
      id: json['id']?.toString(),
      message: json['message']?.toString(),
      type: _asInt(json['type']),
      status: _asInt(json['status']),
      cancelReason: _asInt(json['cancelReason'] ?? json['cancel_reason']),
      cancelDesc: json['cancelDesc']?.toString() ??
          json['cancel_desc']?.toString(),
      buyerId: json['buyer']?.toString() ??
          json['buyer_id']?.toString() ??
          json['buyerId']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
      read: _asBool(json['read'] ?? json['isRead'] ?? json['is_read']),
    );
  }
}

class NoticeMessageItem {
  final String? id;
  final String? title;
  final int? createTime;
  bool isRead;

  NoticeMessageItem({
    this.id,
    this.title,
    this.createTime,
    this.isRead = false,
  });

  factory NoticeMessageItem.fromJson(Map<String, dynamic> json) {
    return NoticeMessageItem(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
      isRead: _asBool(json['isRead'] ?? json['read'] ?? json['is_read']),
    );
  }
}

class NoticeDetail {
  final String? id;
  final String? title;
  final String? content;
  final String? createName;
  final int? createTime;

  const NoticeDetail({
    this.id,
    this.title,
    this.content,
    this.createName,
    this.createTime,
  });

  factory NoticeDetail.fromJson(Map<String, dynamic> json) {
    return NoticeDetail(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      createName: json['createName']?.toString() ??
          json['create_name']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final str = value.toString().toLowerCase();
  return str == '1' || str == 'true' || str == 'yes';
}
