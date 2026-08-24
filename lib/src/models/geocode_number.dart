import 'package:equatable/equatable.dart';

class GeocodeNumber extends Equatable {
  const GeocodeNumber({
    required this.number,
    required this.plusCode,
    required this.hints,
  });

  factory GeocodeNumber.fromJson(Map<String, dynamic> json) => GeocodeNumber(
    number: json['number'] as String,
    plusCode: json['plus_code'] as String,
    hints: List<String>.unmodifiable(
      (json['hints'] as List<dynamic>? ?? const []).cast<String>(),
    ),
  );

  /// Zero-padded region number, always 2 characters (`"01"`..`"28"`).
  final String number;

  /// Leading 4 characters of the plus code, e.g. `"7MRC"`.
  final String plusCode;

  /// Alternate spellings used for search/matching, e.g. `["1", "01"]`.
  final List<String> hints;

  Map<String, dynamic> toJson() => {
    'number': number,
    'plus_code': plusCode,
    'hints': hints,
  };

  /// True if [query] matches this entry's number or any of its hints,
  /// ignoring case and surrounding whitespace.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return number.toLowerCase() == q || hints.any((h) => h.toLowerCase() == q);
  }

  @override
  List<Object?> get props => [number, plusCode, hints];
}
