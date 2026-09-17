import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String sha256String(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String sha256Bytes(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
