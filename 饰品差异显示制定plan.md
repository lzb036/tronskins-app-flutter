# 饰品列表对齐计划（tronskins-app-flutter vs tronskins-app）

## 目标
让 Flutter 端的饰品列表渲染与交互行为对齐原版 tronskins-app 的组件与分游戏展示逻辑。

## 当前差距（摘要）
- Flutter 目前只有单一通用列表卡片（MarketItemCard）与页面内列表 UI。
- 原版使用多种饰品组件（BaseItem、ItemSell、ItemBuying、ItemBag、ItemTemplate、StickerList、GemList、WearProgressBar、PhaseItem）。
- Flutter 缺少可复用的饰品子组件（贴纸、宝石、磨损条等）。
- CSGO/Dota2/TF2 的列表差异尚未完全封装。
- 部分字段（贴纸/宝石/钥链）在 Flutter 中未建模或未展示。

## 计划
### 1）梳理列表场景与数据映射
- 列出 Flutter 中所有展示饰品的列表场景：
  - 市场列表、库存列表、出售/上架列表、求购列表、订单等
- 为每个场景映射其数据模型：
  - MarketItemEntity、InventoryItem、ShopItemAsset、BuyRequestItem 等
- 记录每个场景可用字段：
  - appId、marketName、rarity/quality/exterior、paintWear/paintSeed/phase、贴纸/宝石/钥链、状态/冷却/可交易、价格
- 如接口返回缺字段则补模型。

### 2）建设共享饰品子组件（Flutter）
- 新建目录（如 `lib/components/game_item/`）。
- 子组件（对齐原版行为）：
  - ItemImageWithRarityBg
  - QualityBorder / RarityTag / ExteriorBadge
  - WearProgressBar
  - StickerRow / GemRow / KeychainRow（有数据时）
  - StatusBadges（冷却/可交易/在售）
  - SelectionBadge
- 增加小型适配层/视图模型，统一字段映射。

### 3）按场景组合饰品卡片
- MarketItemCard（重构为共享子组件组合）。
- InventoryItemCard（网格、可选、冷却/可交易状态）。
- SellItemCard（价格、磨损、贴纸/宝石、品质/稀有度标签）。
- BuyingItemCard（磨损范围、phase、价格、状态）。
- TemplateItemCard（如模板/详情页需要）。

### 4）页面替换为新组件
- 替换以下页面内联列表 UI：
  - `lib/pages/navbar/market.dart`
  - `lib/pages/navbar/inventory.dart`
  - `lib/pages/shop/buying_page.dart`
  - `lib/pages/shop/*`（出售/求购/上架等）
- 保证间距、排版、状态指示一致。

### 5）详情页对齐（分游戏差异）
- 市场详情补齐原版的分游戏区块：
  - CSGO：磨损、paint index/seed、phase、贴纸/钥链
  - Dota2/TF2：品质边框、稀有度标签、宝石列表
- 复用共享子组件。

### 6）验证与对比
- 使用真实数据验证 appId 730/570/440。
- 检查列表性能（滚动、图片缓存）。
- 确认 i18n 覆盖所有新增文案。
- 与原版截图对齐对比。

## 依赖 / 风险
- API 可能暂未返回贴纸/宝石/钥链字段。
- 原版部分 UI 行为可能依赖缺失数据，需要先确认。

## 下一步
开始第 1 步：梳理列表场景与数据字段映射。

## 第 1 步输出（场景映射）
- 市场列表（首页 + 市场 tab）
  - 文件：`lib/components/market/market_item_card.dart`
  - 数据：`MarketItemEntity`（`lib/api/model/market/market_models.dart`）
  - 字段：tags（rarity/quality/exterior）、paintWear/seed/index/phase/tier/fireIce
- 市场详情列表（在售 / 求购 / 成交）
  - 文件：`lib/pages/market/market_detail_page.dart`
  - 数据：`MarketListItem` + `MarketSchemaInfo` + `MarketUserInfo`
- 库存列表（库存）
  - 文件：`lib/pages/navbar/inventory.dart`
  - 数据：`InventoryItem` + `ShopSchemaInfo`（`lib/api/model/shop/shop_models.dart`）
  - 字段：paintWear/paintSeed/phase、tradable/cooling/status、schema raw
- 上架选择（库存上架）
  - 文件：`lib/pages/shop/inventory_up_shop_page.dart`
  - 数据：`InventoryItem` + `ShopSchemaInfo`
- 供应求购（供货）
  - 文件：`lib/pages/shop/buying_supply_page.dart`
  - 数据：`InventoryItem` + `ShopSchemaInfo`
- 求购列表 / 记录
  - 文件：`lib/pages/shop/buying_page.dart`
  - 数据：`BuyRequestItem` + `ShopSchemaInfo`
- 店铺列表（店铺/订单/出售）
  - 文件：`lib/pages/navbar/shop.dart`
  - 数据：`ShopItemAsset` / `ShopOrderItem`

## 第 2 步进展（共享组件）
- 新增共享饰品组件：
  - `lib/components/game_item/game_item_image.dart`
  - `lib/components/game_item/wear_progress_bar.dart`
  - `lib/components/game_item/sticker_row.dart`
  - `lib/components/game_item/gem_row.dart`
  - `lib/components/game_item/quality_ribbon.dart`
  - `lib/components/game_item/game_item_models.dart`
  - `lib/components/game_item/game_item_utils.dart`
- 市场 + 库存列表卡片重构为共享组件：
  - `lib/components/market/market_item_card.dart`
  - `lib/pages/navbar/inventory.dart`

## 第 3 步（完成）
- 市场列表 + 库存列表切换到共享渲染。
- 店铺在售 / 待发货 / 记录更新。
- 求购列表 / 记录更新。
- 上架选择 / 供应求购更新。

## 第 3 步补充（更多场景）
- 店铺在售列表使用共享卡片：
  - `lib/components/game_item/shop_sale_item_card.dart`
  - `lib/pages/navbar/shop.dart`
- 求购列表 + 记录使用共享求购主体：
  - `lib/components/game_item/buy_request_item_body.dart`
  - `lib/pages/shop/buying_page.dart`
- 供应求购列表 + 头部使用共享展示：
  - `lib/pages/shop/buying_supply_page.dart`
- 上架选择列表展示饰品视觉 + 磨损 + 贴纸：
  - `lib/pages/shop/inventory_up_shop_page.dart`
- 市场详情求购列表使用共享饰品视觉：
  - `lib/pages/market/market_detail_page.dart`
- 店铺待发货 + 出售记录展示饰品预览 + 磨损条：
  - `lib/pages/navbar/shop.dart`
- 市场详情成交记录使用饰品预览：
  - `lib/pages/market/market_detail_page.dart`

## 第 5 步进展（详情对齐）
- 模板详情接入模板数据（参考价、标签、磨损列表、在售/求购数量）：
  - `lib/pages/market/market_detail_page.dart`
- 在售/成交列表可进入单品详情，并补齐饰品视觉：
  - `lib/pages/market/market_detail_page.dart`
- 新增单品详情页，覆盖 CSGO/Dota2/TF2 差异块（磨损/paint、贴纸/钥链、宝石）：
  - `lib/pages/market/market_item_detail_page.dart`
