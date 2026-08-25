import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/kataho_code.dart';

/// Must match the key used to encrypt the package data. The plaintext JSON is not kept in the
/// repo, so these tests decrypt the shipped assets the same way the app does.
const _key = String.fromEnvironment('KATAHO_ENCRYPTION_KEY');

/// Mirrors `GeocodeCipher.decryptJson`: `[12-byte IV][ciphertext + tag]`.
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

  test('parses every GeocodeNumber and round-trips', () {
    final raw = _load('nepal_geocode.json', 'geocode_numbers');
    final parsed = raw.map(GeocodeNumber.fromJson).toList();
    expect(parsed, hasLength(28));
    for (var i = 0; i < raw.length; i++) {
      expect(parsed[i].toJson(), equals(raw[i]));
      expect(parsed[i].plusCode.length, 4);
      expect(parsed[i].number.length, 2);
    }
    expect(parsed.first.matches('1'), isTrue);
    expect(parsed.first.matches('01'), isTrue);
    expect(parsed.first.matches('99'), isFalse);
  }, skip: skipWithoutKey);

  test('parses every GeocodeWord and round-trips', () {
    final raw = _load('geocode_words.json', 'geocode_words');
    final parsed = raw.map(GeocodeWord.fromJson).toList();
    expect(parsed, hasLength(400));
    for (var i = 0; i < raw.length; i++) {
      expect(parsed[i].toJson(), equals(raw[i]));
      expect(parsed[i].plusCode.length, 4);
    }
    final first = parsed.first;
    expect(first.matches(first.word), isTrue);
    expect(first.startsWith(first.word.substring(0, 2)), isTrue);
  }, skip: skipWithoutKey);

  test('parses every GeocodeNumberSuffix and round-trips', () {
    final raw = _load(
      'geocode_number_suffixes.json',
      'geocode_number_suffixes',
    );
    final parsed = raw.map(GeocodeNumberSuffix.fromJson).toList();
    expect(parsed, hasLength(8000));
    for (var i = 0; i < raw.length; i++) {
      expect(parsed[i].toJson(), equals(raw[i]));
      expect(parsed[i].codes.length, 3);
      expect(parsed[i].numbers.length, 4);
      expect(parsed[i].anka.length, 4);
    }
    final hundred = parsed.firstWhere((e) => e.numbers == '0100');
    expect(hundred.value, 100);
    expect(hundred.anka, '०१००');
    expect(hundred.matches('100'), isTrue, reason: 'unpadded query');
    expect(hundred.matches('0100'), isTrue);
    expect(hundred.matches('०१००'), isTrue, reason: 'devanagari query');
  }, skip: skipWithoutKey);

  test('plus code segments are unique and sum to full code length', () {
    final n = _load(
      'nepal_geocode.json',
      'geocode_numbers',
    ).map(GeocodeNumber.fromJson);
    final w = _load(
      'geocode_words.json',
      'geocode_words',
    ).map(GeocodeWord.fromJson);
    final s = _load(
      'geocode_number_suffixes.json',
      'geocode_number_suffixes',
    ).map(GeocodeNumberSuffix.fromJson);

    expect(w.map((e) => e.plusCode).toSet(), hasLength(400));
    expect(s.map((e) => e.codes).toSet(), hasLength(8000));

    final assembled = n.first.plusCode + w.first.plusCode + s.first.codes;
    expect(assembled.length, 11);
  }, skip: skipWithoutKey);

  test('encrypted assets reject a wrong key', () {
    final blob = File('assets/data/nepal_geocode.json.enc').readAsBytesSync();
    final wrong = Encrypter(AES(Key.fromSecureRandom(32), mode: AESMode.gcm));
    expect(
      () => wrong.decrypt(
        Encrypted(blob.sublist(12)),
        iv: IV(blob.sublist(0, 12)),
      ),
      throwsA(anything),
    );
  }, skip: skipWithoutKey);
}
