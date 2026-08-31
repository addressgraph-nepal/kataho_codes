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

  test('unmapped and malformed input returns null', () async {
    expect(await repo.resolve('99 nope nope 9999'), isNull);
    expect(await repo.resolve(''), isNull);
    expect(await repo.resolve('गलत'), isNull);
    expect(await repo.resolve('०९ लक्ष १८३८'), isNull); // one word only
  });
}
