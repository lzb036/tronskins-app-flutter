import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/components/game/game_switch_menu.dart';
import 'package:tronskins_app/components/game_item/buy_request_item_body.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/shop/buy_request_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class BuyingPage extends StatefulWidget {
  const BuyingPage({super.key});

  @override
  State<BuyingPage> createState() => _BuyingPageState();
}

class _BuyingPageState extends State<BuyingPage>
    with SingleTickerProviderStateMixin {
  final BuyRequestController controller =
      Get.isRegistered<BuyRequestController>()
      ? Get.find<BuyRequestController>()
      : Get.put(BuyRequestController());

  late final TabController _tabController;
  late int _currentAppId;
  final ScrollController _myBuyingScroll = ScrollController();
  final ScrollController _recordScroll = ScrollController();
  final TextEditingController _mySearchController = TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentAppId = GameStorage.getGameType();
    _myBuyingScroll.addListener(_handleMyBuyingScroll);
    _recordScroll.addListener(_handleRecordScroll);
    controller.refreshMyBuying();
    controller.refreshBuyRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _myBuyingScroll
      ..removeListener(_handleMyBuyingScroll)
      ..dispose();
    _recordScroll
      ..removeListener(_handleRecordScroll)
      ..dispose();
    _mySearchController.dispose();
    _recordSearchController.dispose();
    super.dispose();
  }

  void _handleMyBuyingScroll() {
    if (_myBuyingScroll.position.pixels >
        _myBuyingScroll.position.maxScrollExtent - 200) {
      controller.loadMyBuying();
    }
  }

  void _handleRecordScroll() {
    if (_recordScroll.position.pixels >
        _recordScroll.position.maxScrollExtent - 200) {
      controller.loadBuyRecords();
    }
  }

  ShopSchemaInfo? _lookupSchema(BuyRequestItem item) {
    final key = item.schemaId?.toString();
    if (key != null && controller.schemas.containsKey(key)) {
      return controller.schemas[key];
    }
    return null;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '-';
    }
    var ts = timestamp;
    if (ts < 10000000000) {
      ts *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  Future<void> _switchGame(int appId) async {
    if (appId == GameStorage.getGameType()) {
      return;
    }
    await GameStorage.setGameType(appId);
    if (mounted) {
      setState(() => _currentAppId = appId);
    }
    controller.refreshMyBuying();
    controller.refreshBuyRecords();
  }

  void _showOfflineTips() {
    Get.snackbar(
      'app.system.tips.title'.tr,
      'app.trade.purchase.offline_tips'.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = UserStorage.getUserInfo() != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('app.trade.purchase.text'.tr),
        actions: [
          Builder(
            builder: (iconContext) {
              return IconButton(
                icon: Image.asset(
                  'assets/images/game/icon/$_currentAppId.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.videogame_asset);
                  },
                ),
                onPressed: () async {
                  final selected = await showGameSwitchMenu(
                    iconContext: iconContext,
                    currentAppId: _currentAppId,
                  );
                  if (selected == null) {
                    return;
                  }
                  await _switchGame(selected);
                },
              );
            },
          ),
          if (isLoggedIn)
            Obx(() {
              final isOnline = controller.purchaseOnline.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: () => Get.toNamed(Routers.PURCHASE_SETTING),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'app.user.menu.purchase'.tr),
            Tab(text: 'app.trade.purchase.record'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyBuyingTab(), _buildRecordTab()],
      ),
    );
  }

  Widget _buildMyBuyingTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mySearchController,
                  onSubmitted: (_) =>
                      controller.searchMyBuying(_mySearchController.text),
                  decoration: InputDecoration(
                    hintText: 'app.market.filter.search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () =>
                          controller.searchMyBuying(_mySearchController.text),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final asc = controller.buyingSortAsc.value;
                return IconButton(
                  tooltip: 'app.market.filter.price'.tr,
                  icon: Icon(asc ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: controller.togglePriceSort,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingMyBuying.value &&
                controller.myBuying.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.myBuying.isEmpty) {
              return Center(child: Text('app.common.no_data'.tr));
            }
            final showLoadingFooter =
                controller.isLoadingMyBuying.value &&
                controller.myBuying.isNotEmpty;
            final showNoMoreFooter =
                controller.myBuying.isNotEmpty &&
                !controller.isLoadingMyBuying.value &&
                !controller.myBuyingHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return ListView.separated(
              controller: _myBuyingScroll,
              padding: const EdgeInsets.all(16),
              itemCount: controller.myBuying.length + (showFooter ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= controller.myBuying.length) {
                  return _buildLoadMoreFooter(
                    showLoading: showLoadingFooter,
                    showNoMore: showNoMoreFooter,
                  );
                }
                final item = controller.myBuying[index];
                final schema = _lookupSchema(item);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatTime(item.upTime ?? item.createTime),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              '${item.received ?? 0}/${item.nums ?? 0}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BuyRequestItemBody(
                          item: item,
                          schema: schema,
                          trailing: Column(
                            children: [
                              FilledButton.tonal(
                                onPressed: () async {
                                  if (!controller.purchaseOnline.value) {
                                    _showOfflineTips();
                                    return;
                                  }
                                  final result = await Get.toNamed(
                                    Routers.BUYING_UPDATE_PRICE,
                                    arguments: {
                                      'item': item.raw,
                                      'schema': schema?.raw,
                                    },
                                  );
                                  if (result == true) {
                                    await controller.refreshMyBuying();
                                  }
                                },
                                child: Text('app.inventory.price_change'.tr),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  if (!controller.purchaseOnline.value) {
                                    _showOfflineTips();
                                    return;
                                  }
                                  final id = item.id?.toString();
                                  if (id == null) {
                                    return;
                                  }
                                  final confirm = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: Text('app.system.tips.title'.tr),
                                      content: Text(
                                        'app.trade.purchase.message.confirm_terminate'
                                            .tr,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: false),
                                          child: Text('app.common.cancel'.tr),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          child: Text('app.common.confirm'.tr),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await controller.cancelBuy(id);
                                    Get.snackbar(
                                      'app.system.tips.title'.tr,
                                      'app.system.message.success'.tr,
                                    );
                                  }
                                },
                                child: Text('app.trade.purchase.terminate'.tr),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecordTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _recordSearchController,
                  onSubmitted: (_) =>
                      controller.searchRecords(_recordSearchController.text),
                  decoration: InputDecoration(
                    hintText: 'app.market.filter.search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => controller.searchRecords(
                        _recordSearchController.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final asc = controller.recordSortAsc.value;
                return IconButton(
                  tooltip: 'app.market.filter.time'.tr,
                  icon: Icon(asc ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: controller.toggleRecordSort,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingRecords.value &&
                controller.buyRecords.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.buyRecords.isEmpty) {
              return Center(child: Text('app.common.no_data'.tr));
            }
            final showLoadingFooter =
                controller.isLoadingRecords.value &&
                controller.buyRecords.isNotEmpty;
            final showNoMoreFooter =
                controller.buyRecords.isNotEmpty &&
                !controller.isLoadingRecords.value &&
                !controller.recordHasMore;
            final showFooter = showLoadingFooter || showNoMoreFooter;
            return ListView.separated(
              controller: _recordScroll,
              padding: const EdgeInsets.all(16),
              itemCount: controller.buyRecords.length + (showFooter ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= controller.buyRecords.length) {
                  return _buildLoadMoreFooter(
                    showLoading: showLoadingFooter,
                    showNoMore: showNoMoreFooter,
                  );
                }
                final item = controller.buyRecords[index];
                final schema = _lookupSchema(item);
                final statusName = item.statusName ?? '-';
                final statusColor = item.status == 1
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.onSurfaceVariant;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BuyRequestItemBody(
                      item: item,
                      schema: schema,
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            statusName,
                            style: TextStyle(color: statusColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.received ?? 0}/${item.nums ?? 0}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLoadMoreFooter({
    required bool showLoading,
    required bool showNoMore,
  }) {
    if (showLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (showNoMore) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }
    return const SizedBox(height: 4);
  }
}
