import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kataho_code/src/application/kataho_code_state.dart';
import 'package:kataho_code/src/geocode_repository.dart';

/// Coordinates asynchronous Plus Code lookups and exposes their state.
class KatahoCodeCubit extends Cubit<KatahoCodeState> {
  /// Creates a cubit backed by [repository].
  KatahoCodeCubit({required this.repository})
    : super(const KatahoCodeInitial());

  final GeocodeRepository repository;

  String? _currentPlusCode;

  /// Resolves [plusCode] and emits loading, success, unavailable, or failure.
  Future<void> resolve(String plusCode) async {
    final trimmed = plusCode.trim();

    if (trimmed.isEmpty) {
      _currentPlusCode = null;
      _safeEmit(const KatahoCodeInitial());
      return;
    }

    if (trimmed == _currentPlusCode && state is! KatahoCodeFailure) return;
    _currentPlusCode = trimmed;

    _safeEmit(const KatahoCodeLoading());

    try {
      final code = await repository.katahoCodeFor(trimmed);

      if (_currentPlusCode != trimmed) return;

      _safeEmit(
        code == null ? KatahoCodeUnavailable(trimmed) : KatahoCodeSuccess(code),
      );
    } catch (e) {
      if (_currentPlusCode != trimmed) return;
      _safeEmit(KatahoCodeFailure('Could not read the Kataho code. ($e)'));
    }
  }

  /// Clears the current lookup and emits [KatahoCodeInitial].
  void clear() {
    _currentPlusCode = null;
    _safeEmit(const KatahoCodeInitial());
  }

  void _safeEmit(KatahoCodeState next) {
    if (!isClosed) emit(next);
  }
}
