import 'dart:math';

/// Creates a Google Open Location Code (Plus Code) from decimal coordinates.
///
/// This file is standalone and has no dependency on the Kataho application.
/// Copy it into another Dart or Flutter project and call [plusCodeFromLatLng].
///
/// The default output contains 11 significant characters (for example:
/// `7MV7P8CF+X2R`).
String plusCodeFromLatLng(
  double latitude,
  double longitude, {
  int codeLength = 11,
}) {
  if (codeLength < 2 || (codeLength < 10 && codeLength.isOdd)) {
    throw ArgumentError('codeLength must be at least 2 and even below 10');
  }

  const alphabet = '23456789CFGHJMPQRVWX';
  const base = 20;
  const latitudeMax = 90;
  const longitudeMax = 180;
  const pairCodeLength = 10;
  const separatorPosition = 8;
  const gridRows = 5;
  const gridColumns = 4;
  const gridCodeLength = 6;
  const maxDigitCount = 16;

  latitude = latitude.clamp(-90.0, 90.0);
  while (longitude < -180.0) {
    longitude += 360.0;
  }
  while (longitude >= 180.0) {
    longitude -= 360.0;
  }

  final pairPrecision = pow(base, 3).toInt();
  final finalLatPrecision =
      pairPrecision * pow(gridRows, gridCodeLength).toInt();
  final finalLngPrecision =
      pairPrecision * pow(gridColumns, gridCodeLength).toInt();

  // Latitude 90 must be moved slightly inward so the result can be decoded.
  if (latitude == 90.0) {
    latitude -= 1 / finalLatPrecision;
  }

  var latValue =
      ((latitude + latitudeMax) * finalLatPrecision * 1e6).round() ~/ 1e6;
  var lngValue =
      ((longitude + longitudeMax) * finalLngPrecision * 1e6).round() ~/ 1e6;
  var code = '';

  if (codeLength > pairCodeLength) {
    for (var i = 0; i < maxDigitCount - pairCodeLength; i++) {
      final latDigit = latValue % gridRows;
      final lngDigit = lngValue % gridColumns;
      code = alphabet[latDigit * gridColumns + lngDigit] + code;
      latValue ~/= gridRows;
      lngValue ~/= gridColumns;
    }
  } else {
    latValue ~/= pow(gridRows, gridCodeLength);
    lngValue ~/= pow(gridColumns, gridCodeLength);
  }

  for (var i = 0; i < pairCodeLength / 2; i++) {
    code = alphabet[lngValue % base] + code;
    code = alphabet[latValue % base] + code;
    latValue ~/= base;
    lngValue ~/= base;
  }

  code =
      '${code.substring(0, separatorPosition)}+${code.substring(separatorPosition)}';

  if (codeLength >= separatorPosition) {
    return code.substring(0, codeLength + 1);
  }
  return '${code.substring(0, codeLength)}${'0' * (separatorPosition - codeLength)}+';
}

/// A decoded Plus Code area: its bounding box and its centre point.
///
/// A Plus Code names a rectangle, not a point. An 11-character code covers
/// roughly 3.5m x 2.8m, so [latitude]/[longitude] — the centre — is what a
/// caller almost always wants; the bounds are kept for callers that need the
/// footprint.
class PlusCodeArea {
  /// Creates a decoded area from its bounds.
  const PlusCodeArea({
    required this.latitudeLo,
    required this.longitudeLo,
    required this.latitudeHi,
    required this.longitudeHi,
    required this.codeLength,
  });

  /// South edge of the area, in decimal degrees.
  final double latitudeLo;

  /// West edge of the area, in decimal degrees.
  final double longitudeLo;

  /// North edge of the area, in decimal degrees.
  final double latitudeHi;

  /// East edge of the area, in decimal degrees.
  final double longitudeHi;

  /// Number of significant characters the code carried.
  final int codeLength;

  /// Latitude of the area's centre, in decimal degrees.
  double get latitude => (latitudeLo + latitudeHi) / 2;

  /// Longitude of the area's centre, in decimal degrees.
  double get longitude => (longitudeLo + longitudeHi) / 2;

  @override
  String toString() =>
      'PlusCodeArea(centre: $latitude, $longitude, length: $codeLength)';
}

/// Decodes a full Plus Code back to the area it names.
///
/// Accepts the code with or without its `+` separator, spaces, or hyphens, in
/// any case. Returns `null` when [code] is not a decodable full Plus Code —
/// including short/relative codes such as `8CF+J68`, which cannot be decoded
/// without a reference location.
///
/// This is the inverse of [plusCodeFromLatLng]; feeding the centre of the
/// result back into that function reproduces the original code.
PlusCodeArea? plusCodeToArea(String code) {
  const alphabet = '23456789CFGHJMPQRVWX';
  const base = 20;
  const pairCodeLength = 10;
  const gridRows = 5;
  const gridColumns = 4;
  const maxDigitCount = 16;

  final digits = code.replaceAll(RegExp(r'[+\s-]'), '').toUpperCase();

  // A full code carries at least the 8 characters preceding the separator,
  // and padding ('0') only ever appears in short codes, which need a
  // reference location this function does not take.
  if (digits.length < 8 || digits.length > maxDigitCount) return null;
  if (digits.length < pairCodeLength && digits.length.isOdd) return null;
  for (final rune in digits.runes) {
    if (!alphabet.contains(String.fromCharCode(rune))) return null;
  }

  // Work in integer units of the finest precision the format supports, so the
  // arithmetic stays exact and mirrors the encoder.
  final pairPrecision = pow(base, 3).toInt();
  final finalLatPrecision =
      pairPrecision * pow(gridRows, maxDigitCount - pairCodeLength).toInt();
  final finalLngPrecision =
      pairPrecision * pow(gridColumns, maxDigitCount - pairCodeLength).toInt();

  var latValue = 0;
  var lngValue = 0;

  // The first ten characters are latitude/longitude pairs in base 20.
  final pairDigits = digits.length < pairCodeLength
      ? digits.length
      : pairCodeLength;
  for (var i = 0; i < pairDigits; i += 2) {
    latValue = latValue * base + alphabet.indexOf(digits[i]);
    lngValue = lngValue * base + alphabet.indexOf(digits[i + 1]);
  }

  // Pairs beyond those supplied are unresolved, so shift the value up by the
  // place value of the missing pairs before the grid characters refine it.
  final missingPairs = (pairCodeLength - pairDigits) ~/ 2;
  final missingPairPlace = pow(base, missingPairs).toInt();
  latValue *= missingPairPlace;
  lngValue *= missingPairPlace;

  // Each remaining character refines the area on a 5x4 grid.
  var latPlaceValue = finalLatPrecision ~/ pairPrecision;
  var lngPlaceValue = finalLngPrecision ~/ pairPrecision;
  latValue *= latPlaceValue;
  lngValue *= lngPlaceValue;

  for (var i = pairCodeLength; i < digits.length; i++) {
    final index = alphabet.indexOf(digits[i]);
    latPlaceValue ~/= gridRows;
    lngPlaceValue ~/= gridColumns;
    latValue += (index ~/ gridColumns) * latPlaceValue;
    lngValue += (index % gridColumns) * lngPlaceValue;
  }

  // The area's size is the place value of the last character supplied: for a
  // pair-only code that is the pair place value, otherwise the grid place
  // value the loop above left behind.
  final int latSize;
  final int lngSize;
  if (digits.length <= pairCodeLength) {
    // Only whole pairs were supplied, so the unresolved span is one unit of
    // the last pair's place value, in the same grid units latValue and
    // lngValue were scaled into above.
    latSize = missingPairPlace * (finalLatPrecision ~/ pairPrecision);
    lngSize = missingPairPlace * (finalLngPrecision ~/ pairPrecision);
  } else {
    latSize = latPlaceValue;
    lngSize = lngPlaceValue;
  }

  final latLo = latValue / finalLatPrecision - 90;
  final lngLo = lngValue / finalLngPrecision - 180;

  return PlusCodeArea(
    latitudeLo: latLo,
    longitudeLo: lngLo,
    latitudeHi: latLo + latSize / finalLatPrecision,
    longitudeHi: lngLo + lngSize / finalLngPrecision,
    codeLength: digits.length,
  );
}
