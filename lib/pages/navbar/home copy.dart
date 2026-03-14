// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/system.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final apiService = ApiSystemServer();
    await apiService.getCurrencyList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CurrencyController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => {}, icon: Icon(Icons.menu)),
        title: Text('首页'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.attach_money),
            onSelected: (String currency) {
              // 设置当前货币
              final controller = Get.find<CurrencyController>();
              controller.setCurrency(currency);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'USD', child: Text('USD - 美元')),
                PopupMenuItem(
                  value: 'EUR_DE',
                  child: Text('EUR (DE) - 欧元(德国)'),
                ),
                PopupMenuItem(
                  value: 'EUR_FR',
                  child: Text('EUR (FR) - 欧元(法国)'),
                ),
                PopupMenuItem(
                  value: 'EUR_IT',
                  child: Text('EUR (IT) - 欧元(意大利)'),
                ),
                PopupMenuItem(
                  value: 'EUR_ES',
                  child: Text('EUR (ES) - 欧元(西班牙)'),
                ),
                PopupMenuItem(value: 'GBP', child: Text('GBP - 英镑')),
                PopupMenuItem(value: 'CNY', child: Text('CNY - 人民币')),
                PopupMenuItem(value: 'RUB', child: Text('RUB - 卢布')),
                PopupMenuItem(value: 'VND', child: Text('VND - 越南盾')),
                PopupMenuItem(value: 'PHP', child: Text('PHP - 菲律宾比索')),
                PopupMenuItem(value: 'THB', child: Text('THB - 泰铢')),
                PopupMenuItem(value: 'INR', child: Text('INR - 印度卢比')),
                PopupMenuItem(value: 'IDR', child: Text('IDR - 印尼盾')),
                PopupMenuItem(value: 'JPY', child: Text('JPY - 日元')),
                PopupMenuItem(value: 'KRW', child: Text('KRW - 韩元')),
                PopupMenuItem(value: 'BRL', child: Text('BRL - 巴西雷亚尔')),
                PopupMenuItem(value: 'TRY', child: Text('TRY - 土耳其里拉')),
                PopupMenuItem(value: 'AUD', child: Text('AUD - 澳元')),
                PopupMenuItem(value: 'CAD', child: Text('CAD - 加元')),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Get.toNamed(Routers.USER_SETTING),
              child: const Text("跳转1"),
            ),
            Text('app.tabbar.home'.tr, style: const TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            // 显示当前货币和格式化后的金额
            Obx(() {
              return Column(
                children: [
                  Text('当前货币：${controller.code}'),
                  Text('格式化金额：${controller.format(98)}'),
                  Text('美元基准：${controller.format(2)}'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
