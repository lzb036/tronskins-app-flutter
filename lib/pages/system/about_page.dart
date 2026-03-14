import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _copyWebsite(BuildContext context, String website) async {
    await Clipboard.setData(ClipboardData(text: website));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('app.system.message.copy_success'.tr)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = 'v1.0.0';
    final server = ServerStorage.getServer();
    return Scaffold(
      appBar: AppBar(title: Text('app.user.setting.about'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('TronSkins'),
              subtitle: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _copyWebsite(context, server),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          server,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
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
