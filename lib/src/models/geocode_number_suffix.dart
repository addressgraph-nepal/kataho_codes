import 'package:equatable/equatable.dart';

/// A suffix mapping for the final segment of a Kataho code.
class GeocodeNumberSuffix extends Equatable {
  /// Creates a suffix mapping.
  const GeocodeNumberSuffix({
    required this.codes,
    required this.numbers,
    required this.anka,
  });

  /// Creates a suffix mapping from a decoded dataset object.
  factory GeocodeNumberSuffix.fromJson(Map<String, dynamic> json) =>
      GeocodeNumberSuffix(
        codes: json['codes'] as String,
        numbers: json['numbers'] as String,
        anka: json['anka'] as String,
      );

  /// Plus Code characters for this suffix.
  final String codes;

  /// Western-digit, zero-padded representation.
  final String numbers;

  /// Devanagari representation.
  final String anka;

  /// Converts this mapping to its dataset representation.
  Map<String, dynamic> toJson() => {
    'codes': codes,
    'numbers': numbers,
    'anka': anka,
  };

  /// [numbers] as an int, e.g. `"0100"` -> `100`.
  int get value => int.parse(numbers);

  /// True if [query] matches the Western or Devanagari form. Accepts an
  /// unpadded query, so `"100"` matches the entry stored as `"0100"`.
  /// True if [query] matches either numeric representation.
  bool matches(String query) {
    final q = query.trim();
    if (q.isEmpty) return false;
    if (q == numbers || q == anka) return true;
    final n = int.tryParse(q);
    return n != null && n == value;
  }

  @override
  List<Object?> get props => [codes, numbers, anka];
}
