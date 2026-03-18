import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';
import 'package:tronskins_app/components/filter/market_filter_sheet.dart';

enum OrderFilterSectionCategory { attribute, price, status, date, sort }

class OrderFilterSheet extends StatefulWidget {
  const OrderFilterSheet({
    super.key,
    required this.initial,
    required this.statusOptions,
    this.sortOptions = const [],
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
    this.sectionOrder,
  });

  final OrderFilterResult initial;
  final List<StatusOption> statusOptions;
  final List<SortOption> sortOptions;
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
  final List<OrderFilterSectionCategory>? sectionOrder;

  static Future<OrderFilterResult?> showFromRight({
    required BuildContext context,
    required OrderFilterResult initial,
    required List<StatusOption> statusOptions,
    List<SortOption> sortOptions = const [],
    String titleKey = 'app.market.filter.text',
    bool showSort = false,
    bool showStatus = true,
    bool showDateRange = true,
    bool enableAttributeFilter = false,
    int? appId,
    List<SortOption> attributeSortOptions = const [],
    bool attributeShowSort = false,
    bool attributeShowPriceRange = false,
    List<OrderFilterSectionCategory>? sectionOrder,
  }) {
    final barrierLabel = MaterialLocalizations.of(
      context,
    ).modalBarrierDismissLabel;
    return showGeneralDialog<OrderFilterResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final width = MediaQuery.of(dialogContext).size.width;
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            child: Material(
              color: Colors.transparent,
              child: OrderFilterSheet(
                initial: initial,
                statusOptions: statusOptions,
                sortOptions: sortOptions,
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
                sectionOrder: sectionOrder,
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
  int _currentSectionIndex = 0;
  bool _sortAsc = false;
  late String _sortField;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late String _attributeSortField;
  late bool _attributeSortAsc;
  late Map<String, dynamic> _attributeTags;
  String? _attributeItemName;
  List<MarketFilterGroupMeta> _attributeGroups = const [];
  bool _attributeGroupsLoading = false;
  bool _hasScheduledAttributeLoad = false;
  bool _isFetchingAttributeGroups = false;
  final Map<String, GlobalKey> _selectionAnchorKeys = {};

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _sortAsc = widget.initial.sortAsc ?? false;
    _sortField =
        widget.initial.sortField ??
        (widget.sortOptions.isNotEmpty
            ? widget.sortOptions.first.field
            : 'time');
    _minController = TextEditingController(
      text: widget.initial.priceMin?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.priceMax?.toString() ?? '',
    );
    _attributeSortField =
        widget.initial.sortField ??
        (widget.attributeSortOptions.isNotEmpty
            ? widget.attributeSortOptions.first.field
            : 'time');
    _attributeSortAsc = widget.initial.sortAsc ?? false;
    _attributeTags = Map<String, dynamic>.from(widget.initial.tags ?? const {});
    _attributeItemName = widget.initial.itemName;
    if (widget.enableAttributeFilter && widget.appId != null) {
      _primeAttributeGroups();
      if (_attributeGroups.isEmpty) {
        _attributeGroupsLoading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleAttributeGroupLoad();
        });
      }
    }
    if (widget.initial.statusList != null) {
      final index = widget.statusOptions.indexWhere(
        (option) => _listEquals(option.values, widget.initial.statusList!),
      );
      _selectedStatusIndex = index;
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
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
      _sortField = widget.sortOptions.isNotEmpty
          ? widget.sortOptions.first.field
          : 'time';
      _selectedStatusIndex = -1;
      _startDate = null;
      _endDate = null;
      _minController.clear();
      _maxController.clear();
      _attributeSortField = widget.attributeSortOptions.isNotEmpty
          ? widget.attributeSortOptions.first.field
          : 'time';
      _attributeSortAsc = false;
      _attributeTags = <String, dynamic>{};
      _attributeItemName = null;
    });
  }

  void _resetAndApply() {
    _reset();
    Navigator.of(context).pop(
      const OrderFilterResult(
        sortAsc: false,
        sortField: null,
        priceMin: null,
        priceMax: null,
        tags: <String, dynamic>{},
        itemName: '',
        reset: true,
      ),
    );
  }

  void _primeAttributeGroups() {
    final appId = widget.appId;
    if (appId == null) {
      return;
    }
    _attributeGroups = MarketFilterSheet.cachedGroupMetas(appId: appId);
  }

  Future<void> _scheduleAttributeGroupLoad() async {
    if (_hasScheduledAttributeLoad || _attributeGroups.isNotEmpty) {
      return;
    }
    _hasScheduledAttributeLoad = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) {
      return;
    }
    await _loadAttributeGroups();
  }

  Future<void> _loadAttributeGroups() async {
    final appId = widget.appId;
    if (appId == null || _isFetchingAttributeGroups) {
      return;
    }
    _isFetchingAttributeGroups = true;
    if (mounted) {
      setState(() => _attributeGroupsLoading = true);
    } else {
      _attributeGroupsLoading = true;
    }
    try {
      final groups = await MarketFilterSheet.loadGroupMetas(appId: appId);
      if (!mounted) {
        _attributeGroups = groups;
        return;
      }
      setState(() {
        _attributeGroups = groups;
      });
    } finally {
      _isFetchingAttributeGroups = false;
      if (mounted) {
        setState(() => _attributeGroupsLoading = false);
      } else {
        _attributeGroupsLoading = false;
      }
    }
  }

  bool _hasAttributeValue(String key) {
    if (key == 'type') {
      return (_attributeItemName ?? '').isNotEmpty;
    }
    final value = _attributeTags[key];
    return value != null && value.toString().isNotEmpty;
  }

  void _clearAttributeGroup(String key) {
    setState(() {
      _attributeTags.remove(key);
      if (key == 'type') {
        _attributeItemName = null;
      }
    });
  }

  GlobalKey _selectionAnchorKey(String sectionKey, String optionName) {
    final key = '$sectionKey::$optionName';
    return _selectionAnchorKeys.putIfAbsent(key, GlobalKey.new);
  }

  String? _selectedAnchorOptionName(_OrderFilterSection section) {
    switch (section.type) {
      case _OrderFilterSectionType.attribute:
      case _OrderFilterSectionType.price:
      case _OrderFilterSectionType.date:
        return null;
      case _OrderFilterSectionType.sort:
        return _sortField.isEmpty ? null : _sortField;
      case _OrderFilterSectionType.status:
        if (_selectedStatusIndex < 0 ||
            _selectedStatusIndex >= widget.statusOptions.length) {
          return null;
        }
        return 'status:$_selectedStatusIndex';
      case _OrderFilterSectionType.attributeGroup:
        final key = section.groupKey;
        if (key == null) {
          return null;
        }
        if (key == 'type') {
          return (_attributeItemName ?? '').isEmpty ? null : _attributeItemName;
        }
        final value = _attributeTags[key]?.toString() ?? '';
        return value.isEmpty ? null : value;
    }
  }

  void _scrollToSectionSelection(_OrderFilterSection section) {
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

  void _scheduleScrollToSectionSelection(_OrderFilterSection section) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToSectionSelection(section);
    });
  }

  void _apply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    Navigator.of(context).pop(
      OrderFilterResult(
        sortAsc: widget.showSort
            ? _sortAsc
            : (widget.attributeShowSort ? _attributeSortAsc : null),
        sortField: widget.showSort
            ? _sortField
            : (widget.attributeShowSort ? _attributeSortField : null),
        priceMin: widget.attributeShowPriceRange ? min : null,
        priceMax: widget.attributeShowPriceRange ? max : null,
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

  List<_OrderFilterSection> get _sections {
    final sections = <_OrderFilterSection>[];
    const defaultOrder = [
      OrderFilterSectionCategory.attribute,
      OrderFilterSectionCategory.price,
      OrderFilterSectionCategory.status,
      OrderFilterSectionCategory.date,
      OrderFilterSectionCategory.sort,
    ];
    final orderedCategories = <OrderFilterSectionCategory>[
      ...?widget.sectionOrder,
      ...defaultOrder.where(
        (category) => !(widget.sectionOrder?.contains(category) ?? false),
      ),
    ];
    for (final category in orderedCategories) {
      _appendSectionsByCategory(sections, category);
    }
    return sections;
  }

  void _appendSectionsByCategory(
    List<_OrderFilterSection> sections,
    OrderFilterSectionCategory category,
  ) {
    switch (category) {
      case OrderFilterSectionCategory.attribute:
        if (!widget.enableAttributeFilter) {
          return;
        }
        if (_attributeGroups.isEmpty) {
          sections.add(
            const _OrderFilterSection(
              type: _OrderFilterSectionType.attribute,
              labelKey: 'app.market.filter.text',
            ),
          );
          return;
        }
        sections.addAll(
          _attributeGroups.map(
            (group) => _OrderFilterSection(
              type: _OrderFilterSectionType.attributeGroup,
              labelKey: group.labelKey,
              groupKey: group.key,
            ),
          ),
        );
        return;
      case OrderFilterSectionCategory.price:
        if (!widget.attributeShowPriceRange) {
          return;
        }
        sections.add(
          const _OrderFilterSection(
            type: _OrderFilterSectionType.price,
            labelKey: 'app.market.filter.price_range',
          ),
        );
        return;
      case OrderFilterSectionCategory.status:
        if (!widget.showStatus) {
          return;
        }
        sections.add(
          const _OrderFilterSection(
            type: _OrderFilterSectionType.status,
            labelKey: 'app.trade.order.status',
          ),
        );
        return;
      case OrderFilterSectionCategory.date:
        if (!widget.showDateRange) {
          return;
        }
        sections.add(
          const _OrderFilterSection(
            type: _OrderFilterSectionType.date,
            labelKey: 'app.trade.order.date',
          ),
        );
        return;
      case OrderFilterSectionCategory.sort:
        if (!widget.showSort) {
          return;
        }
        sections.add(
          const _OrderFilterSection(
            type: _OrderFilterSectionType.sort,
            labelKey: 'app.market.filter.sort',
          ),
        );
        return;
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

  Widget _buildAttributeSection() {
    if (_attributeGroupsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('app.market.filter.text'.tr),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.market.filter.text'.tr),
        const SizedBox(height: 8),
        Text(
          'app.common.no_data'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAttributeGroupSection(_OrderFilterSection section) {
    final key = section.groupKey;
    if (key == null) {
      return _buildAttributeSection();
    }
    MarketFilterGroupMeta? group;
    for (final item in _attributeGroups) {
      if (item.key == key) {
        group = item;
        break;
      }
    }
    if (group == null) {
      return _buildAttributeSection();
    }
    final groupValue = group;
    final selectedValue = groupValue.key == 'type'
        ? (_attributeItemName ?? '')
        : (_attributeTags[groupValue.key]?.toString() ?? '');
    final hasValue = _hasAttributeValue(groupValue.key);
    final sectionKey = section.key;
    final optionEntries = groupValue.optionLabels.entries
        .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty)
        .toList(growable: false);

    void selectValue(String? value) {
      setState(() {
        if (groupValue.key == 'type') {
          _attributeItemName = (value == null || value.isEmpty) ? null : value;
        } else if (value == null || value.isEmpty) {
          _attributeTags.remove(groupValue.key);
        } else {
          _attributeTags[groupValue.key] = value;
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(groupValue.labelKey.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            KeyedSubtree(
              key: _selectionAnchorKey(sectionKey, 'all'),
              child: ChoiceChip(
                label: Text('app.market.filter.all'.tr),
                selected: selectedValue.isEmpty,
                onSelected: (_) => selectValue(null),
              ),
            ),
            ...optionEntries.map((entry) {
              return KeyedSubtree(
                key: _selectionAnchorKey(sectionKey, entry.key),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: selectedValue == entry.key,
                  onSelected: (_) => selectValue(entry.key),
                ),
              );
            }),
          ],
        ),
        if (optionEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'app.common.no_data'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (hasValue)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _clearAttributeGroup(groupValue.key),
              icon: const Icon(Icons.restart_alt, size: 16),
              label: Text('app.market.filter.clear'.tr),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSection(_OrderFilterSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.trade.order.status'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(widget.statusOptions.length, (index) {
            final option = widget.statusOptions[index];
            final selected = _selectedStatusIndex == index;
            return KeyedSubtree(
              key: _selectionAnchorKey(section.key, 'status:$index'),
              child: FilterChip(
                label: Text(option.labelKey.tr),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    _selectedStatusIndex = value ? index : -1;
                  });
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.trade.order.date'.tr),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                title: 'app.market.filter.date_start'.tr,
                value: _formatDate(_startDate),
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateField(
                title: 'app.market.filter.date_end'.tr,
                value: _formatDate(_endDate),
                onTap: _pickEndDate,
              ),
            ),
          ],
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
                decoration: buildInputDecoration(
                  'app.market.filter.price_lowest'.tr,
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
                decoration: buildInputDecoration(
                  'app.market.filter.price_highest'.tr,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection(_OrderFilterSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('app.market.filter.sort'.tr),
        const SizedBox(height: 8),
        if (widget.sortOptions.isNotEmpty) ...[
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
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('↑'),
              selected: _sortAsc,
              onSelected: (_) => setState(() => _sortAsc = true),
            ),
            ChoiceChip(
              label: Text('↓'),
              selected: !_sortAsc,
              onSelected: (_) => setState(() => _sortAsc = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionContent(_OrderFilterSection section) {
    switch (section.type) {
      case _OrderFilterSectionType.attribute:
        return _buildAttributeSection();
      case _OrderFilterSectionType.attributeGroup:
        return _buildAttributeGroupSection(section);
      case _OrderFilterSectionType.price:
        return _buildPriceSection();
      case _OrderFilterSectionType.status:
        return _buildStatusSection(section);
      case _OrderFilterSectionType.date:
        return _buildDateSection();
      case _OrderFilterSectionType.sort:
        return _buildSortSection(section);
    }
  }

  String? _sectionSummary(_OrderFilterSection section) {
    switch (section.type) {
      case _OrderFilterSectionType.attribute:
        return null;
      case _OrderFilterSectionType.attributeGroup:
        final key = section.groupKey;
        if (key == null) {
          return null;
        }
        final selectedValue = key == 'type'
            ? (_attributeItemName ?? '')
            : (_attributeTags[key]?.toString() ?? '');
        if (selectedValue.isEmpty) {
          return null;
        }
        MarketFilterGroupMeta? group;
        for (final item in _attributeGroups) {
          if (item.key == key) {
            group = item;
            break;
          }
        }
        return group?.labelForValue(selectedValue) ?? selectedValue;
      case _OrderFilterSectionType.price:
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
      case _OrderFilterSectionType.status:
        if (_selectedStatusIndex < 0 ||
            _selectedStatusIndex >= widget.statusOptions.length) {
          return null;
        }
        return widget.statusOptions[_selectedStatusIndex].labelKey.tr;
      case _OrderFilterSectionType.date:
        if (_startDate == null && _endDate == null) {
          return null;
        }
        final startText = _startDate == null
            ? null
            : '${_startDate!.month}/${_startDate!.day}';
        final endText = _endDate == null
            ? null
            : '${_endDate!.month}/${_endDate!.day}';
        if (startText != null && endText != null) {
          return '$startText-$endText';
        }
        if (startText != null) {
          return '>=$startText';
        }
        return '<=$endText';
      case _OrderFilterSectionType.sort:
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
    }
  }

  Widget _buildSectionTabs(List<_OrderFilterSection> sections) {
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
    final body = SafeArea(
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
                                  '${sections[_currentSectionIndex].type.name}:'
                                  '${sections[_currentSectionIndex].groupKey ?? ''}',
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
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text('app.common.cancel'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetAndApply,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Text('app.market.filter.reset'.tr),
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
    if (!widget.isSideSheet) {
      return body;
    }
    return Container(color: colors.surface, child: body);
  }
}

enum _OrderFilterSectionType {
  attribute,
  attributeGroup,
  price,
  status,
  date,
  sort,
}

class _OrderFilterSection {
  const _OrderFilterSection({
    required this.type,
    required this.labelKey,
    this.groupKey,
  });

  final _OrderFilterSectionType type;
  final String labelKey;
  final String? groupKey;

  String get key {
    if (type == _OrderFilterSectionType.attributeGroup && groupKey != null) {
      return 'group:$groupKey';
    }
    return labelKey;
  }
}
