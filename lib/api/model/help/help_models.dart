class HelpCategory {
  final String? categoryCode;
  final String? label;
  final String? category;

  const HelpCategory({this.categoryCode, this.label, this.category});

  factory HelpCategory.fromJson(Map<String, dynamic> json) {
    return HelpCategory(
      categoryCode:
          json['categoryCode']?.toString() ??
          json['category_code']?.toString() ??
          json['category']?.toString() ??
          json['code']?.toString(),
      label:
          json['label']?.toString() ??
          json['name']?.toString() ??
          json['title']?.toString(),
      category: json['category']?.toString(),
    );
  }
}

class HelpItem {
  final String? id;
  final String? title;
  final String? content;
  final String? author;
  final int? time;
  final String? categoryCode;

  const HelpItem({
    this.id,
    this.title,
    this.content,
    this.author,
    this.time,
    this.categoryCode,
  });

  factory HelpItem.fromJson(Map<String, dynamic> json) {
    return HelpItem(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      content: json['context']?.toString() ?? json['content']?.toString(),
      author:
          json['author']?.toString() ??
          json['createName']?.toString() ??
          json['create_name']?.toString(),
      time: _asInt(json['time'] ?? json['createTime'] ?? json['create_time']),
      categoryCode:
          json['categoryCode']?.toString() ?? json['category_code']?.toString(),
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
