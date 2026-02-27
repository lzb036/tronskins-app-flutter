import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';

class OrderFilterSheet extends StatefulWidget {
  const OrderFilterSheet({
    super.key,
    required this.initial,
    required this.statusOptions,
    this.titleKey = 'app.market.filter.text',
    this.showStatus = true,
    this.showDateRange = true,
  });

  final OrderFilterResult initial;
  final List<StatusOption> statusOptions;
  final String titleKey;
  final bool showStatus;
  final bool showDateRange;

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedStatusIndex = -1;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
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
      _selectedStatusIndex = -1;
      _startDate = null;
      _endDate = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      OrderFilterResult(
        statusList: _selectedStatusIndex >= 0
            ? widget.statusOptions[_selectedStatusIndex].values
            : null,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
  }
}
