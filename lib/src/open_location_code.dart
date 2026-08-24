class OpenLocationCode {
  OpenLocationCode._();

  static const _alphabet = '23456789CFGHJMPQRVWX';
  static const _pairResolutions = [20.0, 1.0, 0.05, 0.0025, 0.000125];

  static String encode(double latitude, double longitude) {
    var lat = latitude.clamp(-90.0, 90.0).toDouble();
    final lon = _normaliseLongitude(longitude);

    if (lat == 90.0) lat = 89.999999999;
    lat += 90.0;
    var adjustedLon = lon + 180.0;

    final pair = StringBuffer();
    for (final resolution in _pairResolutions.take(4)) {
      final latDigit = ((lat / resolution).floor()).clamp(0, 19).toInt();
      final lonDigit = ((adjustedLon / resolution).floor())
          .clamp(0, 19)
          .toInt();
      pair
        ..write(_alphabet[latDigit])
        ..write(_alphabet[lonDigit]);

      // Keep the remainder inside the current pair cell. Using modulo here
      // prevents floating-point boundary values from producing an invalid
      // grid index later.
      lat %= resolution;
      adjustedLon %= resolution;
    }

    const gridRows = 5;
    const gridColumns = 4;
    var gridLatitudeResolution = _pairResolutions[3];
    var gridLongitudeResolution = _pairResolutions[3];
    final grid = StringBuffer();
    for (var i = 0; i < 3; i++) {
      final row = (lat / (gridLatitudeResolution / gridRows))
          .floor()
          .clamp(0, gridRows - 1)
          .toInt();
      final column = (adjustedLon / (gridLongitudeResolution / gridColumns))
          .floor()
          .clamp(0, gridColumns - 1)
          .toInt();
      grid.write(_alphabet[row * gridColumns + column]);

      lat %= gridLatitudeResolution / gridRows;
      adjustedLon %= gridLongitudeResolution / gridColumns;
      gridLatitudeResolution /= gridRows;
      gridLongitudeResolution /= gridColumns;
    }

    final significant = '$pair$grid';
    return '${significant.substring(0, 4)}+${significant.substring(4)}';
  }

  static double _normaliseLongitude(double longitude) {
    var result = longitude % 360.0;
    if (result > 180.0) result -= 360.0;
    if (result < -180.0) result += 360.0;
    return result;
  }
}
