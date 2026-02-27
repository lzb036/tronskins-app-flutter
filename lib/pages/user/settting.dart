import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/theme/use_theme.dart';

// ignore: use_key_in_widget_constructors
class UserSetting extends StatelessWidget {
  final Rx<Locale> currentLocale = Locale('en', 'US').obs;  
  final useTheme = Get.find<UseTheme>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(  title: Text(
          'app.user.setting.title'.tr,
          style: const TextStyle(fontSize: 14),
        ),),
      body: ListView(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0), 
            title: Text('app.user.setting.avatar'.tr,
            style: TextStyle(fontSize: 14)),
            dense: true, 
            trailing: CircleAvatar(
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
            onTap: () {
            },
          ),
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0), 
            title: Text('app.user.setting.nickname'.tr,
            style: TextStyle(fontSize: 14)),
            trailing: Text( '昵称'),
            dense: true,
            onTap: () {
            },
          ),
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true, 
            title: Text('app.user.setting.email'.tr,
            style: TextStyle(fontSize: 14)),
            trailing: Text( '邮箱'),
            onTap: () {
            },
          ),
          
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true, 
            title: Text('app.user.setting.password'.tr,
            style: TextStyle(fontSize: 14)),
            onTap: () {
            },
          ),
             ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true, 
            title: Text('app.user.setting.steam_management'.tr,
            style: TextStyle(fontSize: 14)),
            onTap: () {
            },
          ),
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true, 
            title: Text('app.user.setting.multilingual'.tr,
            style: TextStyle(fontSize: 14),),
            onTap: () {
            },
            
          ),
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true, 
            title: Text('app.user.setting.server'.tr,
            style: TextStyle(fontSize: 14)),
            onTap: () {
            },
            
          ),
            ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true,
            title: Text('app.user.setting.version'.tr,
            style: TextStyle(fontSize: 14)),
            onTap: () {
            },
          ),
             ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            dense: true,
            title: Text('切换主题'.tr,
            style: TextStyle(fontSize: 14)),
            onTap: () {
              useTheme.toggleTheme();
            },
          ),
          ],
        ),
    );
  }
}