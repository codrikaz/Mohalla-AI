import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String hashPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '').trim();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
