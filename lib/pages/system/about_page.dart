import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final version = 'v1.0.0';
    final server = ServerStorage.getServer();
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.setting.about'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('TronSkins'),
              subtitle: Text(server),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('app.user.setting.version'.tr),
                  trailing: Text(version),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text('app.user.setting.website'.tr),
                  subtitle: const Text('https://www.tronskins.com/'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
