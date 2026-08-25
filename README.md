# kataho_code

Flutter package for converting Nepal-focused 11-character Plus Codes into
human-readable Kataho Codes.

The package includes encrypted geocode datasets, model classes, an async
repository, a `KatahoCodeCubit`, and a ready-to-use `KatahoCodeBuilder`.

## Installation

```yaml
dependencies:
  kataho_code: ^0.1.1
```

Then run `flutter pub get`.

## Encryption key

The package does not contain the AES key. Every consumer must provide the
Base64-encoded 32-byte key that matches the encrypted datasets. Keep this key
in a secret build configuration and never commit it to source control.

For example:

```bash
flutter run --dart-define=KATAHO_AUTH_KEY=<base64-aes-key>
```

## Widget usage

```dart
KatahoCodeBuilder(
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  plusCode: '7MV7P8CF+J68',
  builder: (context, code) => Text(code.display),
  placeholder: const Text('Loading...'),
)
```

A matching dataset entry resolves to a display value such as
`०९ लक्ष निवास १८३८`.

## Repository usage

Use `GeocodeRepository` directly when the application owns loading and state:

```dart
final repository = GeocodeRepository(
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
);

final result = await repository.katahoCodeFor('7MV7P8CF+J68');
print(result?.display);
```

Call `await repository.preload()` during startup to decrypt and cache all
datasets before the first lookup.

## Input format

Inputs may contain the standard Plus Code separator, spaces, or hyphens. The
repository normalizes them before lookup and expects 11 significant
characters. A lookup returns `null` for invalid input or an unmapped code.

## Data tooling

The scripts in `tool/` are for dataset administrators who have the encryption
key. See [tool/README.md](tool/README.md) before decrypting or re-encrypting
the assets.

## License

MIT. See [LICENSE](LICENSE).
