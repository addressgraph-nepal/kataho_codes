import 'package:encrypt/encrypt.dart';

void main() {
  final key = Key.fromSecureRandom(32);

  print('KATAHO_AUTH_KEY=${key.base64}');
  print('');
  print('Run the app with:');
  print('flutter run --dart-define=KATAHO_AUTH_KEY=${key.base64}');
  print('');
  print('Keep this key private. Anyone with it can decrypt the datasets.');
}
