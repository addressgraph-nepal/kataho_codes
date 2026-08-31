import 'package:equatable/equatable.dart';
import 'package:kataho_code/src/models/kataho_code.dart';

/// State of a single plus-code -> Kataho-code translation.
sealed class KatahoCodeState extends Equatable {
  const KatahoCodeState();

  @override
  List<Object?> get props => [];
}

/// No plus code has been supplied yet.
class KatahoCodeInitial extends KatahoCodeState {
  const KatahoCodeInitial();
}

/// The geocode assets are being decrypted, or the lookup is running.
class KatahoCodeLoading extends KatahoCodeState {
  const KatahoCodeLoading();
}

/// The plus code resolved to a Kataho code.
class KatahoCodeSuccess extends KatahoCodeState {
  const KatahoCodeSuccess(this.code);

  final KatahoCode code;

  @override
  List<Object?> get props => [code];
}

/// The input is well-formed but has no Kataho equivalent, e.g. it points
/// outside the mapped area. Distinct from [KatahoCodeFailure]: nothing went
/// wrong, there is simply no code to show.
class KatahoCodeUnavailable extends KatahoCodeState {
  const KatahoCodeUnavailable(this.input);

  /// The input that could not be resolved — a Plus Code, a Kataho code, or a
  /// coordinate pair.
  final String input;

  @override
  List<Object?> get props => [input];
}

/// The lookup itself failed — decryption error, missing asset, bad key.
class KatahoCodeFailure extends KatahoCodeState {
  const KatahoCodeFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
