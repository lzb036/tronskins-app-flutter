class FeedbackPager {
  final int page;
  final int pageSize;
  final int total;

  const FeedbackPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory FeedbackPager.fromJson(Map<String, dynamic> json) {
    return FeedbackPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 10,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class FeedbackListResponse<T> {
  final List<T> list;
  final FeedbackPager? pager;

  const FeedbackListResponse({required this.list, this.pager});

  factory FeedbackListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper, {
    String listKey = 'list',
  }) {
    final rawList = json[listKey];
    final list = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(mapper).toList()
        : <T>[];
    final pager = json['pager'] is Map<String, dynamic>
        ? FeedbackPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;
    return FeedbackListResponse(list: list, pager: pager);
  }
}

class FeedbackTicket {
  final String? id;
  final String? title;
  final int? status;
  final String? statusName;
  final int? createTime;

  const FeedbackTicket({
    this.id,
    this.title,
    this.status,
    this.statusName,
    this.createTime,
  });

  factory FeedbackTicket.fromJson(Map<String, dynamic> json) {
    return FeedbackTicket(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      status: _asInt(json['status']),
      statusName:
          json['statusName']?.toString() ?? json['status_name']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class FeedbackDetail {
  final String? id;
  final String? title;
  final String? context;
  final int? status;
  final String? statusName;
  final int? createTime;

  const FeedbackDetail({
    this.id,
    this.title,
    this.context,
    this.status,
    this.statusName,
    this.createTime,
  });

  factory FeedbackDetail.fromJson(Map<String, dynamic> json) {
    return FeedbackDetail(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      context: json['context']?.toString(),
      status: _asInt(json['status']),
      statusName:
          json['statusName']?.toString() ?? json['status_name']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class FeedbackReply {
  final String? id;
  final String? context;
  final int? createTime;
  final List<String> images;
  final bool isAdmin;

  const FeedbackReply({
    this.id,
    this.context,
    this.createTime,
    required this.images,
    this.isAdmin = false,
  });

  factory FeedbackReply.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];
    return FeedbackReply(
      id: json['id']?.toString(),
      context: json['context']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
      images: images,
      isAdmin: _asBool(json['is_admin'] ?? json['isAdmin']),
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
