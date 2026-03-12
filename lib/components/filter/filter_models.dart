import 'package:flutter/foundation.dart';

class SortOption {
  const SortOption({required this.labelKey, required this.field});

  final String labelKey;
  final String field;
}

class StatusOption {
  const StatusOption({required this.labelKey, required this.values});

  final String labelKey;
  final List<int> values;
}

@immutable
class PriceSortFilterResult {
  const PriceSortFilterResult({
    required this.sortField,
    required this.sortAsc,
    this.priceMin,
    this.priceMax,
    this.sellableOnly = false,
    this.coolingOnly = false,
  });

  final String sortField;
  final bool sortAsc;
  final double? priceMin;
  final double? priceMax;
  final bool sellableOnly;
  final bool coolingOnly;
}

@immutable
class OrderFilterResult {
  const OrderFilterResult({
    this.statusList,
    this.startDate,
    this.endDate,
    this.sortAsc,
    this.sortField,
    this.priceMin,
    this.priceMax,
    this.tags,
    this.itemName,
    this.reset = false,
  });

  final List<int>? statusList;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? sortAsc;
  final String? sortField;
  final double? priceMin;
  final double? priceMax;
  final Map<String, dynamic>? tags;
  final String? itemName;
  final bool reset;
}

@immutable
class MarketFilterResult {
  const MarketFilterResult({
    required this.sortField,
    required this.sortAsc,
    this.priceMin,
    this.priceMax,
    this.tags,
    this.itemName,
    this.statusList,
    this.startDate,
    this.endDate,
    this.clearKeyword = false,
  });

  final String sortField;
  final bool sortAsc;
  final double? priceMin;
  final double? priceMax;
  final Map<String, dynamic>? tags;
  final String? itemName;
  final List<int>? statusList;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool clearKeyword;
}
