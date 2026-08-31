import 'package:equatable/equatable.dart';
import 'package:kataho_code/src/models/geocode_number.dart';
import 'package:kataho_code/src/models/geocode_number_suffix.dart';
import 'package:kataho_code/src/models/geocode_word.dart';
import 'package:kataho_code/src/models/kataho_code_type.dart';

/// A plus code translated into its human-readable Kataho form.
///
/// The 11 significant characters of a plus code split into three segments,
/// each of which maps to one of the geocode datasets:
///
/// ```
///   7MV7      P8CF      J68
///   └ number  └ word  └ suffix
///     "09"      लक्ष निवास    "१८३८"
///
///   -> "०१ अखण्ड ००००"
/// ```
class KatahoCode extends Equatable {
  /// Creates a translated Kataho code from its component mappings.
  const KatahoCode({
    required this.number,
    required this.word,
    required this.suffix,
    required this.plusCode,
    this.latitude,
    this.longitude,
    this.kid,
  });

  /// Leading region segment, e.g. `01`.
  final GeocodeNumber number;

  /// Middle word segment, e.g. `अखण्ड`.
  final GeocodeWord word;

  /// Trailing house-number segment, e.g. `००००`.
  final GeocodeNumberSuffix suffix;

  /// The normalised 11-character plus code this was derived from,
  /// without separators, e.g. `"7MV7P8CFJ68"`.
  final String plusCode;

  /// Latitude of the centre of the area [plusCode] names, in decimal degrees.
  ///
  /// Populated for every code the repository resolves. It is `null` only when
  /// a [KatahoCode] is constructed directly without coordinates.
  final double? latitude;

  /// Longitude of the centre of the area [plusCode] names, in decimal degrees.
  ///
  /// Populated for every code the repository resolves. It is `null` only when
  /// a [KatahoCode] is constructed directly without coordinates.
  final double? longitude;

  /// The 12-digit KID, e.g. `"192451960075"`.
  ///
  /// Populated for every code the repository resolves. It is `null` only when
  /// a [KatahoCode] is constructed directly without one.
  final String? kid;

  /// The plus code in its canonical separated form, e.g. `"7MV7P8CF+J68"`.
  String get formattedPlusCode => plusCode.length > 8
      ? '${plusCode.substring(0, 8)}+${plusCode.substring(8)}'
      : plusCode;

  /// Devanagari form shown on the plate, e.g. `"०१ अखण्ड ००००"`.
  ///
  /// [GeocodeNumber.number] is stored in Western digits, so it is converted
  /// here to match the rest of the line.
  String get display =>
      '${_toDevanagari(number.number)} '
      '${word.word} '
      '${suffix.anka}';

  /// Western-digit form, e.g. `"01 अखण्ड 0000"`. The word has no Western
  /// equivalent, so it stays in Devanagari.
  String get displayLatin => '${number.number} ${word.word} ${suffix.numbers}';

  /// The plus code re-joined with its segment boundaries visible,
  /// e.g. `"7MRC-2X-X2R"`. Useful for debugging a bad lookup.
  String get segmentedPlusCode =>
      '${number.plusCode}-${word.plusCode}-${suffix.codes}';

  /// Returns this code in the representation [type] names.
  ///
  /// Returns `null` only when the underlying value is missing — [kid] and the
  /// coordinates are absent when a [KatahoCode] is constructed directly
  /// rather than resolved through a repository.
  String? valueFor(KatahoCodeType type) => switch (type) {
    KatahoCodeType.latLng => latitude == null || longitude == null
        ? null
        : '${latitude!.toStringAsFixed(6)}, '
              '${longitude!.toStringAsFixed(6)}',
    KatahoCodeType.plusCode => formattedPlusCode,
    KatahoCodeType.katahoCode => display,
    KatahoCodeType.katahoCodeLatin => displayLatin,
    KatahoCodeType.kid => kid,
  };

  static const _devanagariDigits = '०१२३४५६७८९';

  static String _toDevanagari(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _devanagariDigits[digit]);
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    number,
    word,
    suffix,
    plusCode,
    latitude,
    longitude,
    kid,
  ];

  @override
  String toString() => 'KatahoCode($display, plusCode: $plusCode)';
}
