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

class KatahoExamplePage extends StatelessWidget {
  const KatahoExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    const latitude = 27.7172;
    const longitude = 85.3240;
    final plusCode = plusCodeFromLatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Kataho Code example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Plus Code for Kathmandu:\n$plusCode\n\n'
            'To resolve a Kataho Code, provide your dataset key to '
            'KatahoCodeBuilder or GeocodeRepository.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
