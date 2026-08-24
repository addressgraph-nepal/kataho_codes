import 'package:equatable/equatable.dart';

class GeocodeNumberSuffix extends Equatable {
  const GeocodeNumberSuffix({
    required this.codes,
    required this.numbers,
    required this.anka,
  });

  factory GeocodeNumberSuffix.fromJson(Map<String, dynamic> json) =>
      GeocodeNumberSuffix(
        codes: json['codes'] as String,
        numbers: json['numbers'] as String,
        anka: json['anka'] as String,
      );

  final String codes;

  final String numbers;

  final String anka;

  Map<String, dynamic> toJson() => {
    'codes': codes,
    'numbers': numbers,
    'anka': anka,
  };

  /// [numbers] as an int, e.g. `"0100"` -> `100`.
  int get value => int.parse(numbers);

  /// True if [query] matches the Western or Devanagari form. Accepts an
  /// unpadded query, so `"100"` matches the entry stored as `"0100"`.
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
