import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/kataho_code.dart';

/// These exercise the real encrypted datasets, so they need the key:
///
///   flutter test --dart-define=KATAHO_AUTH_KEY=`your-base64-key`
const _key = String.fromEnvironment('KATAHO_AUTH_KEY');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const skipWithoutKey = _key == ''
      ? 'Set KATAHO_AUTH_KEY to run encrypted asset tests.'
      : null;

  late GeocodeRepository repo;
  setUp(() => repo = GeocodeRepository(authKey: _key));

  test('real data: the documented example resolves every which way', () async {
    // 7MW4JQF6+62R  <->  १९ माणिक प्रकाश ००७५  <->  192451960075
    const plus = '7MW4JQF6+62R';
    const kataho = '१९ माणिक प्रकाश ००७५';
    const kid = '192451960075';

    for (final seed in [plus, kataho, kid]) {
      final c = await repo.resolve(seed);
      expect(c, isNotNull, reason: 'failed to resolve $seed');
      expect(c!.formattedPlusCode, plus, reason: seed);
      expect(c.display, kataho, reason: seed);
      expect(c.kid, kid, reason: seed);
      expect(c.latitude, isNotNull, reason: seed);
      expect(c.longitude, isNotNull, reason: seed);
    }
  }, skip: skipWithoutKey);

  test('real data: coordinates round trip back to themselves', () async {
    final first = await repo.resolve('7MW4JQF6+62R');
    final viaLatLng =
        await repo.katahoCodeForLatLng(first!.latitude!, first.longitude!);
    expect(viaLatLng!.plusCode, first.plusCode);
    expect(viaLatLng.kid, first.kid);
    expect(viaLatLng.display, first.display);
  }, skip: skipWithoutKey);

  test('real data: convert covers the full input x output matrix', () async {
    const inputs = ['7MW4JQF6+62R', '१९ माणिक प्रकाश ००७५', '192451960075'];
    for (final input in inputs) {
      for (final type in KatahoCodeType.values) {
        final v = await repo.convert(input, type);
        expect(v, isNotNull, reason: '$input -> $type');
        expect(v, isNotEmpty, reason: '$input -> $type');
      }
    }
  }, skip: skipWithoutKey);

  test('real data: KID is unique across a sample of plus codes', () async {
    // Walk real coordinates across Nepal and confirm no KID collisions.
    final seen = <String, String>{};
    for (var i = 0; i < 60; i++) {
      final lat = 26.5 + (i % 10) * 0.35;
      final lng = 85.0 + (i ~/ 10) * 0.4;
      final c = await repo.katahoCodeForLatLng(lat, lng);
      if (c?.kid == null) continue;
      final prior = seen[c!.kid!];
      expect(
        prior,
        anyOf(isNull, equals(c.plusCode)),
        reason: 'KID ${c.kid} maps to both $prior and ${c.plusCode}',
      );
      seen[c.kid!] = c.plusCode;
    }
    expect(seen, isNotEmpty);
  }, skip: skipWithoutKey);

  test('real data: every KID resolves back to its own plus code', () async {
    for (var i = 0; i < 40; i++) {
      final lat = 27.0 + i * 0.02;
      final lng = 85.2 + i * 0.01;
      final c = await repo.katahoCodeForLatLng(lat, lng);
      if (c?.kid == null) continue;
      final back = await repo.katahoCodeForKid(c!.kid!);
      expect(back, isNotNull, reason: 'KID ${c.kid} did not resolve back');
      expect(back!.plusCode, c.plusCode, reason: 'KID ${c.kid}');
      expect(back.display, c.display);
    }
  }, skip: skipWithoutKey);
}
