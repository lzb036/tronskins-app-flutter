import 'dart:math';

import 'package:get_storage/get_storage.dart';

class DeviceIdHelper {
  static const String _key = 'device_udid';
  static final GetStorage _box = GetStorage();

  static String getUdid() {
    final existing = _box.read<String>(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }

    final id =
        '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}${buffer.toString()}';
    _box.write(_key, id);
    return id;
  }
}
