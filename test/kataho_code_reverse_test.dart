import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/kataho_code.dart';

/// Repository backed by an in-memory dataset so the reverse path can be
/// exercised without the encryption key.
class _FakeRepo extends GeocodeRepository {
  _FakeRepo() : super(authKey: 'unused');

  static const _numbers = [
    GeocodeNumber(number: '09', plusCode: '7MV7', hints: ['9']),
    GeocodeNumber(number: '01', plusCode: '7MRC', hints: ['1']),
  ];
  static const _words = [
    GeocodeWord(word: 'लक्ष', plusCode: 'P8', hints: ['laxya']),
    GeocodeWord(word: 'निवास', plusCode: '8F', hints: ['niwas']),
    GeocodeWord(word: 'निवास२', plusCode: 'CF', hints: ['niwas2']),
    GeocodeWord(word: 'अखण्ड', plusCode: '2X', hints: ['akhanda']),
  ];
  static const _wordKids = [
    GeocodeWordKid(plusCode: 'P8', kid: '294'),
    GeocodeWordKid(plusCode: '8F', kid: '212'),
    GeocodeWordKid(plusCode: 'CF', kid: '171'),
    GeocodeWordKid(plusCode: '2X', kid: '001'),
  ];
  static const _suffixes = [
    GeocodeNumberSuffix(codes: 'VJC', numbers: '1838', anka: '१८३८'),
    GeocodeNumberSuffix(codes: 'X2R', numbers: '0000', anka: '००००'),
  ];

  @override
  Future<List<GeocodeNumber>> numbers() async => _numbers;
  @override
  Future<List<GeocodeWord>> words() async => _words;
  @override
  Future<List<GeocodeNumberSuffix>> suffixes() async => _suffixes;
  @override
  Future<List<GeocodeWordKid>> wordKids() async => _wordKids;
}

void main() {
  late _FakeRepo repo;
  setUp(() => repo = _FakeRepo());

  test('forward: plus code -> kataho + latlng', () async {
    final c = (await repo.resolve('7MV7P88F+VJC'))!;
    expect(c.display, '०९ लक्ष निवास १८३८');
    expect(c.plusCode, '7MV7P88FVJC');
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
    expect(c.latitude, closeTo(27.7172, 0.01));
    expect(c.longitude, closeTo(85.3240, 0.01));
  });

  test('reverse: kataho (devanagari) -> plus code + latlng', () async {
    final c = (await repo.resolve('०९ लक्ष निवास १८३८'))!;
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
    expect(c.latitude, closeTo(27.7172, 0.01));
    expect(c.longitude, closeTo(85.3240, 0.01));
  });

  test('reverse: kataho with western digits', () async {
    final c = (await repo.resolve('09 लक्ष निवास 1838'))!;
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
  });

  test('reverse: kataho via hints', () async {
    final c = (await repo.resolve('9 laxya niwas 1838'))!;
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
  });

  test('reverse: unpadded suffix', () async {
    final c = (await repo.resolve('01 अखण्ड निवास 0'))!;
    expect(c.plusCode, '7MRC2X8FX2R');
  });

  test('latlng string input', () async {
    final c = (await repo.resolve('27.7172,85.3240'))!;
    expect(c.display, '०९ लक्ष निवास १८३८');
  });

  test('latlng method', () async {
    final c = (await repo.katahoCodeForLatLng(27.7172, 85.3240))!;
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
  });

  test('round trip: kataho -> latlng -> kataho', () async {
    final a = (await repo.resolve('०९ लक्ष निवास १८३८'))!;
    final b = (await repo.katahoCodeForLatLng(a.latitude!, a.longitude!))!;
    expect(b.display, a.display);
    expect(b.plusCode, a.plusCode);
  });

  test('every lookup carries the KID', () async {
    final c = (await repo.resolve('7MV7P88F+VJC'))!;
    // 09 + P8->294 + 8F->212 + 1838
    expect(c.kid, '092942121838');
    expect(c.kid!.length, 12);
  });

  test('kid -> everything else', () async {
    final c = (await repo.resolve('092942121838'))!;
    expect(c.display, '०९ लक्ष निवास १८३८');
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
    expect(c.latitude, closeTo(27.7172, 0.01));
    expect(c.longitude, closeTo(85.3240, 0.01));
    expect(c.kid, '092942121838');
  });

  test('kid accepts devanagari digits', () async {
    final c = (await repo.resolve('०९२९४२१२१८३८'))!;
    expect(c.kid, '092942121838');
  });

  test('kid via explicit method', () async {
    final c = (await repo.katahoCodeForKid('092942121838'))!;
    expect(c.formattedPlusCode, '7MV7P88F+VJC');
  });

  test('all four representations round trip', () async {
    final seeds = [
      '7MV7P88F+VJC',
      '०९ लक्ष निवास १८३८',
      '092942121838',
      '27.7172, 85.3240',
    ];
    for (final seed in seeds) {
      final c = (await repo.resolve(seed))!;
      expect(c.formattedPlusCode, '7MV7P88F+VJC', reason: seed);
      expect(c.display, '०९ लक्ष निवास १८३८', reason: seed);
      expect(c.kid, '092942121838', reason: seed);
      expect(c.latitude, closeTo(27.7172, 0.01), reason: seed);
    }
  });

  test('malformed kid returns null', () async {
    expect(await repo.resolve('99999999999999'), isNull); // wrong length
    expect(await repo.katahoCodeForKid('09294212183'), isNull); // 11 digits
    expect(await repo.katahoCodeForKid('099999991838'), isNull); // unmapped
    expect(await repo.katahoCodeForKid('abcdefghijkl'), isNull);
  });

  test('unmapped and malformed input returns null', () async {
    expect(await repo.resolve('99 nope nope 9999'), isNull);
    expect(await repo.resolve(''), isNull);
    expect(await repo.resolve('गलत'), isNull);
    expect(await repo.resolve('०९ लक्ष १८३८'), isNull); // one word only
  });
}
