import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_filter_models.dart';
import 'package:tronskins_app/components/filter/filter_models.dart';

class MarketFilterSheet extends StatefulWidget {
  const MarketFilterSheet({
    super.key,
    required this.appId,
    required this.sortOptions,
    required this.initial,
    this.titleKey = 'app.market.filter.text',
    this.showPriceRange = true,
    this.showSort = true,
    this.showStatus = false,
    this.showDateRange = false,
    this.statusOptions = const [],
    this.isSideSheet = false,
    this.initialGroupKey,
  });

  final int appId;
  final List<SortOption> sortOptions;
  final MarketFilterResult initial;
  final String titleKey;
  final bool showPriceRange;
  final bool showSort;
  final bool showStatus;
  final bool showDateRange;
  final List<StatusOption> statusOptions;
  final bool isSideSheet;
  final String? initialGroupKey;

  static final GetStorage _box = GetStorage();
  static final Map<int, Map<String, List<_AttributeGroup>>> _memoryCache = {};
  static final Map<String, Future<List<_AttributeGroup>>> _inflight = {};
  static final Map<int, Map<String, int>> _memoryTs = {};
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const String _cacheDataKey = '__data';
  static const String _cacheTsKey = '__ts';

  static Future<MarketFilterResult?> showFromRight({
    required BuildContext context,
    required int appId,
    required List<SortOption> sortOptions,
    required MarketFilterResult initial,
    String titleKey = 'app.market.filter.text',
    bool showPriceRange = true,
    bool showSort = true,
    bool showStatus = false,
    bool showDateRange = false,
    List<StatusOption> statusOptions = const [],
    String? initialGroupKey,
  }) {
    final barrierLabel = MaterialLocalizations.of(
      context,
    ).modalBarrierDismissLabel;
    return showGeneralDialog<MarketFilterResult>(
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
              child: MarketFilterSheet(
                appId: appId,
                sortOptions: sortOptions,
                initial: initial,
                titleKey: titleKey,
                showPriceRange: showPriceRange,
                showSort: showSort,
                showStatus: showStatus,
                showDateRange: showDateRange,
                statusOptions: statusOptions,
                isSideSheet: true,
                initialGroupKey: initialGroupKey,
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

  static Future<void> preload({required int appId}) async {
    await Future<void>.delayed(Duration.zero);
    await _loadGroups(appId);
  }

  static Future<List<MarketFilterGroupMeta>> loadGroupMetas({
    required int appId,
  }) async {
    final groups = await _loadGroups(appId);
    return groups
        .map(
          (group) => MarketFilterGroupMeta(
            key: group.key,
            labelKey: group.label,
            optionLabels: _buildOptionLabelMap(group),
          ),
        )
        .toList(growable: false);
  }

  static Map<String, String> _buildOptionLabelMap(_AttributeGroup group) {
    final labels = <String, String>{};
    for (final option in group.options) {
      if (!option.isUnlimited && option.name.isNotEmpty) {
        labels[option.name] = option.label;
      }
      for (final sub in option.subOptions) {
        if (!sub.isUnlimited && sub.name.isNotEmpty) {
          labels[sub.name] = sub.label;
        }
      }
    }
    for (final heroSection in group.heroSections) {
      for (final hero in heroSection.heroes) {
        if (!hero.isUnlimited && hero.name.isNotEmpty) {
          labels[hero.name] = hero.label;
        }
      }
    }
    return labels;
  }

  static String _localeKeyStatic() {
    final locale = Get.locale;
    if (locale == null) return 'en_US';
    final country = locale.countryCode;
    return country == null
        ? locale.languageCode
        : '${locale.languageCode}_$country';
  }

  static bool _isExpired(int ts, int now) {
    if (ts <= 0) return true;
    return (now - ts) > _cacheTtl.inMilliseconds;
  }

  static _CachePayload? _readCachePayload(int appId, String localeKey) {
    final cacheKey = 'schema_tags_$appId';
    final cached = _box.read<Map<String, dynamic>>(cacheKey);
    final cachedData = cached?[localeKey];
    if (cachedData is Map<String, dynamic>) {
      if (cachedData.containsKey(_cacheDataKey)) {
        final raw = cachedData[_cacheDataKey];
        final tsValue = cachedData[_cacheTsKey];
        final ts = tsValue is int
            ? tsValue
            : int.tryParse(tsValue?.toString() ?? '') ?? 0;
        if (raw is Map<String, dynamic>) {
          return _CachePayload(raw, ts);
        }
      }
      return _CachePayload(cachedData, 0);
    }
    return null;
  }

  static Future<void> _writeCache(
    int appId,
    String localeKey,
    Map<String, dynamic> raw,
  ) async {
    final cacheKey = 'schema_tags_$appId';
    final cached =
        _box.read<Map<String, dynamic>>(cacheKey) ?? <String, dynamic>{};
    cached[localeKey] = <String, dynamic>{
      _cacheTsKey: DateTime.now().millisecondsSinceEpoch,
      _cacheDataKey: raw,
    };
    await _box.write(cacheKey, cached);
  }

  static Future<List<_AttributeGroup>> _fetchAndCache(
    int appId,
    String localeKey,
  ) async {
    try {
      final api = ApiMarketServer();
      final res = await api.marketAttributeList(appId: appId);
      final data = res.datas?.data;
      if (data != null && data.isNotEmpty) {
        await _writeCache(appId, localeKey, data);
        final groups = _buildGroupsStatic(appId, data);
        _memoryCache.putIfAbsent(appId, () => {})[localeKey] = groups;
        _memoryTs.putIfAbsent(appId, () => {})[localeKey] =
            DateTime.now().millisecondsSinceEpoch;
        return groups;
      }
      return <_AttributeGroup>[];
    } catch (_) {
      return <_AttributeGroup>[];
    }
  }

  static Future<List<_AttributeGroup>> _awaitFetch(
    int appId,
    String localeKey,
  ) async {
    final inflightKey = '$appId:$localeKey';
    final existing = _inflight[inflightKey];
    if (existing != null) {
      return existing;
    }
    final task = _fetchAndCache(appId, localeKey);
    _inflight[inflightKey] = task;
    try {
      return await task;
    } finally {
      _inflight.remove(inflightKey);
    }
  }

  static void _refreshInBackground(int appId, String localeKey) {
    final inflightKey = '$appId:$localeKey';
    if (_inflight.containsKey(inflightKey)) {
      return;
    }
    _awaitFetch(appId, localeKey);
  }

  static Future<List<_AttributeGroup>> _loadGroups(int appId) async {
    final localeKey = _localeKeyStatic();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedByLocale = _memoryCache[appId];
    final memoryGroups = cachedByLocale?[localeKey];
    if (memoryGroups != null) {
      final ts = _memoryTs[appId]?[localeKey] ?? 0;
      if (_isExpired(ts, now)) {
        _refreshInBackground(appId, localeKey);
      }
      return memoryGroups;
    }

    final payload = _readCachePayload(appId, localeKey);
    if (payload != null) {
      final groups = _buildGroupsStatic(appId, payload.raw);
      _memoryCache.putIfAbsent(appId, () => {})[localeKey] = groups;
      _memoryTs.putIfAbsent(appId, () => {})[localeKey] = payload.ts;
      if (_isExpired(payload.ts, now)) {
        _refreshInBackground(appId, localeKey);
      }
      return groups;
    }

    return _awaitFetch(appId, localeKey);
  }

  @override
  State<MarketFilterSheet> createState() => _MarketFilterSheetState();
}

class _MarketFilterSheetState extends State<MarketFilterSheet> {
  static final GetStorage _box = MarketFilterSheet._box;

  late String _sortField;
  late bool _sortAsc;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedStatusIndex = -1;

  final Map<String, String?> _selectedTags = {};
  String? _selectedItemName;
  List<_AttributeGroup> _groups = [];
  bool _isLoading = true;
  bool _hasLoadScheduled = false;
  bool _entered = false;
  bool _showAttributes = false;
  List<_FilterSection> _sections = [];
  int _currentSectionIndex = 0;
  int _slideDirection = 1;
  bool _hasAppliedInitialGroupKey = false;

  @override
  void initState() {
    super.initState();
    _sortField = widget.initial.sortField;
    _sortAsc = widget.initial.sortAsc;
    _minController = TextEditingController(
      text: widget.initial.priceMin?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.priceMax?.toString() ?? '',
    );
    if (widget.initial.tags != null) {
      widget.initial.tags!.forEach((key, value) {
        _selectedTags[key] = value?.toString();
      });
    }
    _selectedItemName = widget.initial.itemName;
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _selectedStatusIndex = _resolveInitialStatusIndex();
    _primeCache();
    _rebuildSections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleLoad();
      if (mounted) {
        setState(() => _entered = true);
      }
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final delay = disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 320);
      Future<void>.delayed(delay, () {
        if (!mounted || _showAttributes) {
          return;
        }
        setState(() => _showAttributes = true);
      });
    });
  }

  int _resolveInitialStatusIndex() {
    if (!widget.showStatus || widget.statusOptions.isEmpty) {
      return -1;
    }
    final initialStatusList = widget.initial.statusList;
    if (initialStatusList == null || initialStatusList.isEmpty) {
      return -1;
    }
    return widget.statusOptions.indexWhere(
      (option) => _listEquals(option.values, initialStatusList),
    );
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

  void _primeCache() {
    final localeKey = _localeKey();
    final memory = MarketFilterSheet._memoryCache[widget.appId];
    final memoryGroups = memory?[localeKey];
    if (memoryGroups != null) {
      _groups = memoryGroups;
      _isLoading = false;
      _rebuildSections();
      final ts = MarketFilterSheet._memoryTs[widget.appId]?[localeKey] ?? 0;
      if (MarketFilterSheet._isExpired(
        ts,
        DateTime.now().millisecondsSinceEpoch,
      )) {
        MarketFilterSheet._refreshInBackground(widget.appId, localeKey);
      }
      return;
    }
    final payload = MarketFilterSheet._readCachePayload(
      widget.appId,
      localeKey,
    );
    if (payload != null) {
      _groups = _buildGroups(payload.raw);
      MarketFilterSheet._memoryCache.putIfAbsent(
        widget.appId,
        () => {},
      )[localeKey] = _groups;
      MarketFilterSheet._memoryTs.putIfAbsent(
        widget.appId,
        () => {},
      )[localeKey] = payload.ts;
      _isLoading = false;
      _rebuildSections();
      if (MarketFilterSheet._isExpired(
        payload.ts,
        DateTime.now().millisecondsSinceEpoch,
      )) {
        MarketFilterSheet._refreshInBackground(widget.appId, localeKey);
      }
    }
  }

  Future<void> _scheduleLoad() async {
    if (_groups.isNotEmpty || _hasLoadScheduled) {
      return;
    }
    _hasLoadScheduled = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _loadAttributes();
    }
  }

  void _rebuildSections() {
    final sections = <_FilterSection>[];
    if (widget.showSort) {
      sections.add(
        const _FilterSection(
          type: _SectionType.sort,
          labelKey: 'app.market.filter.sort',
        ),
      );
    }
    if (widget.showPriceRange) {
      sections.add(
        const _FilterSection(
          type: _SectionType.price,
          labelKey: 'app.market.filter.price_range',
        ),
      );
    }
    for (final group in _groups) {
      sections.add(
        _FilterSection(
          type: _SectionType.group,
          labelKey: group.label,
          group: group,
        ),
      );
    }
    if (widget.showStatus) {
      sections.add(
        const _FilterSection(
          type: _SectionType.status,
          labelKey: 'app.trade.order.status',
        ),
      );
    }
    if (widget.showDateRange) {
      sections.add(
        const _FilterSection(
          type: _SectionType.date,
          labelKey: 'app.trade.order.date',
        ),
      );
    }
    _sections = sections;
    if (_currentSectionIndex >= _sections.length) {
      _currentSectionIndex = 0;
    }
    _applyInitialGroupSection();
  }

  void _applyInitialGroupSection() {
    if (_hasAppliedInitialGroupKey) {
      return;
    }
    final targetKey = widget.initialGroupKey;
    if (targetKey == null || targetKey.isEmpty) {
      _hasAppliedInitialGroupKey = true;
      return;
    }
    final index = _sections.indexWhere(
      (section) =>
          section.type == _SectionType.group && section.group?.key == targetKey,
    );
    if (index < 0) {
      return;
    }
    _currentSectionIndex = index;
    _hasAppliedInitialGroupKey = true;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _loadAttributes() async {
    if (_groups.isNotEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final groups = await MarketFilterSheet._loadGroups(widget.appId);
    if (!mounted) {
      _groups = groups;
      return;
    }
    setState(() {
      _groups = groups;
      _rebuildSections();
      _isLoading = false;
    });
  }

  String _localeKey() {
    return MarketFilterSheet._localeKeyStatic();
  }

  List<_AttributeGroup> _buildGroups(Map<String, dynamic> raw) {
    return _buildGroupsStatic(widget.appId, raw);
  }

  _AttributeGroup _buildGroup(
    String key,
    Map<String, dynamic> group,
    String unlimitedLabel,
  ) {
    return _buildGroupStatic(key, group, unlimitedLabel);
  }

  List<_AttributeOption> _parseOptions(List list) {
    return _parseOptionsStatic(list);
  }

  List<_AttributeOption> _withUnlimited(
    List<_AttributeOption> options,
    String unlimitedLabel,
  ) {
    return _withUnlimitedStatic(options, unlimitedLabel);
  }

  void _reset() {
    final resetField = widget.sortOptions.isNotEmpty
        ? widget.sortOptions.first.field
        : _sortField;
    Navigator.of(context).pop(
      MarketFilterResult(
        sortField: resetField,
        sortAsc: false,
        priceMin: null,
        priceMax: null,
        tags: <String, dynamic>{},
        itemName: '',
        statusList: null,
        startDate: null,
        endDate: null,
        clearKeyword: true,
      ),
    );
  }

  void _apply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    final tags = Map<String, dynamic>.from(_selectedTags)
      ..removeWhere(
        (key, value) => value == null || value == '' || value == 'unlimited',
      );
    Navigator.of(context).pop(
      MarketFilterResult(
        sortField: _sortField,
        sortAsc: _sortAsc,
        priceMin: min,
        priceMax: max,
        tags: tags,
        itemName: _selectedItemName ?? '',
        statusList: widget.showStatus && _selectedStatusIndex >= 0
            ? widget.statusOptions[_selectedStatusIndex].values
            : null,
        startDate: widget.showDateRange ? _startDate : null,
        endDate: widget.showDateRange ? _endDate : null,
      ),
    );
  }

  bool _isGroupSelected(String key, _AttributeOption option) {
    final selected = _selectedTags[key];
    if (option.isUnlimited) {
      return selected == null;
    }
    return selected == option.name;
  }

  void _selectOption(String key, _AttributeOption option) {
    setState(() {
      if (option.isUnlimited) {
        _selectedTags.remove(key);
        if (key == 'type') {
          _selectedItemName = null;
        }
        return;
      }
      _selectedTags[key] = option.name;
    });
  }

  void _selectSubOption(_AttributeGroup group, _AttributeOption option) {
    setState(() {
      if (option.isUnlimited) {
        _selectedItemName = null;
        _selectedTags.remove(group.key);
        return;
      }
      _selectedItemName = option.name;
      if (option.parentName != null && option.parentName!.isNotEmpty) {
        _selectedTags[group.key] = option.parentName;
      } else {
        _selectedTags[group.key] = option.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animationDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
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
              child: _buildTabbedBody(
                surface: colors.surface,
                borderColor: colors.outline.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionBar(context),
          ],
        ),
      ),
    );
    final sheet = AnimatedOpacity(
      opacity: _entered ? 1 : 0,
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      child: body,
    );
    if (!widget.isSideSheet) {
      return sheet;
    }
    return Dismissible(
      key: const ValueKey('market_filter_sheet'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.2},
      background: const SizedBox.shrink(),
      onDismissed: (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(color: colors.surface, child: sheet),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildChip(
    String label, {
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
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
            onPressed: _reset,
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
    );
  }

  Widget _buildTabbedBody({
    required Color surface,
    required Color borderColor,
  }) {
    if (_sections.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Text(
          'app.common.no_data'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: _showAttributes
                ? _buildSectionContent()
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: _buildSectionTabs(),
        ),
      ],
    );
  }

  Widget _buildSectionTabs() {
    final colors = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        final selected = index == _currentSectionIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (index == _currentSectionIndex) {
                return;
              }
              setState(() {
                _slideDirection = index < _currentSectionIndex ? -1 : 1;
                _currentSectionIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.16)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.45)
                      : colors.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                section.labelKey.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionContent() {
    final section = _sections[_currentSectionIndex];
    List<Widget> children;
    switch (section.type) {
      case _SectionType.sort:
        children = _buildSortSection();
        break;
      case _SectionType.price:
        children = _buildPriceSection();
        break;
      case _SectionType.status:
        children = _buildStatusSection();
        break;
      case _SectionType.date:
        children = _buildDateSection();
        break;
      case _SectionType.group:
        children = [
          if (section.group != null) _buildGroupSection(section.group!),
        ];
        break;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final tween = Tween<Offset>(
              begin: Offset(0.06 * _slideDirection, 0),
              end: Offset.zero,
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey(section.key),
            height: constraints.maxHeight,
            width: double.infinity,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [...children, const SizedBox(height: 8)],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSortSection() {
    return [
      _buildSectionTitle('app.market.filter.sort'.tr),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.sortOptions.map((option) {
          final selected = _sortField == option.field;
          return _buildChip(
            option.labelKey.tr,
            selected: selected,
            onSelected: (_) => setState(() => _sortField = option.field),
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
      _buildSortDirectionToggle(),
    ];
  }

  Widget _buildSortDirectionToggle() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          '↑',
          selected: _sortAsc,
          onSelected: (_) => setState(() => _sortAsc = true),
        ),
        _buildChip(
          '↓',
          selected: !_sortAsc,
          onSelected: (_) => setState(() => _sortAsc = false),
        ),
      ],
    );
  }

  List<Widget> _buildPriceSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.06) : colors.surface;
    return [
      const SizedBox(height: 8),
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
              decoration: InputDecoration(
                filled: true,
                fillColor: fillColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                labelText: 'app.market.filter.price_lowest'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.outline.withOpacity(0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.outline.withOpacity(0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.primary.withOpacity(0.6),
                  ),
                ),
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
                filled: true,
                fillColor: fillColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                labelText: 'app.market.filter.price_highest'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.outline.withOpacity(0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.outline.withOpacity(0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.primary.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStatusSection() {
    return [
      _buildSectionTitle('app.trade.order.status'.tr),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
    ];
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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

  List<Widget> _buildDateSection() {
    return [
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
    ];
  }

  Widget _buildHeroGroupSection(_AttributeGroup group) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedHero = _selectedTags['hero'];
    final isUnlimited = selectedHero == null;
    final headerTint = isDark
        ? colors.surfaceVariant.withOpacity(0.22)
        : colors.surfaceVariant.withOpacity(0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle(group.label.tr),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _selectedTags.remove('hero');
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUnlimited
                        ? colors.primary.withOpacity(0.12)
                        : headerTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlimited
                          ? colors.primary.withOpacity(0.5)
                          : colors.outline.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    'app.common.unlimited'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnlimited
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: isUnlimited
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...group.heroSections.map(
            (section) => _buildHeroSection(section, selectedHero),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(_HeroSection section, String? selectedHero) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.labelKey.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final minTileWidth = 78.0;
              final count = (width / minTileWidth).floor().clamp(3, 5).toInt();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.heroes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final hero = section.heroes[index];
                  final selected = selectedHero == hero.name;
                  return _buildHeroTile(hero, selected: selected);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTile(_AttributeOption hero, {required bool selected}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final name = hero.label;
    final imageUrl = hero.imageUrl;
    final placeholder = isDark ? colors.surfaceVariant : colors.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectOption('hero', hero),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withOpacity(0.12)
                : colors.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colors.primary.withOpacity(0.55)
                  : colors.outline.withOpacity(0.12),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: placeholder,
                    alignment: Alignment.center,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 26,
                            color: colors.onSurfaceVariant,
                          )
                        : _buildHeroImage(imageUrl),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String url) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    const displaySize = 52.0;
    final cacheSize = (displaySize * devicePixelRatio).round();
    return Image.network(
      url,
      width: displaySize,
      height: displaySize,
      fit: BoxFit.cover,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: 26,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final overlayColor = Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.35);
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            ColoredBox(color: overlayColor),
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupSection(_AttributeGroup group) {
    if (group.isHeroGroup) {
      return _buildHeroGroupSection(group);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(group.label.tr),
          const SizedBox(height: 8),
          if (group.hasSubOptions)
            _buildSubOptionGroup(group)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.options
                  .map(
                    (option) => _buildChip(
                      option.label.tr,
                      selected: _isGroupSelected(group.key, option),
                      onSelected: (_) => _selectOption(group.key, option),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSubOptionGroup(_AttributeGroup group) {
    final unlimitedLabel = 'app.common.unlimited'.tr;
    final selected = _selectedItemName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              unlimitedLabel,
              selected: selected == null,
              onSelected: (_) => _selectSubOption(
                group,
                _AttributeOption(
                  name: 'unlimited',
                  label: unlimitedLabel,
                  isUnlimited: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.options.map((option) {
          if (option.subOptions.isEmpty) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  option.label.tr,
                  selected: selected == option.name,
                  onSelected: (_) => _selectSubOption(group, option),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: option.subOptions
                    .map(
                      (sub) => _buildChip(
                        sub.label.tr,
                        selected: selected == sub.name,
                        onSelected: (_) => _selectSubOption(group, sub),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }
}

List<_AttributeGroup> _buildGroupsStatic(int appId, Map<String, dynamic> raw) {
  final unlimitedLabel = 'app.common.unlimited'.tr;
  final groups = <_AttributeGroup>[];

  if (appId == 570) {
    final heroSections = <_HeroSection>[];
    final heroOptions = <_AttributeOption>[];
    const heroKeys = [
      'heroStrength',
      'heroAgility',
      'heroIntellect',
      'heroAll',
    ];
    const heroLabelMap = {
      'heroStrength': 'app.market.dota2.hero_strength',
      'heroAgility': 'app.market.dota2.hero_agility',
      'heroIntellect': 'app.market.dota2.hero_intellect',
      'heroAll': 'app.market.dota2.hero_all',
    };
    for (final key in heroKeys) {
      final group = raw[key];
      if (group is Map<String, dynamic>) {
        final list = group['list'];
        final base = group['base']?.toString() ?? '';
        if (list is List) {
          final heroes = _parseHeroOptionsStatic(list, base);
          if (heroes.isNotEmpty) {
            heroOptions.addAll(heroes);
            heroSections.add(
              _HeroSection(
                labelKey: heroLabelMap[key] ?? 'app.market.dota2.hero',
                heroes: heroes,
              ),
            );
          }
        }
      }
    }
    if (heroSections.isNotEmpty) {
      groups.add(
        _AttributeGroup(
          key: 'hero',
          label: 'app.market.dota2.hero',
          options: heroOptions,
          heroSections: heroSections,
        ),
      );
    }
    for (final key in ['slot', 'type', 'quality', 'rarity']) {
      final group = raw[key];
      if (group is Map<String, dynamic>) {
        groups.add(_buildGroupStatic(key, group, unlimitedLabel));
      }
    }
  } else {
    final preferred = ['type', 'exterior', 'quality', 'rarity', 'itemSet'];
    final used = <String>{};
    const skipKeys = {'weapon'};
    for (final key in preferred) {
      final group = raw[key];
      if (group is Map<String, dynamic>) {
        groups.add(_buildGroupStatic(key, group, unlimitedLabel));
        used.add(key);
      }
    }
    raw.forEach((key, value) {
      if (used.contains(key) || skipKeys.contains(key)) return;
      if (value is Map<String, dynamic>) {
        groups.add(_buildGroupStatic(key, value, unlimitedLabel));
      }
    });
  }
  return groups
      .where((group) => group.options.isNotEmpty || group.isHeroGroup)
      .toList();
}

_AttributeGroup _buildGroupStatic(
  String key,
  Map<String, dynamic> group,
  String unlimitedLabel,
) {
  final label = group['label']?.toString() ?? key;
  final list = group['list'];
  final options = list is List
      ? _parseOptionsStatic(list)
      : <_AttributeOption>[];
  final hasSubOptions = options.any((option) => option.subOptions.isNotEmpty);
  final normalized = hasSubOptions
      ? options
      : _withUnlimitedStatic(options, unlimitedLabel);
  return _AttributeGroup(
    key: key,
    label: label,
    options: normalized,
    hasSubOptions: hasSubOptions,
  );
}

List<_AttributeOption> _parseOptionsStatic(List list) {
  return list.whereType<Map<String, dynamic>>().map((item) {
    final name = item['name']?.toString() ?? '';
    final label = item['localized_name']?.toString() ?? name;
    final subTypes = item['subTypes'];
    final subOptions = <_AttributeOption>[];
    if (subTypes is List) {
      for (final sub in subTypes) {
        if (sub is Map<String, dynamic>) {
          final subKey = sub['key']?.toString() ?? '';
          final subLabel =
              sub['value']?.toString() ??
              sub['localized_name']?.toString() ??
              subKey;
          subOptions.add(
            _AttributeOption(name: subKey, label: subLabel, parentName: name),
          );
        }
      }
    }
    return _AttributeOption(
      name: name,
      label: label,
      isUnlimited: name.toLowerCase() == 'unlimited',
      subOptions: subOptions,
    );
  }).toList();
}

List<_AttributeOption> _parseHeroOptionsStatic(List list, String base) {
  return list.whereType<Map<String, dynamic>>().map((item) {
    final name = item['name']?.toString() ?? '';
    final label = item['localized_name']?.toString() ?? name;
    final imageUrl = base.isEmpty ? null : '$base$name.jpg';
    return _AttributeOption(name: name, label: label, imageUrl: imageUrl);
  }).toList();
}

List<_AttributeOption> _withUnlimitedStatic(
  List<_AttributeOption> options,
  String unlimitedLabel,
) {
  final exists = options.any((option) => option.isUnlimited);
  if (exists) return options;
  return [
    _AttributeOption(
      name: 'unlimited',
      label: unlimitedLabel,
      isUnlimited: true,
    ),
    ...options,
  ];
}

class MarketFilterGroupMeta {
  const MarketFilterGroupMeta({
    required this.key,
    required this.labelKey,
    required this.optionLabels,
  });

  final String key;
  final String labelKey;
  final Map<String, String> optionLabels;

  String? labelForValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return optionLabels[value.toString()];
  }
}

class _AttributeGroup {
  const _AttributeGroup({
    required this.key,
    required this.label,
    required this.options,
    this.hasSubOptions = false,
    this.heroSections = const [],
  });

  final String key;
  final String label;
  final List<_AttributeOption> options;
  final bool hasSubOptions;
  final List<_HeroSection> heroSections;

  bool get isHeroGroup => heroSections.isNotEmpty;
}

class _AttributeOption {
  const _AttributeOption({
    required this.name,
    required this.label,
    this.subOptions = const [],
    this.parentName,
    this.isUnlimited = false,
    this.imageUrl,
  });

  final String name;
  final String label;
  final List<_AttributeOption> subOptions;
  final String? parentName;
  final bool isUnlimited;
  final String? imageUrl;
}

class _HeroSection {
  const _HeroSection({required this.labelKey, required this.heroes});

  final String labelKey;
  final List<_AttributeOption> heroes;
}

class _CachePayload {
  const _CachePayload(this.raw, this.ts);

  final Map<String, dynamic> raw;
  final int ts;
}

enum _SectionType { sort, price, group, status, date }

class _FilterSection {
  const _FilterSection({
    required this.type,
    required this.labelKey,
    this.group,
  });

  final _SectionType type;
  final String labelKey;
  final _AttributeGroup? group;

  String get key {
    if (type == _SectionType.group && group != null) {
      return 'group:${group!.key}';
    }
    return labelKey;
  }
}
