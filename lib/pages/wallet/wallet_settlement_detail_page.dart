import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletSettlementDetailPage extends StatelessWidget {
  const WalletSettlementDetailPage({
    super.key,
    required this.record,
    required this.schemas,
    required this.users,
    required this.stickers,
  });

  final WalletSettlementRecord record;
  final Map<String, WalletSchemaInfo> schemas;
  final Map<String, dynamic> users;
  final Map<String, dynamic> stickers;

  WalletSchemaInfo? _lookupSchema(WalletSettlementDetail detail) {
    final hash = detail.marketHashName ?? '';
    if (hash.isNotEmpty && schemas.containsKey(hash)) {
      return schemas[hash];
    }
    return null;
  }

  String? _paintWearText(WalletSettlementDetail detail) {
    final value = detail.raw['paint_wear'] ?? detail.raw['paintWear'];
    if (value != null) {
      return value.toString();
    }
    return detail.paintWear?.toString();
  }

  Widget _buildItemImage(String url) {
    if (url.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (context, _) => const SizedBox(
          width: 64,
          height: 64,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, _, __) =>
            const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final details = record.details;
    final isReceivable = (record.status ?? 0) == 4;
    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        backgroundColor: WalletUi.pageBackground(context),
        appBar: AppBar(title: Text('app.trade.order.details'.tr)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: WalletUi.cardShape(context),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${'app.trade.order.number'.tr}: ${record.id ?? '-'}',
                        ),
                        const Spacer(),
                        Text(
                          currency.formatUsd(record.price ?? 0),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    if (users.isNotEmpty || stickers.isNotEmpty)
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...details.map((detail) {
              final schema = _lookupSchema(detail);
              final name =
                  detail.marketName ??
                  schema?.marketName ??
                  detail.marketHashName;
              final image = detail.imageUrl ?? schema?.imageUrl ?? '';
              final linePrice = detail.price ?? 0;
              final wearText = _paintWearText(detail);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: WalletUi.cardShape(context),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildItemImage(image),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name ?? '-', maxLines: 2),
                            if (wearText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${'app.market.csgo.abradability'.tr}: $wearText',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currency.formatUsd(linePrice),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: WalletUi.cardShape(context),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'app.system.tips.warm'.tr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('1. ${'app.trade.order.buyer_tips_1'.tr}'),
                    const SizedBox(height: 4),
                    Text('2. ${'app.trade.order.buyer_tips_2'.tr}'),
                    const SizedBox(height: 4),
                    Text('3. ${'app.trade.order.buyer_tips_3'.tr}'),
                    const SizedBox(height: 4),
                    Text('4. ${'app.trade.order.buyer_tips_4'.tr}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isReceivable
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Get.toNamed(
                        Routers.SHOP_PURCHASE,
                        arguments: {'initialTab': 0},
                      ),
                      child: Text('app.market.product.receive'.tr),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
