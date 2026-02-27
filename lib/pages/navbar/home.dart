import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
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
    final response = await apiService.getCurrencyList();
    final logger = Logger();
    logger.d(response.datas);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CurrencyController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => {}, icon: Icon(Icons.menu)),
        title: Text('首页'),
        actions: [],
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
