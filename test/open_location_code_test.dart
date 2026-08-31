import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/src/open_location_code.dart';

void main() {
  test('known code decodes to expected area', () {
    final a = plusCodeToArea('7MV7P8CF+J68')!;
    expect(a.latitude, closeTo(27.7172, 0.01));
    expect(a.longitude, closeTo(85.3240, 0.01));
  });

  test('round trips random coordinates in Nepal', () {
    final rnd = Random(42);
    for (var i = 0; i < 2000; i++) {
      final lat = 26.0 + rnd.nextDouble() * 5.0;
      final lng = 80.0 + rnd.nextDouble() * 8.0;
      final code = plusCodeFromLatLng(lat, lng);
      final area = plusCodeToArea(code);
      expect(area, isNotNull, reason: 'failed to decode $code');
      expect(plusCodeFromLatLng(area!.latitude, area.longitude), code,
          reason: 'centre of $code re-encoded differently');
      expect(lat, greaterThanOrEqualTo(area.latitudeLo));
      expect(lat, lessThanOrEqualTo(area.latitudeHi));
      expect(lng, greaterThanOrEqualTo(area.longitudeLo));
      expect(lng, lessThanOrEqualTo(area.longitudeHi));
    }
  });

  test('round trips globally', () {
    final rnd = Random(7);
    for (var i = 0; i < 2000; i++) {
      final lat = -89.0 + rnd.nextDouble() * 178.0;
      final lng = -179.0 + rnd.nextDouble() * 358.0;
      final code = plusCodeFromLatLng(lat, lng);
      final area = plusCodeToArea(code)!;
      expect(plusCodeFromLatLng(area.latitude, area.longitude), code);
    }
  });

  test('round trips shorter code lengths', () {
    for (final len in [8, 10, 12, 14, 16]) {
      final code = plusCodeFromLatLng(27.7172, 85.3240, codeLength: len);
      final area = plusCodeToArea(code);
      expect(area, isNotNull, reason: 'len $len code $code');
      const eps = 1e-9;
      expect(area!.latitudeLo, lessThanOrEqualTo(27.7172 + eps));
      expect(area.latitudeHi, greaterThanOrEqualTo(27.7172 - eps));
      expect(area.longitudeLo, lessThanOrEqualTo(85.3240 + eps));
      expect(area.longitudeHi, greaterThanOrEqualTo(85.3240 - eps));
    }
  });

  test('rejects malformed input', () {
    expect(plusCodeToArea('8CF+J68'), isNull); // short code
    expect(plusCodeToArea('7MV7P8CF+J6A'), isNull); // 'A' not in alphabet
    expect(plusCodeToArea(''), isNull);
    expect(plusCodeToArea('7MV70000+'), isNull); // padded short code
  });

  test('accepts separators and lowercase', () {
    final a = plusCodeToArea('7mv7p8cf+j68')!;
    final b = plusCodeToArea('7MV7P8CFJ68')!;
    final c = plusCodeToArea('7MV7-P8CF-J68')!;
    expect(a.latitude, b.latitude);
    expect(c.latitude, b.latitude);
  });
}
