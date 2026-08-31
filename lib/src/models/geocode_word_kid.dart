import 'package:equatable/equatable.dart';

/// One entry of `geocode_word_kids.json`.
///
/// Maps a **2-character** plus code segment to the 3-digit group it
/// contributes to a KID, e.g. `JQ` -> `245`. Two entries are combined into
/// the middle six digits of a full 12-digit KID.
///
/// All 400 [plusCode] values and all 400 [kid] values are unique, so the
/// mapping is bidirectional.
class GeocodeWordKid extends Equatable {
  /// Creates a word-KID mapping.
  const GeocodeWordKid({required this.plusCode, required this.kid});

  /// Two-character Plus Code segment, e.g. `"JQ"`.
  final String plusCode;

  /// Zero-padded 3-digit group, e.g. `"245"`.
  final String kid;

  /// Converts this mapping to its dataset representation, a single pair of
  /// the `geocode_word_kids` object.
  MapEntry<String, String> toJson() => MapEntry(plusCode, kid);

  @override
  List<Object?> get props => [plusCode, kid];

  @override
  String toString() => 'GeocodeWordKid($plusCode -> $kid)';
}
