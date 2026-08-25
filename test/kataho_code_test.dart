import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/kataho_code.dart';

const _key = String.fromEnvironment('KATAHO_ENCRYPTION_KEY');

List<Map<String, dynamic>> _load(String file, String key) {
  final blob = File('assets/data/$file.enc').readAsBytesSync();
  final encrypter = Encrypter(AES(Key.fromBase64(_key), mode: AESMode.gcm));
  final plain = encrypter.decrypt(
    Encrypted(blob.sublist(12)),
    iv: IV(blob.sublist(0, 12)),
  );
  return ((jsonDecode(plain) as Map<String, dynamic>)[key] as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

void main() {
  const skipWithoutKey = _key == ''
      ? 'Set KATAHO_ENCRYPTION_KEY to run encrypted asset tests.'
      : null;

  group('normalisePlusCode', () {
    test('strips separators and uppercases', () {
      expect(GeocodeRepository.normalisePlusCode('7mv7+p8c'), '7MV7P8C');
      expect(GeocodeRepository.normalisePlusCode('7MRC+2X X2R'), '7MRC2XX2R');
      expect(GeocodeRepository.normalisePlusCode('7MRC-2X-X2R'), '7MRC2XX2R');
      expect(
        GeocodeRepository.normalisePlusCode('7MV7P8CF+J68'),
        '7MV7P8CFJ68',
      );
    });
  });

  group('KatahoCode', () {
    late GeocodeNumber number;
    late GeocodeWord word;
    late GeocodeNumberSuffix suffix;

    setUpAll(() {
      number = _load(
        'nepal_geocode.json',
        'geocode_numbers',
      ).map(GeocodeNumber.fromJson).first;
      word = _load(
        'geocode_words.json',
        'geocode_words',
      ).map(GeocodeWord.fromJson).first;
      suffix = _load(
        'geocode_number_suffixes.json',
        'geocode_number_suffixes',
      ).map(GeocodeNumberSuffix.fromJson).first;
    });

    test('translates the 11-character map code for Laxya Niwas', () {
      final number = _load('nepal_geocode.json', 'geocode_numbers')
          .map(GeocodeNumber.fromJson)
          .firstWhere((entry) => entry.plusCode == '7MV7');
      final word = _load('geocode_words.json', 'geocode_words')
          .map(GeocodeWord.fromJson)
          .firstWhere((entry) => entry.plusCode == 'P8CF');
      final suffix =
          _load('geocode_number_suffixes.json', 'geocode_number_suffixes')
              .map(GeocodeNumberSuffix.fromJson)
              .firstWhere((entry) => entry.codes == 'J68');

      final code = KatahoCode(
        number: number,
        word: word,
        suffix: suffix,
        plusCode: '7MV7P8CFJ68',
      );

      expect(code.display, '०९ लक्ष निवास १८३८');
    });

    test('assembles the devanagari display form', () {
      final code = KatahoCode(
        number: number,
        word: word,
        suffix: suffix,
        plusCode: number.plusCode + word.plusCode + suffix.codes,
      );

      expect(code.display, contains(word.word));
      expect(code.displayLatin, contains(word.word));
      expect(
        code.segmentedPlusCode,
        '${number.plusCode}-${word.plusCode}-${suffix.codes}',
      );
      expect(code.plusCode, number.plusCode + word.plusCode + suffix.codes);
      expect(code.plusCode.length, 11);
    });

    test('converts every western digit to devanagari', () {
      final all =
          _load('geocode_number_suffixes.json', 'geocode_number_suffixes')
              .map(GeocodeNumberSuffix.fromJson)
              .firstWhere((e) => e.numbers == '1234');
      final code = KatahoCode(
        number: number,
        word: word,
        suffix: all,
        plusCode: 'IGNORED12',
      );
      expect(code.display, endsWith('१२३४'));
    }, skip: skipWithoutKey);
  }, skip: skipWithoutKey);
}
