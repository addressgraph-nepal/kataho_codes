import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kataho_code/src/application/kataho_code_cubit.dart';
import 'package:kataho_code/src/application/kataho_code_state.dart';
import 'package:kataho_code/src/geocode_repository.dart';
import 'package:kataho_code/src/models/kataho_code.dart';
import 'package:kataho_code/src/models/kataho_code_type.dart';
import 'package:kataho_code/src/open_location_code.dart';

/// Builds a widget from the asynchronous result of a Kataho Code lookup.
class KatahoCodeBuilder extends StatelessWidget {
  /// Creates a builder that resolves a Plus Code, a Kataho code, a KID, or
  /// coordinates using [authKey].
  ///
  /// Provide exactly one input: [plusCode], [katahoCode], [kid], [input], or
  /// both [latitude] and [longitude]. Whichever is given is resolved to the
  /// same [KatahoCode], which carries all four representations.
  ///
  /// To ask for one specific representation, set [output] and supply
  /// [outputBuilder] instead of [builder].
  const KatahoCodeBuilder({
    super.key,
    this.plusCode,
    this.katahoCode,
    this.kid,
    this.input,
    this.latitude,
    this.longitude,
    this.output,
    this.builder,
    this.outputBuilder,
    required this.authKey,
    required this.placeholder,
  }) : assert(
         (builder != null) ^ (outputBuilder != null),
         'Provide exactly one of builder or outputBuilder.',
       ),
       assert(
         outputBuilder == null || output != null,
         'outputBuilder needs an output type to build.',
       ),
       assert(
         (plusCode != null ? 1 : 0) +
                 (katahoCode != null ? 1 : 0) +
                 (kid != null ? 1 : 0) +
                 (input != null ? 1 : 0) +
                 (latitude != null && longitude != null ? 1 : 0) ==
             1,
         'Provide exactly one of plusCode, katahoCode, kid, input, or '
         'latitude+longitude.',
       ),
       assert(
         (latitude == null) == (longitude == null),
         'Provide both latitude and longitude, or neither.',
       );

  /// Plus Code to resolve, with or without separators.
  final String? plusCode;

  /// Kataho code to resolve, e.g. `"०९ लक्ष निवास १८३८"`.
  final String? katahoCode;

  /// KID to resolve — 12 digits, e.g. `"192451960075"`.
  final String? kid;

  /// Any supported input — a Plus Code, a Kataho code, a KID, or `"lat,lng"`.
  /// Use
  /// this when the input type is not known ahead of time, such as a value
  /// typed by the user.
  final String? input;

  /// Latitude in decimal degrees. Must be supplied with [longitude].
  final double? latitude;

  /// Longitude in decimal degrees. Must be supplied with [latitude].
  final double? longitude;

  /// Base64-encoded key used to decrypt the package datasets.
  final String authKey;

  /// The representation [outputBuilder] receives. Required by, and only used
  /// with, [outputBuilder].
  final KatahoCodeType? output;

  /// Builds the successful result with the resolved [KatahoCode].
  ///
  /// Mutually exclusive with [outputBuilder].
  final Widget Function(BuildContext context, KatahoCode code)? builder;

  /// Builds the successful result with the resolved [KatahoCode] and its
  /// [output] representation, e.g. the KID as a `String`.
  ///
  /// `value` is null only when the requested representation is unavailable,
  /// which for a resolved code cannot happen.
  final Widget Function(BuildContext context, KatahoCode code, String? value)?
  outputBuilder;

  /// Widget shown while the lookup is pending or has no result.
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final resolvedInput =
        plusCode ??
        katahoCode ??
        kid ??
        input ??
        plusCodeFromLatLng(latitude!, longitude!);

    return BlocProvider<KatahoCodeCubit>(
      create: (_) =>
          KatahoCodeCubit(repository: GeocodeRepository(authKey: authKey))
            ..resolve(resolvedInput),
      child: _KatahoCodeView(
        input: resolvedInput,
        output: output,
        builder: builder,
        outputBuilder: outputBuilder,
        placeholder: placeholder,
      ),
    );
  }
}

class _KatahoCodeView extends StatefulWidget {
  const _KatahoCodeView({
    required this.input,
    required this.output,
    required this.builder,
    required this.outputBuilder,
    required this.placeholder,
  });

  final String input;
  final KatahoCodeType? output;
  final Widget Function(BuildContext context, KatahoCode code)? builder;
  final Widget Function(BuildContext context, KatahoCode code, String? value)?
  outputBuilder;
  final Widget placeholder;

  @override
  State<_KatahoCodeView> createState() => _KatahoCodeViewState();
}

class _KatahoCodeViewState extends State<_KatahoCodeView> {
  @override
  void didUpdateWidget(_KatahoCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      context.read<KatahoCodeCubit>().resolve(widget.input);
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
          final build = widget.builder;
          if (build != null) return build(context, code);
          return widget.outputBuilder!(
            context,
            code,
            code.valueFor(widget.output!),
          );
        }

        if (state case KatahoCodeUnavailable(:final input)) {
          debugPrint('[KATAHO CODE] no mapping for input: $input');
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
