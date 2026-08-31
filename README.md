# kataho_code

Flutter package for converting between coordinates, Nepal-focused 11-character
Plus Codes, and human-readable Kataho Codes — in any direction.

```
latitude/longitude  <-->  Plus Code  <-->  Kataho Code
   27.7172, 85.3240        7MV7P8CF+J68     ०९ लक्ष निवास १८३८
```

Give the package any one of the three and it returns all of them. It includes
encrypted geocode datasets, model classes, an async repository, a
`KatahoCodeCubit`, and a ready-to-use `KatahoCodeBuilder`.

## Installation

```yaml
dependencies:
  kataho_code: ^0.2.0
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

`KatahoCodeBuilder` accepts a Plus Code, a Kataho Code, coordinates, or — when
the input type is not known ahead of time — a free-form `input`:

```dart
// From a Plus Code
KatahoCodeBuilder(
  plusCode: '7MV7P8CF+J68',
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text(code.display),
  placeholder: const Text('Loading...'),
)

// From coordinates
KatahoCodeBuilder(
  latitude: 27.7172,
  longitude: 85.3240,
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text(code.formattedPlusCode),
  placeholder: const Text('Loading...'),
)

// From a Kataho Code
KatahoCodeBuilder(
  katahoCode: '०९ लक्ष निवास १८३८',
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text('${code.latitude}, ${code.longitude}'),
  placeholder: const Text('Loading...'),
)

// Anything the user typed
KatahoCodeBuilder(
  input: userText,
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text(code.display),
  placeholder: const Text('Loading...'),
)
```

Provide exactly one of `plusCode`, `katahoCode`, `input`, or
`latitude` + `longitude`.

## The result

Every lookup returns a `KatahoCode` carrying all three representations, so one
conversion covers every direction:

```dart
code.display           // '०९ लक्ष निवास १८३८'  Devanagari
code.displayLatin      // '09 लक्ष निवास 1838'  Western digits
code.plusCode          // '7MV7P8CFJ68'         normalised
code.formattedPlusCode // '7MV7P8CF+J68'        canonical
code.latitude          // 27.7172
code.longitude         // 85.3240
code.segmentedPlusCode // '7MV7-P8CF-J68'       for debugging
```

`latitude` and `longitude` are the centre of the area the Plus Code names — an
11-character code covers roughly 3.5m x 2.8m.

## Repository usage

Use `GeocodeRepository` directly when the application owns loading and state.
`resolve` detects the input type for you:

```dart
final repository = GeocodeRepository(
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
);

await repository.resolve('7MV7P8CF+J68');       // Plus Code
await repository.resolve('०९ लक्ष निवास १८३८');  // Kataho Code
await repository.resolve('27.7172, 85.3240');   // coordinates
```

Or call a direction explicitly:

```dart
await repository.katahoCodeFor('7MV7P8CF+J68');
await repository.katahoCodeForLatLng(27.7172, 85.3240);
await repository.katahoCodeForDisplay('०९ लक्ष निवास १८३८');
```

Every one returns the same `KatahoCode?`, `null` when the input is
unrecognised or has no mapping. Call `await repository.preload()` during
startup to decrypt and cache all datasets before the first lookup.

## Plus Codes without the datasets

`plusCodeFromLatLng` and `plusCodeToArea` are standalone and need no
encryption key:

```dart
final code = plusCodeFromLatLng(27.7172, 85.3240); // '7MV7P88F+VJC'

final area = plusCodeToArea('7MV7P88F+VJC')!;
area.latitude;    // centre latitude
area.longitude;   // centre longitude
area.latitudeLo;  // bounding box edges
```

`plusCodeToArea` returns `null` for a short/relative code such as `8CF+J68`,
which cannot be decoded without a reference location.

## Input format

**Plus Codes** may contain the standard separator, spaces, or hyphens, in any
case. The repository normalises them and expects 11 significant characters.

**Kataho Codes** are matched leniently: digits may be Devanagari (`०९`) or
Western (`09`), house numbers may be unpadded (`0` for `0000`), and each
segment also matches the `hints` recorded in the datasets, so a romanised
`9 laxya niwas 1838` resolves too.

**Coordinates** are accepted as `"lat,lng"` or `"lat lng"`.

A lookup returns `null` for invalid input or an unmapped code.

## Data tooling

The scripts in `tool/` are for dataset administrators who have the encryption
key. See [tool/README.md](tool/README.md) before decrypting or re-encrypting
the assets.

## License

MIT. See [LICENSE](LICENSE).
