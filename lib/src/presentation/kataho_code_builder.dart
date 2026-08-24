import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kataho_code/src/application/kataho_code_cubit.dart';
import 'package:kataho_code/src/application/kataho_code_state.dart';
import 'package:kataho_code/src/geocode_repository.dart';
import 'package:kataho_code/src/models/kataho_code.dart';

class KatahoCodeBuilder extends StatelessWidget {
  const KatahoCodeBuilder({
    super.key,
    required this.plusCode,
    required this.authKey,
    required this.builder,
    required this.placeholder,
  });

  final String plusCode;
  final String authKey;
  final Widget Function(BuildContext context, KatahoCode code) builder;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<KatahoCodeCubit>(
      create: (_) =>
          KatahoCodeCubit(repository: GeocodeRepository(authKey: authKey))
            ..resolve(plusCode),
      child: _KatahoCodeView(
        plusCode: plusCode,
        builder: builder,
        placeholder: placeholder,
      ),
    );
  }
}

class _KatahoCodeView extends StatefulWidget {
  const _KatahoCodeView({
    required this.plusCode,
    required this.builder,
    required this.placeholder,
  });

  final String plusCode;
  final Widget Function(BuildContext context, KatahoCode code) builder;
  final Widget placeholder;

  @override
  State<_KatahoCodeView> createState() => _KatahoCodeViewState();
}

class _KatahoCodeViewState extends State<_KatahoCodeView> {
  @override
  void didUpdateWidget(_KatahoCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plusCode != widget.plusCode) {
      context.read<KatahoCodeCubit>().resolve(widget.plusCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KatahoCodeCubit, KatahoCodeState>(
      builder: (context, state) {
        if (state case KatahoCodeSuccess(:final code)) {
          debugPrint(
            '[KATAHO CODE] plusCode: ${code.plusCode}, '
            'katahoCode: ${code.display}',
          );
          return widget.builder(context, code);
        }

        if (state case KatahoCodeUnavailable(:final plusCode)) {
          debugPrint('[KATAHO CODE] no mapping for plusCode: $plusCode');
          return const Text('Kataho code unavailable');
        }

        if (state case KatahoCodeFailure(:final message)) {
          debugPrint('[KATAHO CODE] lookup failed: $message');
          return Text(message);
        }

        return widget.placeholder;
      },
    );
  }
}
