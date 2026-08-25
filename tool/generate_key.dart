import 'dart:io';

import 'package:encrypt/encrypt.dart';

void main() {
  final key = Key.fromSecureRandom(32);

  stdout.writeln('KATAHO_AUTH_KEY=${key.base64}');
  stdout.writeln();
  stdout.writeln('Run the app with:');
  stdout.writeln('flutter run --dart-define=KATAHO_AUTH_KEY=${key.base64}');
  stdout.writeln();
  stdout.writeln(
    'Keep this key private. Anyone with it can decrypt the datasets.',
  );
}
