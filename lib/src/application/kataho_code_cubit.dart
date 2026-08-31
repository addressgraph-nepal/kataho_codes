import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kataho_code/src/application/kataho_code_state.dart';
import 'package:kataho_code/src/geocode_repository.dart';
import 'package:kataho_code/src/open_location_code.dart';

/// Coordinates asynchronous Plus Code lookups and exposes their state.
class KatahoCodeCubit extends Cubit<KatahoCodeState> {
  /// Creates a cubit backed by [repository].
  KatahoCodeCubit({required this.repository})
    : super(const KatahoCodeInitial());

  final GeocodeRepository repository;

  String? _currentInput;

  /// Converts [latitude] and [longitude] to a Plus Code and resolves it.
  Future<void> resolveLatLng(double latitude, double longitude) {
    return resolve(plusCodeFromLatLng(latitude, longitude));
  }

  /// Resolves [input] and emits loading, success, unavailable, or failure.
  ///
  /// [input] may be a Plus Code, a Kataho code, or a `"latitude,longitude"`
  /// pair; the repository decides which it is.
  Future<void> resolve(String input) async {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      _currentInput = null;
      _safeEmit(const KatahoCodeInitial());
      return;
    }

    if (trimmed == _currentInput && state is! KatahoCodeFailure) return;
    _currentInput = trimmed;

    _safeEmit(const KatahoCodeLoading());

    try {
      final code = await repository.resolve(trimmed);

      if (_currentInput != trimmed) return;

      _safeEmit(
        code == null ? KatahoCodeUnavailable(trimmed) : KatahoCodeSuccess(code),
      );
    } catch (e) {
      if (_currentInput != trimmed) return;
      _safeEmit(KatahoCodeFailure('Could not read the Kataho code. ($e)'));
    }
  }

  /// Clears the current lookup and emits [KatahoCodeInitial].
  void clear() {
    _currentInput = null;
    _safeEmit(const KatahoCodeInitial());
  }

  void _safeEmit(KatahoCodeState next) {
    if (!isClosed) emit(next);
  }
}
