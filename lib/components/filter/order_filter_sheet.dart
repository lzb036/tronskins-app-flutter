import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';

class OrderFilterSheet extends StatefulWidget {
  const OrderFilterSheet({
    super.key,
    required this.initial,
    required this.statusOptions,
    this.titleKey = 'app.market.filter.text',
    this.showSort = false,
    this.showStatus = true,
    this.showDateRange = true,
    this.enableAttributeFilter = false,
    this.appId,
    this.attributeSortOptions = const [],
    this.attributeShowSort = false,
    this.attributeShowPriceRange = false,
    this.isSideSheet = false,
  });

  final OrderFilterResult initial;
  final List<StatusOption> statusOptions;
  final String titleKey;
  final bool showSort;
  final bool showStatus;
  final bool showDateRange;
  final bool enableAttributeFilter;
  final int? appId;
  final List<SortOption> attributeSortOptions;
  final bool attributeShowSort;
  final bool attributeShowPriceRange;
  final bool isSideSheet;

  static Future<OrderFilterResult?> showFromRight({
    required BuildContext context,
    required OrderFilterResult initial,
    required List<StatusOption> statusOptions,
    String titleKey = 'app.market.filter.text',
    bool showSort = false,
    bool showStatus = true,
    bool showDateRange = true,
    bool enableAttributeFilter = false,
    int? appId,
    List<SortOption> attributeSortOptions = const [],
    bool attributeShowSort = false,
    bool attributeShowPriceRange = false,
  }) {
    final barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;
    return showGeneralDialog<OrderFilterResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final width = MediaQuery.of(dialogContext).size.width;
        final panelWidth = width.clamp(320.0, 560.0).toDouble();
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: panelWidth,
            child: Material(
              color: Colors.transparent,
              child: OrderFilterSheet(
                initial: initial,
                statusOptions: statusOptions,
                titleKey: titleKey,
                showSort: showSort,
                showStatus: showStatus,
                showDateRange: showDateRange,
                enableAttributeFilter: enableAttributeFilter,
                appId: appId,
                attributeSortOptions: attributeSortOptions,
                attributeShowSort: attributeShowSort,
                attributeShowPriceRange: attributeShowPriceRange,
                isSideSheet: true,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedStatusIndex = -1;
  bool _sortAsc = false;
  late String _attributeSortField;
  late bool _attributeSortAsc;
  late Map<String, dynamic> _attributeTags;
  String? _attributeItemName;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _sortAsc = widget.initial.sortAsc ?? false;
    _attributeSortField = widget.initial.sortField ??
        (widget.attributeSortOptions.isNotEmpty
            ? widget.attributeSortOptions.first.field
            : 'time');
    _attributeSortAsc = widget.initial.sortAsc ?? false;
    _attributeTags = Map<String, dynamic>.from(widget.initial.tags ?? const {});
    _attributeItemName = widget.initial.itemName;
    if (widget.initial.statusList != null) {
      final index = widget.statusOptions.indexWhere(
        (option) => _listEquals(option.values, widget.initial.statusList!),
      );
      _selectedStatusIndex = index;
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (result != null) {
      setState(() => _startDate = result);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (result != null) {
      setState(() => _endDate = result);
    }
  }

  void _reset() {
    setState(() {
      _sortAsc = false;
      _selectedStatusIndex = -1;
      _startDate = null;
      _endDate = null;
      _attributeSortField = widget.attributeSortOptions.isNotEmpty
          ? widget.attributeSortOptions.first.field
          : 'time';
      _attributeSortAsc = false;
      _attributeTags = <String, dynamic>{};
      _attributeItemName = null;
    });
  }

  String _attributeSummary() {
    if ((_attributeItemName ?? '').isNotEmpty) {
      return _attributeItemName!;
    }
    if (_attributeTags.isNotEmpty) {
      return '${'app.market.filter.text'.tr} (${_attributeTags.length})';
    }
    return 'app.market.filter.all'.tr;
  }

  Future<void> _openAttributeFilter() async {
    final appId = widget.appId;
    if (appId == null) {
      return;
    }
    final result = await MarketFilterSheet.showFromRight(
      context: context,
      appId: appId,
      sortOptions: widget.attributeSortOptions,
      showSort: widget.attributeShowSort,
      showPriceRange: widget.attributeShowPriceRange,
      initial: MarketFilterResult(
        sortField: _attributeSortField,
        sortAsc: _attributeSortAsc,
        tags: _attributeTags,
        itemName: _attributeItemName,
      ),
    );
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _attributeSortField = result.sortField;
      _attributeSortAsc = result.sortAsc;
      _attributeTags = Map<String, dynamic>.from(result.tags ?? const {});
      _attributeItemName = (result.itemName == null || result.itemName!.isEmpty)
          ? null
          : result.itemName;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      OrderFilterResult(
        sortAsc: widget.showSort
            ? _sortAsc
            : (widget.attributeShowSort ? _attributeSortAsc : null),
        sortField: widget.attributeShowSort ? _attributeSortField : null,
        statusList: _selectedStatusIndex >= 0
            ? widget.statusOptions[_selectedStatusIndex].values
            : null,
        startDate: _startDate,
        endDate: _endDate,
        tags: widget.enableAttributeFilter ? _attributeTags : null,
        itemName: widget.enableAttributeFilter ? _attributeItemName : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.titleKey.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.showSort) ...[
                Text(
                  'app.market.filter.sort'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('app.market.filter.sort'.tr),
                  secondary: Icon(
                    _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  value: _sortAsc,
                  onChanged: (value) => setState(() => _sortAsc = value),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.showStatus) ...[
                Text(
                  'app.trade.order.status'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(widget.statusOptions.length, (index) {
                    final option = widget.statusOptions[index];
                    final selected = _selectedStatusIndex == index;
                    return FilterChip(
                      label: Text(option.labelKey.tr),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          _selectedStatusIndex = value ? index : -1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.enableAttributeFilter) ...[
                Text(
                  'app.market.filter.text'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune_outlined),
                  title: Text('app.market.filter.text'.tr),
                  subtitle: Text(
                    _attributeSummary(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAttributeFilter,
                ),
                const SizedBox(height: 8),
              ],
              if (widget.showDateRange) ...[
                Text(
                  'app.trade.order.date'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('app.market.filter.date_start'.tr),
                  subtitle: Text(_formatDate(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickStartDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('app.market.filter.date_end'.tr),
                  subtitle: Text(_formatDate(_endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickEndDate,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    child: Text('app.market.filter.clear'.tr),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: Text('app.market.filter.reset'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('app.common.cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: Text('app.market.filter.finish'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!widget.isSideSheet) {
      return body;
    }
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: body,
    );
  }
}
