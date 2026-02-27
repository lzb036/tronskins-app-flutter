import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_filter_models.dart';
import 'package:tronskins_app/common/storage/market_search_history_storage.dart';

class MarketSearchSheet extends StatefulWidget {
  const MarketSearchSheet({
    super.key,
    required this.appId,
    this.initialKeyword = '',
  });

  final int appId;
  final String initialKeyword;

  @override
  State<MarketSearchSheet> createState() => _MarketSearchSheetState();
}

class _MarketSearchSheetState extends State<MarketSearchSheet> {
  final ApiMarketServer _api = ApiMarketServer();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _lastKeyword = '';

  List<MarketNameSuggestion> _suggestions = [];
  List<String> _history = [];
  bool _isLoading = false;
  bool _hasQueried = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialKeyword;
    _lastKeyword = _controller.text;
    _history = MarketSearchHistoryStorage.getHistory();
    _controller.addListener(_onKeywordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onKeywordChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeywordChanged() {
    final rawKeyword = _controller.text;
    if (rawKeyword == _lastKeyword) {
      return;
    }
    _lastKeyword = rawKeyword;
    final keyword = rawKeyword.trim();
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (keyword.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      _fetchSuggestions(keyword);
    });
  }

  Future<void> _fetchSuggestions(String keyword) async {
    _hasQueried = true;
    setState(() => _isLoading = true);
    try {
      final res = await _api.marketQueryItemName(
        appId: widget.appId,
        keywords: keyword,
      );
      if (!mounted) return;
      setState(() => _suggestions = res.datas ?? []);
    } catch (_) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await MarketSearchHistoryStorage.addHistory(trimmed);
    if (!mounted) return;
    Navigator.of(context).pop(trimmed);
  }

  Future<void> _clearHistory() async {
    await MarketSearchHistoryStorage.clearHistory();
    if (mounted) {
      setState(() => _history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHistory = _controller.text.trim().isEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            if (showHistory)
              _buildHistorySection()
            else
              _buildSuggestionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'app.market.filter.search'.tr,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _suggestions = []);
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('app.common.cancel'.tr),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'app.common.no_data'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'app.market.filter.selection_quick'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: Text('app.market.filter.clear'.tr),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _history
              .map(
                (keyword) => ActionChip(
                  label: Text(keyword),
                  onPressed: () => _submit(keyword),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(),
      );
    }
    if (!_hasQueried && _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'app.common.no_data'.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return SizedBox(
      height: 280,
      child: ListView.separated(
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          final name = item.displayName;
          return ListTile(
            title: Text(name),
            onTap: () => _submit(name),
          );
        },
      ),
    );
  }
}
