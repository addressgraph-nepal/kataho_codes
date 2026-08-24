import 'package:equatable/equatable.dart';

/// One entry of `geocode_words.json`.
///
/// Maps a Nepali word or phrase to a **4-character** plus code segment, e.g.
/// `लक्ष निवास` -> `P8CF`. This is the middle segment of the full 11-character code.
/// All 400 [plusCode] values are unique, so the mapping is bidirectional.
class GeocodeWord extends Equatable {
  const GeocodeWord({
    required this.word,
    required this.plusCode,
    required this.hints,
  });

  factory GeocodeWord.fromJson(Map<String, dynamic> json) => GeocodeWord(
    word: json['word'] as String,
    plusCode: json['plus_code'] as String,
    hints: List<String>.unmodifiable(
      (json['hints'] as List<dynamic>? ?? const []).cast<String>(),
    ),
  );

  final String word;

  final String plusCode;

  final List<String> hints;

  Map<String, dynamic> toJson() => {
    'word': word,
    'plus_code': plusCode,
    'hints': hints,
  };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return word.toLowerCase() == q || hints.any((h) => h.toLowerCase() == q);
  }

  /// True if the word or any hint *starts with* [query] — for type-ahead.
  bool startsWith(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return word.toLowerCase().startsWith(q) ||
        hints.any((h) => h.toLowerCase().startsWith(q));
  }

  @override
  List<Object?> get props => [word, plusCode, hints];
}
