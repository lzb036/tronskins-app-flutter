import 'dart:convert';

import 'package:dart_sm/dart_sm.dart';

class Sm2Helper {
  static String encryptPassword({
    required String password,
    required String base64PublicKey,
  }) {
    final trimmedKey = base64PublicKey.trim();
    if (trimmedKey.isEmpty) {
      return password;
    }

    try {
      var decodedKey = utf8.decode(base64.decode(trimmedKey)).trim();
      if (decodedKey.isEmpty) {
        return password;
      }
      if (decodedKey.length == 128) {
        decodedKey = '04$decodedKey';
      }
      return SM2.encrypt(password, decodedKey, cipherMode: C1C3C2);
    } catch (error) {
      throw Exception('Password encryption failed');
    }
  }
}
