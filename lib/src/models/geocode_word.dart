import 'package:equatable/equatable.dart';

/// One entry of `geocode_words.json`.
///
/// Maps a Nepali word or phrase to a **2-character** plus code segment, e.g.
/// `अखण्ड` -> `2X`. Two entries are combined into the middle 4 characters of
/// a full 11-character Kataho code.
/// All 400 [plusCode] values are unique, so the mapping is bidirectional.
class GeocodeWord extends Equatable {
  /// Creates a word mapping.
  const GeocodeWord({
    required this.word,
    required this.plusCode,
    required this.hints,
  });

  /// Creates a word mapping from a decoded dataset object.
  factory GeocodeWord.fromJson(Map<String, dynamic> json) => GeocodeWord(
    word: json['word'] as String,
    plusCode: json['plus_code'] as String,
    hints: List<String>.unmodifiable(
      (json['hints'] as List<dynamic>? ?? const []).cast<String>(),
    ),
  );

  /// Nepali word or phrase displayed to the user.
  final String word;

  /// Two-character Plus Code segment for this word.
  final String plusCode;

  /// Alternate spellings accepted during matching.
  final List<String> hints;

  /// Converts this mapping to its dataset representation.
  Map<String, dynamic> toJson() => {
    'word': word,
    'plus_code': plusCode,
    'hints': hints,
  };

  /// True if [query] exactly matches the word or one of its hints.
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
