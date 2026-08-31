import 'package:flutter/services.dart' show rootBundle;
import 'package:kataho_code/src/geocode_cipher.dart';
import 'package:kataho_code/src/models/geocode_number.dart';
import 'package:kataho_code/src/models/geocode_number_suffix.dart';
import 'package:kataho_code/src/models/geocode_word.dart';
import 'package:kataho_code/src/models/kataho_code.dart';
import 'package:kataho_code/src/open_location_code.dart';

/// Loads and resolves the encrypted geocode datasets bundled with the package.
class GeocodeRepository {
  /// Creates a repository using the Base64-encoded AES [authKey].
  GeocodeRepository({required String authKey})
    : _cipher = GeocodeCipher(authKey: authKey);

  final GeocodeCipher _cipher;

  static const _numbersAsset =
      'packages/kataho_code/assets/data/nepal_geocode.json.enc';
  static const _wordsAsset =
      'packages/kataho_code/assets/data/geocode_words.json.enc';
  static const _suffixesAsset =
      'packages/kataho_code/assets/data/geocode_number_suffixes.json.enc';

  /// Number of characters in the region segment.
  static const int numberCodeLength = 4;

  /// Number of characters in the combined word segment.
  static const int wordCodeLength = 4;

  /// Number of characters in the suffix segment.
  static const int suffixCodeLength = 3;

  /// Number of significant characters in a full Kataho lookup code.
  static const int fullCodeLength =
      numberCodeLength + wordCodeLength + suffixCodeLength;

  List<GeocodeNumber>? _numbers;
  List<GeocodeWord>? _words;
  List<GeocodeNumberSuffix>? _suffixes;

  Map<String, GeocodeNumber>? _numbersByCode;
  Map<String, GeocodeWord>? _wordsByCode;
  Map<String, GeocodeNumberSuffix>? _suffixesByCode;

  Map<String, GeocodeNumber>? _numbersByName;
  Map<String, GeocodeWord>? _wordsByName;
  Map<String, GeocodeNumberSuffix>? _suffixesByName;

  /// Returns the region-number dataset, loading and caching it on first use.
  Future<List<GeocodeNumber>> numbers() async => _numbers ??= await _load(
    _numbersAsset,
    'geocode_numbers',
    GeocodeNumber.fromJson,
  );

  /// Returns the word dataset, loading and caching it on first use.
  Future<List<GeocodeWord>> words() async => _words ??= await _load(
    _wordsAsset,
    'geocode_words',
    GeocodeWord.fromJson,
  );

  /// Returns the number-suffix dataset, loading and caching it on first use.
  Future<List<GeocodeNumberSuffix>> suffixes() async =>
      _suffixes ??= await _load(
        _suffixesAsset,
        'geocode_number_suffixes',
        GeocodeNumberSuffix.fromJson,
      );

  /// Loads all three datasets before returning.
  Future<void> preload() async {
    await Future.wait([numbers(), words(), suffixes()]);
  }

  /// Finds a region number by its Plus Code segment.
  Future<GeocodeNumber?> numberForCode(String code) async {
    _numbersByCode ??= {for (final e in await numbers()) e.plusCode: e};
    return _numbersByCode![code.toUpperCase()];
  }

  /// Finds a word by its two-character Plus Code segment.
  Future<GeocodeWord?> wordForCode(String code) async {
    _wordsByCode ??= {for (final e in await words()) e.plusCode: e};
    return _wordsByCode![code.toUpperCase()];
  }

  /// Finds a suffix by its Plus Code segment.
  Future<GeocodeNumberSuffix?> suffixForCode(String code) async {
    _suffixesByCode ??= {for (final e in await suffixes()) e.codes: e};
    return _suffixesByCode![code.toUpperCase()];
  }

  /// Resolves [plusCode] to a Kataho code, or returns `null` if unmapped.
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

    return _withCoordinates(
      number: number,
      word: word,
      suffix: suffix,
      plusCode: normalised,
    );
  }

  /// Finds a region number by its Devanagari or Western form, or a hint.
  Future<GeocodeNumber?> numberForName(String name) async {
    _numbersByName ??= {
      for (final e in await numbers()) ...{
        _foldName(e.number): e,
        for (final h in e.hints) _foldName(h): e,
      },
    };
    final folded = _foldName(name);
    final direct = _numbersByName![folded];
    if (direct != null) return direct;

    // Accept an unpadded query such as "9" for the entry stored as "09".
    final value = int.tryParse(folded);
    if (value == null) return null;
    return _numbersByName![value.toString().padLeft(2, '0')];
  }

  /// Finds a word by its Nepali spelling or one of its hints.
  Future<GeocodeWord?> wordForName(String name) async {
    _wordsByName ??= {
      for (final e in await words()) ...{
        _foldName(e.word): e,
        for (final h in e.hints) _foldName(h): e,
      },
    };
    return _wordsByName![_foldName(name)];
  }

  /// Finds a suffix by its Devanagari or Western digits.
  Future<GeocodeNumberSuffix?> suffixForName(String name) async {
    _suffixesByName ??= {
      for (final e in await suffixes()) ...{
        _foldName(e.numbers): e,
        _foldName(e.anka): e,
      },
    };
    final folded = _foldName(name);
    final direct = _suffixesByName![folded];
    if (direct != null) return direct;

    // Accept an unpadded query such as "100" for the entry stored as "0100".
    final value = int.tryParse(folded);
    if (value == null) return null;
    return _suffixesByName![value.toString().padLeft(4, '0')];
  }

  /// Resolves a Kataho code such as `"०९ लक्ष निवास १८३८"` back to its
  /// components, or returns `null` when any segment is unmapped.
  ///
  /// Accepts Devanagari or Western digits and the multi-word middle segment.
  /// The leading number and trailing house number may be separated from the
  /// word by any run of whitespace.
  Future<KatahoCode?> katahoCodeForDisplay(String kataho) async {
    final tokens = kataho.trim().split(RegExp(r'\s+'))
      ..removeWhere((t) => t.isEmpty);
    // The first token is the region number and the last the house number;
    // everything between them is the middle segment, which is two dataset
    // words joined by a space — so a valid code has at least four tokens.
    if (tokens.length < 4) return null;
    final middle = tokens.sublist(1, tokens.length - 1);

    final results = await Future.wait([
      numberForName(tokens.first),
      suffixForName(tokens.last),
    ]);
    final number = results[0] as GeocodeNumber?;
    final suffix = results[1] as GeocodeNumberSuffix?;
    if (number == null || suffix == null) return null;

    for (var split = 1; split < middle.length; split++) {
      final pair = await Future.wait([
        wordForName(middle.sublist(0, split).join(' ')),
        wordForName(middle.sublist(split).join(' ')),
      ]);
      final first = pair[0];
      final second = pair[1];
      if (first == null || second == null) continue;

      final word = GeocodeWord(
        word: '${first.word} ${second.word}',
        plusCode: first.plusCode + second.plusCode,
        hints: [...first.hints, ...second.hints],
      );

      return _withCoordinates(
        number: number,
        word: word,
        suffix: suffix,
        plusCode: number.plusCode + word.plusCode + suffix.codes,
      );
    }

    return null;
  }

  /// Resolves [latitude] and [longitude] to a Kataho code.
  Future<KatahoCode?> katahoCodeForLatLng(double latitude, double longitude) {
    return katahoCodeFor(plusCodeFromLatLng(latitude, longitude));
  }

  /// Resolves any supported input to a Kataho code carrying every
  /// representation — Kataho display form, Plus Code, and coordinates.
  ///
  /// [input] may be a Plus Code (`"7MV7P8CF+J68"`), a Kataho code
  /// (`"०९ लक्ष निवास १८३८"`), or a `"latitude,longitude"` pair
  /// (`"27.7172,85.3240"`). Returns `null` when the input is unrecognised or
  /// has no mapping.
  Future<KatahoCode?> resolve(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final latLng = _parseLatLng(trimmed);
    if (latLng != null) {
      return katahoCodeForLatLng(latLng.$1, latLng.$2);
    }

    // A Plus Code is exactly the dataset alphabet plus separators; anything
    // carrying other characters is a Kataho display string.
    final normalised = normalisePlusCode(trimmed);
    if (normalised.length == fullCodeLength &&
        _plusCodeAlphabet.hasMatch(normalised)) {
      return katahoCodeFor(normalised);
    }

    return katahoCodeForDisplay(trimmed);
  }

  static final _plusCodeAlphabet = RegExp(r'^[23456789CFGHJMPQRVWX]+$');

  /// Parses `"lat,lng"` or `"lat lng"`, or returns `null` if [value] is not a
  /// coordinate pair.
  static (double, double)? _parseLatLng(String value) {
    final parts = value.split(RegExp(r'[,\s]+'));
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat, lng);
  }

  /// Normalises a dataset name for case- and whitespace-insensitive lookup.
  ///
  /// Devanagari digits fold to their Western equivalents so a code may be
  /// supplied in either script.
  static String _foldName(String value) {
    final trimmed = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final buffer = StringBuffer();
    for (final rune in trimmed.runes) {
      // Devanagari digits U+0966..U+096F map onto '0'..'9'.
      if (rune >= 0x0966 && rune <= 0x096F) {
        buffer.write(rune - 0x0966);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Builds a [KatahoCode] with the coordinates its plus code decodes to.
  static KatahoCode _withCoordinates({
    required GeocodeNumber number,
    required GeocodeWord word,
    required GeocodeNumberSuffix suffix,
    required String plusCode,
  }) {
    final area = plusCodeToArea(plusCode);
    return KatahoCode(
      number: number,
      word: word,
      suffix: suffix,
      plusCode: plusCode,
      latitude: area?.latitude,
      longitude: area?.longitude,
    );
  }

  /// Removes separators and whitespace and converts a Plus Code to uppercase.
  /// Kataho uses 11 significant characters as four segments: 4 + 2 + 2 + 3.
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
