// One-off tool: encrypts `geocode_word_kids.json` with the existing key.
//
//   dart run tool/encrypt_word_kids.dart <base64-key> [input-json]
//
// The KID dataset was added after the other three assets were encrypted, so
// it needs encrypting with the *same* key rather than a freshly generated one.
// `tool/encrypt_assets.dart` re-encrypts every asset at once and would rotate
// the key; this script touches only the KID file.
//
// Defaults to reading `assets/data/geocode_word_kids.json` and writing
// `assets/data/geocode_word_kids.json.enc` beside it.
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';

const _defaultInput = 'assets/data/geocode_word_kids.json';
const _output = 'assets/data/geocode_word_kids.json.enc';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/encrypt_word_kids.dart <base64-key> [input-json]\n'
      'Use the same key the other assets were encrypted with.',
    );
    exitCode = 64;
    return;
  }

  final key = Key.fromBase64(args.first);
  if (key.bytes.length != 32) {
    stderr.writeln('Key must be 32 bytes (AES-256). Got ${key.bytes.length}.');
    exitCode = 1;
    return;
  }

  final source = File(args.length > 1 ? args[1] : _defaultInput);
  if (!source.existsSync()) {
    stderr.writeln('Missing source file: ${source.path}');
    exitCode = 1;
    return;
  }

  // Fail loudly here rather than at runtime on a user's device.
  final plain = source.readAsStringSync();
  final decoded = jsonDecode(plain) as Map<String, dynamic>;
  final map = decoded['geocode_word_kids'];
  if (map is! Map) {
    stderr.writeln('Expected a "geocode_word_kids" object in ${source.path}.');
    exitCode = 1;
    return;
  }
  final codes = map.keys.cast<String>().toSet();
  final kids = map.values.cast<String>().toSet();
  if (codes.length != map.length || kids.length != map.length) {
    stderr.writeln(
      'The mapping must be bidirectional: ${map.length} entries, '
      '${codes.length} unique codes, ${kids.length} unique KIDs.',
    );
    exitCode = 1;
    return;
  }

  final iv = IV.fromSecureRandom(12);
  final encrypted = Encrypter(AES(key, mode: AESMode.gcm))
      .encrypt(plain, iv: iv);
  File(_output).writeAsBytesSync(iv.bytes + encrypted.bytes);

  stdout.writeln(
    '  ${source.path}  ->  $_output  (${map.length} entries)\n'
    '\n'
    'Verify with:  dart run tool/decrypt_assets.dart <key>',
  );
}
