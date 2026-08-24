import 'package:flutter/services.dart' show rootBundle;
import 'package:kataho_code/src/geocode_cipher.dart';
import 'package:kataho_code/src/models/geocode_number.dart';
import 'package:kataho_code/src/models/geocode_number_suffix.dart';
import 'package:kataho_code/src/models/geocode_word.dart';
import 'package:kataho_code/src/models/kataho_code.dart';

class GeocodeRepository {
  GeocodeRepository({required String authKey})
    : _cipher = GeocodeCipher(authKey: authKey);

  final GeocodeCipher _cipher;

  static const _numbersAsset =
      'packages/kataho_code/assets/data/nepal_geocode.json.enc';
  static const _wordsAsset =
      'packages/kataho_code/assets/data/geocode_words.json.enc';
  static const _suffixesAsset =
      'packages/kataho_code/assets/data/geocode_number_suffixes.json.enc';

  static const int numberCodeLength = 4;
  static const int wordCodeLength = 4;
  static const int suffixCodeLength = 3;

  static const int fullCodeLength =
      numberCodeLength + wordCodeLength + suffixCodeLength;

  List<GeocodeNumber>? _numbers;
  List<GeocodeWord>? _words;
  List<GeocodeNumberSuffix>? _suffixes;

  Map<String, GeocodeNumber>? _numbersByCode;
  Map<String, GeocodeWord>? _wordsByCode;
  Map<String, GeocodeNumberSuffix>? _suffixesByCode;

  Future<List<GeocodeNumber>> numbers() async => _numbers ??= await _load(
    _numbersAsset,
    'geocode_numbers',
    GeocodeNumber.fromJson,
  );

  Future<List<GeocodeWord>> words() async => _words ??= await _load(
    _wordsAsset,
    'geocode_words',
    GeocodeWord.fromJson,
  );

  Future<List<GeocodeNumberSuffix>> suffixes() async =>
      _suffixes ??= await _load(
        _suffixesAsset,
        'geocode_number_suffixes',
        GeocodeNumberSuffix.fromJson,
      );

  Future<void> preload() async {
    await Future.wait([numbers(), words(), suffixes()]);
  }

  Future<GeocodeNumber?> numberForCode(String code) async {
    _numbersByCode ??= {for (final e in await numbers()) e.plusCode: e};
    return _numbersByCode![code.toUpperCase()];
  }

  Future<GeocodeWord?> wordForCode(String code) async {
    _wordsByCode ??= {for (final e in await words()) e.plusCode: e};
    return _wordsByCode![code.toUpperCase()];
  }

  Future<GeocodeNumberSuffix?> suffixForCode(String code) async {
    _suffixesByCode ??= {for (final e in await suffixes()) e.codes: e};
    return _suffixesByCode![code.toUpperCase()];
  }

  Future<KatahoCode?> katahoCodeFor(String plusCode) async {
    final normalised = normalisePlusCode(plusCode);
    if (normalised.length != fullCodeLength) return null;

    final numberCode = normalised.substring(0, numberCodeLength);
    final wordCode = normalised.substring(
      numberCodeLength,
      numberCodeLength + wordCodeLength,
    );
    final suffixCode = normalised.substring(numberCodeLength + wordCodeLength);

    final results = await Future.wait([
      numberForCode(numberCode),
      wordForCode(wordCode.substring(0, 2)),
      wordForCode(wordCode.substring(2)),
      suffixForCode(suffixCode),
    ]);

    final number = results[0] as GeocodeNumber?;
    final firstWord = results[1] as GeocodeWord?;
    final secondWord = results[2] as GeocodeWord?;
    final suffix = results[3] as GeocodeNumberSuffix?;
    if (number == null ||
        firstWord == null ||
        secondWord == null ||
        suffix == null) {
      return null;
    }

    final word = GeocodeWord(
      word: '${firstWord.word} ${secondWord.word}',
      plusCode: wordCode,
      hints: [...firstWord.hints, ...secondWord.hints],
    );

    return KatahoCode(
      number: number,
      word: word,
      suffix: suffix,
      plusCode: normalised,
    );
  }

  /// Strips separators and uppercases the code. Kataho uses 11 significant
  /// characters as four segments: 4 + 2 + 2 + 3.
  static String normalisePlusCode(String value) {
    final normalised = value.replaceAll(RegExp(r'[+\s-]'), '').toUpperCase();
    return normalised;
  }

  Future<List<T>> _load<T>(
    String asset,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await _cipher.init();

    final bytes = await rootBundle.load(asset);
    final json = _cipher.decryptJson(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );

    final list = json[key];
    if (list is! List) {
      throw FormatException('Asset $asset is missing the "$key" array.');
    }

    return List<T>.unmodifiable(
      list.map((e) => fromJson(e as Map<String, dynamic>)),
    );
  }
}
