import 'package:flutter_test/flutter_test.dart';
import 'package:kataho_code/kataho_code.dart';

/// Stubs the repository so the cubit is tested without touching assets or
/// platform channels (secure storage is unavailable in a plain unit test).
class _FakeRepository implements GeocodeRepository {
  _FakeRepository({this.result, this.error});

  final KatahoCode? result;
  final Object? error;
  int calls = 0;

  @override
  Future<KatahoCode?> katahoCodeFor(String plusCode) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KatahoCode _code() => KatahoCode(
  number: const GeocodeNumber(
    number: '01',
    plusCode: '7MRC',
    hints: ['1', '01'],
  ),
  word: const GeocodeWord(word: 'अखण्ड', plusCode: '2X', hints: ['akhanda']),
  suffix: const GeocodeNumberSuffix(
    codes: 'X2R',
    numbers: '0000',
    anka: '००००',
  ),
  plusCode: '7MRC2XX2R',
);

void main() {
  test('emits loading then success', () async {
    final cubit = KatahoCodeCubit(repository: _FakeRepository(result: _code()));
    final states = <KatahoCodeState>[];
    cubit.stream.listen(states.add);

    await cubit.resolve('7MRC+2XX2R');
    // Let the stream deliver the queued events before asserting on them.
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<KatahoCodeLoading>());
    expect(cubit.state, isA<KatahoCodeSuccess>());
    expect((cubit.state as KatahoCodeSuccess).code.display, '०१ अखण्ड ००००');
    await cubit.close();
  });

  test('emits unavailable when the code does not translate', () async {
    final cubit = KatahoCodeCubit(repository: _FakeRepository(result: null));
    await cubit.resolve('ZZZZZZZZZ');
    expect(cubit.state, isA<KatahoCodeUnavailable>());
    await cubit.close();
  });

  test('emits failure when the lookup throws', () async {
    final cubit = KatahoCodeCubit(
      repository: _FakeRepository(error: StateError('boom')),
    );
    await cubit.resolve('7MRC2XX2R');
    expect(cubit.state, isA<KatahoCodeFailure>());
    await cubit.close();
  });

  test('empty plus code returns to initial without a lookup', () async {
    final repo = _FakeRepository(result: _code());
    final cubit = KatahoCodeCubit(repository: repo);
    await cubit.resolve('');
    expect(cubit.state, isA<KatahoCodeInitial>());
    expect(repo.calls, 0);
    await cubit.close();
  });

  test('repeated resolve of the same code skips the lookup', () async {
    final repo = _FakeRepository(result: _code());
    final cubit = KatahoCodeCubit(repository: repo);
    await cubit.resolve('7MRC2XX2R');
    await cubit.resolve('7MRC2XX2R');
    expect(repo.calls, 1);
    await cubit.close();
  });

  test('does not emit after close', () async {
    final cubit = KatahoCodeCubit(repository: _FakeRepository(result: _code()));
    final future = cubit.resolve('7MRC2XX2R');
    await cubit.close();
    await future; // must not throw "Cannot emit new states after calling close"
  });
}
