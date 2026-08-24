import 'dart:math';

/// Creates a Google Open Location Code (Plus Code) from decimal coordinates.
///
/// This file is standalone and has no dependency on the Kataho application.
/// Copy it into another Dart or Flutter project and call [plusCodeFromLatLng].
///
/// The default output contains 11 significant characters (for example:
/// `7MV7P8CF+X2R`).
String plusCodeFromLatLng(double latitude, double longitude, {int codeLength = 11}) {
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
  final finalLatPrecision = pairPrecision * pow(gridRows, gridCodeLength).toInt();
  final finalLngPrecision = pairPrecision * pow(gridColumns, gridCodeLength).toInt();

  // Latitude 90 must be moved slightly inward so the result can be decoded.
  if (latitude == 90.0) {
    latitude -= 1 / finalLatPrecision;
  }

  var latValue = ((latitude + latitudeMax) * finalLatPrecision * 1e6).round() ~/ 1e6;
  var lngValue = ((longitude + longitudeMax) * finalLngPrecision * 1e6).round() ~/ 1e6;
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

  code = '${code.substring(0, separatorPosition)}+${code.substring(separatorPosition)}';

  if (codeLength >= separatorPosition) {
    return code.substring(0, codeLength + 1);
  }
  return '${code.substring(0, codeLength)}${'0' * (separatorPosition - codeLength)}+';
}
