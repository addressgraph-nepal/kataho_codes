import 'dart:io';

import 'package:encrypt/encrypt.dart';

const _targets = <String, String>{
  'nepal_geocode.json': 'assets/data/nepal_geocode.json.enc',
  'geocode_words.json': 'assets/data/geocode_words.json.enc',
  'geocode_number_suffixes.json':
      'assets/data/geocode_number_suffixes.json.enc',
  'geocode_word_kids.json': 'assets/data/geocode_word_kids.json.enc',
};

const _defaultInputDir = 'build/decrypted_geocode';

void main(List<String> args) {
  final key = args.isEmpty
      ? Key.fromSecureRandom(32)
      : Key.fromBase64(args.first);
  final inputDir = args.length > 1 ? args[1] : _defaultInputDir;

  if (key.bytes.length != 32) {
    stderr.writeln('Key must be 32 bytes (AES-256). Got ${key.bytes.length}.');
    exitCode = 1;
    return;
  }

  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

  for (final entry in _targets.entries) {
    final source = File('$inputDir/${entry.key}');
    if (!source.existsSync()) {
      stderr.writeln(
        'Missing source file: ${source.path}\n'
        'The plaintext JSON is not kept in the repo. Recover it first:\n'
        '  dart run tool/decrypt_assets.dart <key>',
      );
      exitCode = 1;
      return;
    }

    final iv = IV.fromSecureRandom(12);
    final encrypted = encrypter.encrypt(source.readAsStringSync(), iv: iv);

    File(entry.value).writeAsBytesSync(iv.bytes + encrypted.bytes);

    final kb = (File(entry.value).lengthSync() / 1024).toStringAsFixed(1);
    stdout.writeln('  ${source.path}  ->  ${entry.value}  ($kb KB)');
  }

  stdout
    ..writeln('')
    ..writeln('Encrypted ${_targets.length} file(s).')
    ..writeln('')
    ..writeln('Pass this Base64 key as KATAHO_ENCRYPTION_KEY:')
    ..writeln('')
    ..writeln('  ${key.base64}')
    ..writeln('');
}
