// Recovery tool: turns the shipped `.enc` blobs back into readable JSON.
//
//   dart run tool/decrypt_assets.dart <base64-key> [output-dir]
//
// The geocode data is treated as final, so the plaintext JSON is not kept in
// the repo. This tool exists so the data is never unrecoverable: given the
// Base64-encoded 32-byte AES key, it reconstructs the original files.
//
// Defaults to writing into `build/decrypted_geocode/` so it cannot clobber the
// encrypted assets by accident.
import 'dart:io';

import 'package:encrypt/encrypt.dart';

const _targets = <String, String>{
  'assets/data/nepal_geocode.json.enc': 'nepal_geocode.json',
  'assets/data/geocode_words.json.enc': 'geocode_words.json',
  'assets/data/geocode_number_suffixes.json.enc':
      'geocode_number_suffixes.json',
  'assets/data/geocode_word_kids.json.enc': 'geocode_word_kids.json',
};

const _ivLength = 12;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/decrypt_assets.dart <base64-key> [output-dir]\n'
      'The key is the Base64-encoded 32-byte AES key.',
    );
    exitCode = 64;
    return;
  }

  final Key key;
  try {
    key = Key.fromBase64(args.first);
  } on FormatException catch (e) {
    stderr.writeln('Key is not valid base64: ${e.message}');
    exitCode = 64;
    return;
  }

  if (key.bytes.length != 32) {
    stderr.writeln('Key must be 32 bytes (AES-256). Got ${key.bytes.length}.');
    exitCode = 64;
    return;
  }

  final outDir = Directory(args.length > 1 ? args[1] : 'build/decrypted_geocode')
    ..createSync(recursive: true);

  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

  for (final entry in _targets.entries) {
    final source = File(entry.key);
    if (!source.existsSync()) {
      stderr.writeln('Missing encrypted asset: ${entry.key}');
      exitCode = 1;
      return;
    }

    final blob = source.readAsBytesSync();
    final iv = IV(blob.sublist(0, _ivLength));
    final payload = Encrypted(blob.sublist(_ivLength));

    final String plainText;
    try {
      plainText = encrypter.decrypt(payload, iv: iv);
    } catch (e) {
      stderr.writeln(
        'Failed to decrypt ${entry.key} — wrong key, or the file was '
        'modified after encryption. ($e)',
      );
      exitCode = 1;
      return;
    }

    final out = File('${outDir.path}/${entry.value}')
      ..writeAsStringSync(plainText);
    final kb = (out.lengthSync() / 1024).toStringAsFixed(1);
    stdout.writeln('  ${entry.key}  ->  ${out.path}  ($kb KB)');
  }

  stdout.writeln('\nRecovered ${_targets.length} file(s) into ${outDir.path}');
}
