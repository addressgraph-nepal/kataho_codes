import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;

/// Decrypts the encrypted geocode datasets bundled with the package.
///
/// [authKey] must be a Base64-encoded 32-byte AES key. Call [init] before
/// calling [decryptJson].
class GeocodeCipher {
  /// Creates a cipher using the consumer-provided [authKey].
  GeocodeCipher({required this.authKey});

  /// Base64-encoded 32-byte AES key supplied by the package consumer.
  final String authKey;

  static const int _ivLength = 12;
  static const int _tagLength = 16;

  Encrypter? _encrypter;

  /// Initializes the AES-GCM encrypter if it has not already been initialized.
  Future<void> init() async {
    if (_encrypter != null) return;

    if (authKey.trim().isEmpty) {
      throw StateError('Kataho auth key is missing. Provide KATAHO_AUTH_KEY.');
    }

    try {
      final key = Key.fromBase64(authKey.trim());
      if (key.bytes.length != 32) {
        throw const FormatException('Kataho encryption key must be 32 bytes.');
      }
      _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    } on FormatException catch (error) {
      throw FormatException('Invalid Kataho encryption key: $error');
    }
  }

  /// Decrypts an encrypted asset and decodes its JSON object.
  ///
  /// The encrypted blob must start with the 12-byte initialization vector.
  Map<String, dynamic> decryptJson(Uint8List blob) {
    final encrypter = _encrypter;
    if (encrypter == null) {
      throw StateError(
        'GeocodeCipher.init() must be awaited before decrypting.',
      );
    }

    if (blob.length <= _ivLength + _tagLength) {
      throw const FormatException('Encrypted geocode asset is truncated.');
    }

    final iv = IV(blob.sublist(0, _ivLength));
    final payload = Encrypted(blob.sublist(_ivLength));

    final String plainText;
    try {
      plainText = encrypter.decrypt(payload, iv: iv);
    } catch (e) {
      throw FormatException('Failed to decrypt geocode asset: $e');
    }

    return jsonDecode(plainText) as Map<String, dynamic>;
  }

  /// Discards the initialized encrypter so it can be initialized again.
  Future<void> reset() async {
    _encrypter = null;
  }
}
