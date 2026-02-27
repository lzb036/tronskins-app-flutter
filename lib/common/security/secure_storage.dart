import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:get_storage/get_storage.dart';

class SecureStorage {
  // 与 tronskins-app 保持相同的密钥
  static const String _secureKey = 'yycfsAppSecretKey123!';
  static const String _prefix = 'secure_';
  static final _box = GetStorage();

  // 获取 AES 加密器
  static encrypt.Encrypter get _encrypter {
    // 将密钥转换为 32 字节 (AES-256)
    final key = encrypt.Key.fromUtf8(_secureKey.padRight(32).substring(0, 32));
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  // 加密数据
  static String _encrypt(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(data, iv: iv);
    // 将 IV 与密文拼接 (OpenSSL 格式兼容)
    return iv.base64 + encrypted.base64;
  }

  // 解密数据
  static String _decrypt(String encryptedData) {
    if (encryptedData.length < 24) {
      throw const FormatException('Invalid encrypted payload');
    }
    final iv = encrypt.IV.fromBase64(encryptedData.substring(0, 24));
    final encrypted = encryptedData.substring(24);
    return _encrypter.decrypt64(encrypted, iv: iv);
  }

  // 存储数据（加密）
  static Future<void> setItem(String key, String value) async {
    final encrypted = _encrypt(value);
    await _box.write('$_prefix$key', encrypted);
  }

  // 读取数据（解密）
  static Future<String?> getItem(String key) async {
    final encrypted = _box.read<String>('$_prefix$key');
    if (encrypted == null || encrypted.isEmpty) {
      return null;
    }
    try {
      return _decrypt(encrypted);
    } catch (e) {
      return null;
    }
  }

  // 删除数据
  static Future<void> removeItem(String key) async {
    await _box.remove('$_prefix$key');
  }
}
