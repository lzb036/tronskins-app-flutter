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
  int _currentSectionIndex = 0;
  final Map<String, GlobalKey> _selectionAnchorKeys = {};

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

  List<_PriceSortSection> get _sections {
    final sections = <_PriceSortSection>[];
    if (widget.showSort) {
      sections.add(
        const _PriceSortSection(
          type: _PriceSortSectionType.sort,
          labelKey: 'app.market.filter.sort',
        ),
      );
    }
    if (widget.showPriceRange) {
      sections.add(
        const _PriceSortSection(
          type: _PriceSortSectionType.price,
          labelKey: 'app.market.filter.price_range',
        ),
      );
    }
    if (widget.showInventoryStateFilters) {
      sections.add(
        const _PriceSortSection(
          type: _PriceSortSectionType.state,
          labelKey: 'app.trade.order.status',
        ),
      );
    }
    return sections;
  }

  String _currentStateKey() {
    if (_sellableOnly) {
      return 'sellable';
    }
    if (_coolingOnly) {
      return 'cooling';
    }
    return 'all';
  }

  String _priceLowestLabel() {
    if (Get.locale?.languageCode == 'en') {
      return 'Lowest';
    }
    return 'app.market.filter.price_lowest'.tr;
  }

  String _priceHighestLabel() {
    if (Get.locale?.languageCode == 'en') {
      return 'Highest';
    }
    return 'app.market.filter.price_highest'.tr;
  }

  GlobalKey _selectionAnchorKey(String sectionKey, String optionName) {
    final key = '$sectionKey::$optionName';
    return _selectionAnchorKeys.putIfAbsent(key, GlobalKey.new);
  }

  String? _selectedAnchorOptionName(_PriceSortSection section) {
    switch (section.type) {
      case _PriceSortSectionType.sort:
        return _sortField.isEmpty ? null : _sortField;
      case _PriceSortSectionType.price:
        return null;
      case _PriceSortSectionType.state:
        return _currentStateKey();
    }
  }

  void _scrollToSectionSelection(_PriceSortSection section) {
    final selectedOptionName = _selectedAnchorOptionName(section);
    if ((selectedOptionName ?? '').isEmpty) {
      return;
    }
    final key = _selectionAnchorKey(section.key, selectedOptionName!);
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleScrollToSectionSelection(_PriceSortSection section) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToSectionSelection(section);
    });
  }

  String? _sectionSummary(_PriceSortSection section) {
    switch (section.type) {
      case _PriceSortSectionType.sort:
        if (_sortField.isEmpty) {
          return null;
        }
        var label = _sortField;
        for (final option in widget.sortOptions) {
          if (option.field == _sortField) {
            label = option.labelKey.tr;
            break;
          }
        }
        return '$label ${_sortAsc ? '↑' : '↓'}';
      case _PriceSortSectionType.price:
        final minText = _minController.text.trim();
        final maxText = _maxController.text.trim();
        if (minText.isEmpty && maxText.isEmpty) {
          return null;
        }
        if (minText.isNotEmpty && maxText.isNotEmpty) {
          return '$minText-$maxText';
        }
        if (minText.isNotEmpty) {
          return '>=$minText';
        }
        return '<=$maxText';
      case _PriceSortSectionType.state:
        if (_sellableOnly) {
          return 'app.market.product.sellable'.tr;
        }
        if (_coolingOnly) {
          return 'app.market.product.cooling'.tr;
        }
        return null;
    }
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSortSection(_PriceSortSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.market.filter.sort'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.sortOptions
              .map((option) {
                return KeyedSubtree(
                  key: _selectionAnchorKey(section.key, option.field),
                  child: ChoiceChip(
                    label: Text(option.labelKey.tr),
                    selected: _sortField == option.field,
                    onSelected: (_) =>
                        setState(() => _sortField = option.field),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('↑'),
              selected: _sortAsc,
              onSelected: (_) => setState(() => _sortAsc = true),
            ),
            ChoiceChip(
              label: const Text('↓'),
              selected: !_sortAsc,
              onSelected: (_) => setState(() => _sortAsc = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colors.surface;

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.6)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.market.filter.price_range'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: buildInputDecoration(_priceLowestLabel()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: buildInputDecoration(_priceHighestLabel()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryStateSection(_PriceSortSection section) {
    Widget buildStateChip({
      required String key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return KeyedSubtree(
        key: _selectionAnchorKey(section.key, key),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.trade.order.status'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            buildStateChip(
              key: 'all',
              label: 'app.market.filter.all'.tr,
              selected: !_sellableOnly && !_coolingOnly,
              onTap: () => setState(() {
                _sellableOnly = false;
                _coolingOnly = false;
              }),
            ),
            buildStateChip(
              key: 'sellable',
              label: 'app.market.product.sellable'.tr,
              selected: _sellableOnly,
              onTap: () => setState(() {
                final next = !_sellableOnly;
                _sellableOnly = next;
                _coolingOnly = false;
              }),
            ),
            buildStateChip(
              key: 'cooling',
              label: 'app.market.product.cooling'.tr,
              selected: _coolingOnly,
              onTap: () => setState(() {
                final next = !_coolingOnly;
                _coolingOnly = next;
                _sellableOnly = false;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionContent(_PriceSortSection section) {
    switch (section.type) {
      case _PriceSortSectionType.sort:
        return _buildSortSection(section);
      case _PriceSortSectionType.price:
        return _buildPriceSection();
      case _PriceSortSectionType.state:
        return _buildInventoryStateSection(section);
    }
  }

  Widget _buildSectionTabs(List<_PriceSortSection> sections) {
    final colors = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final selected = index == _currentSectionIndex;
        final summary = _sectionSummary(section);
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (index == _currentSectionIndex) {
                _scheduleScrollToSectionSelection(section);
                return;
              }
              setState(() {
                _currentSectionIndex = index;
              });
              _scheduleScrollToSectionSelection(section);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.16)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.45)
                      : colors.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    section.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? colors.primary.withValues(alpha: 0.86)
                            : colors.onSurfaceVariant.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    if (sections.isNotEmpty && _currentSectionIndex >= sections.length) {
      _currentSectionIndex = 0;
    }
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          children: [
            Expanded(
              child: sections.isEmpty
                  ? Center(
                      child: Text(
                        'app.common.no_data'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: SingleChildScrollView(
                                key: ValueKey(
                                  sections[_currentSectionIndex].key,
                                ),
                                child: _buildSectionContent(
                                  sections[_currentSectionIndex],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 104,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.outline.withValues(alpha: 0.15),
                            ),
                          ),
                          child: _buildSectionTabs(sections),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text('app.market.filter.reset'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text('app.common.cancel'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text('app.market.filter.finish'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _PriceSortSectionType { sort, price, state }

class _PriceSortSection {
  const _PriceSortSection({required this.type, required this.labelKey});

  final _PriceSortSectionType type;
  final String labelKey;

  String get key => labelKey;
}
