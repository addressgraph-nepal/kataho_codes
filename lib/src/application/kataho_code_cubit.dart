import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kataho_code/src/application/kataho_code_state.dart';
import 'package:kataho_code/src/geocode_repository.dart';

class KatahoCodeCubit extends Cubit<KatahoCodeState> {
  KatahoCodeCubit({required this.repository})
    : super(const KatahoCodeInitial());

  final GeocodeRepository repository;

  String? _currentPlusCode;

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

  void clear() {
    _currentPlusCode = null;
    _safeEmit(const KatahoCodeInitial());
  }

  void _safeEmit(KatahoCodeState next) {
    if (!isClosed) emit(next);
  }
}
