import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';

class PriceSortFilterSheet extends StatefulWidget {
  const PriceSortFilterSheet({
    super.key,
    required this.sortOptions,
    required this.initial,
    this.titleKey = 'app.market.filter.text',
    this.showPriceRange = true,
    this.showSort = true,
    this.showInventoryStateFilters = false,
  });

  final List<SortOption> sortOptions;
  final PriceSortFilterResult initial;
  final String titleKey;
  final bool showPriceRange;
  final bool showSort;
  final bool showInventoryStateFilters;

  @override
  State<PriceSortFilterSheet> createState() => _PriceSortFilterSheetState();
}

class _PriceSortFilterSheetState extends State<PriceSortFilterSheet> {
  late String _sortField;
  late bool _sortAsc;
  late bool _sellableOnly;
  late bool _coolingOnly;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _sortField = widget.initial.sortField;
    _sortAsc = widget.initial.sortAsc;
    _sellableOnly = widget.initial.sellableOnly;
    _coolingOnly = widget.initial.coolingOnly;
    _minController = TextEditingController(
      text: widget.initial.priceMin?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.priceMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _sortField = widget.sortOptions.isNotEmpty
          ? widget.sortOptions.first.field
          : _sortField;
      _sortAsc = false;
      _sellableOnly = false;
      _coolingOnly = false;
      _minController.text = '';
      _maxController.text = '';
    });
  }

  void _apply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    Navigator.of(context).pop(
      PriceSortFilterResult(
        sortField: _sortField,
        sortAsc: _sortAsc,
        priceMin: min,
        priceMax: max,
        sellableOnly: _sellableOnly,
        coolingOnly: _coolingOnly,
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
              if (widget.showSort) ...[
                Text(
                  'app.market.filter.sort'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _sortField,
                  items: widget.sortOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.field,
                          child: Text(option.labelKey.tr),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _sortField = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('app.market.filter.sort'.tr),
                  secondary: Icon(
                    _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  value: _sortAsc,
                  onChanged: (value) => setState(() => _sortAsc = value),
                ),
              ],
              if (widget.showPriceRange) ...[
                const SizedBox(height: 8),
                Text(
                  'app.market.filter.price_range'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'app.market.filter.price_lowest'.tr,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'app.market.filter.price_highest'.tr,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.showInventoryStateFilters) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('app.market.product.sellable'.tr),
                  value: _sellableOnly,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _sellableOnly = value;
                      if (value) {
                        _coolingOnly = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('app.market.product.cooling'.tr),
                  value: _coolingOnly,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _coolingOnly = value;
                      if (value) {
                        _sellableOnly = false;
                      }
                    });
                  },
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
