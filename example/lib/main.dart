import 'package:flutter/material.dart';
import 'package:kataho_code/kataho_code.dart';

void main() {
  runApp(const KatahoExampleApp());
}

class KatahoExampleApp extends StatelessWidget {
  const KatahoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kataho Code example',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const KatahoExamplePage(),
    );
  }
}

class KatahoExamplePage extends StatefulWidget {
  const KatahoExamplePage({super.key});

  @override
  State<KatahoExamplePage> createState() => _KatahoExamplePageState();
}

class _KatahoExamplePageState extends State<KatahoExamplePage> {
  static const _authKey = String.fromEnvironment('KATAHO_AUTH_KEY');

  final _controller = TextEditingController(text: '27.7172, 85.3240');
  String? _input;
  KatahoCodeType? _output;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _input = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kataho Code example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter coordinates, a Plus Code, a Kataho Code, or a KID — the '
              'package detects which and converts between all four.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Coordinates, Plus Code, Kataho Code, or KID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final sample in const [
                  '27.7172, 85.3240',
                  '7MW4JQF6+62R',
                  '१९ माणिक प्रकाश ००७५',
                  '192451960075',
                ])
                  ActionChip(
                    label: Text(sample),
                    onPressed: () {
                      _controller.text = sample;
                      _submit();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Convert to', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Everything'),
                  selected: _output == null,
                  onSelected: (_) => setState(() => _output = null),
                ),
                for (final type in KatahoCodeType.values)
                  ChoiceChip(
                    label: Text(_label(type)),
                    selected: _output == type,
                    onSelected: (_) => setState(() => _output = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Convert')),
            if (_input != null) ...[
              const SizedBox(height: 24),
              if (_output == null)
                KatahoCodeBuilder(
                  input: _input,
                  authKey: _authKey,
                  placeholder: const Center(child: CircularProgressIndicator()),
                  builder: (context, code) => _ResultCard(code: code),
                )
              else
                // Ask for one representation and show just that.
                KatahoCodeBuilder(
                  input: _input,
                  output: _output,
                  authKey: _authKey,
                  placeholder: const Center(child: CircularProgressIndicator()),
                  outputBuilder: (context, code, value) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label(_output!),
                            style: theme.textTheme.labelMedium,
                          ),
                          SelectableText(
                            value ?? 'unavailable',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _label(KatahoCodeType type) => switch (type) {
  KatahoCodeType.latLng => 'Coordinates',
  KatahoCodeType.plusCode => 'Plus Code',
  KatahoCodeType.katahoCode => 'Kataho Code',
  KatahoCodeType.katahoCodeLatin => 'Kataho (Latin)',
  KatahoCodeType.kid => 'KID',
};

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.code});

  final KatahoCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kataho Code', style: theme.textTheme.labelMedium),
            Text(code.display, style: theme.textTheme.headlineSmall),
            const Divider(height: 24),
            _Row(label: 'Latin', value: code.displayLatin),
            _Row(label: 'Plus Code', value: code.formattedPlusCode),
            if (code.kid != null) _Row(label: 'KID', value: code.kid!),
            if (code.latitude != null && code.longitude != null)
              _Row(
                label: 'Coordinates',
                value:
                    '${code.latitude!.toStringAsFixed(6)}, '
                    '${code.longitude!.toStringAsFixed(6)}',
              ),
            _Row(label: 'Segments', value: code.segmentedPlusCode),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
