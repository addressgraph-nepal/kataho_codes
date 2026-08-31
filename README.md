# kataho_code

Flutter package for converting between coordinates, Nepal-focused 11-character
Plus Codes, human-readable Kataho Codes, and KIDs — in any direction.

```
latitude/longitude   27.7172, 85.3240
Plus Code            7MW4JQF6+62R
Kataho Code          १९ माणिक प्रकाश ००७५
KID                  192451960075
```

Give the package any one of the four and it returns all of them. It includes
encrypted geocode datasets, model classes, an async repository, a
`KatahoCodeCubit`, and a ready-to-use `KatahoCodeBuilder`.

## Installation

```yaml
dependencies:
  kataho_code: ^0.4.0
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
  katahoCode: '१९ माणिक प्रकाश ००७५',
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text('${code.latitude}, ${code.longitude}'),
  placeholder: const Text('Loading...'),
)

// From a KID
KatahoCodeBuilder(
  kid: '192451960075',
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  builder: (context, code) => Text(code.display),
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

Provide exactly one of `plusCode`, `katahoCode`, `kid`, `input`, or
`latitude` + `longitude`.

### Asking for one representation

Set `output` and use `outputBuilder` when you want a specific form rather than
the whole result:

```dart
KatahoCodeBuilder(
  input: userText,
  output: KatahoCodeType.kid,
  authKey: const String.fromEnvironment('KATAHO_AUTH_KEY'),
  outputBuilder: (context, code, value) => Text(value ?? '—'),
  placeholder: const Text('Loading...'),
)
```

`outputBuilder` still receives the full `KatahoCode`, so the other forms stay
available. `KatahoCodeType` has `latLng`, `plusCode`, `katahoCode`,
`katahoCodeLatin`, and `kid`.

## The result

Every lookup returns a `KatahoCode` carrying all four representations, so one
conversion covers every direction:

```dart
code.display           // '१९ माणिक प्रकाश ००७५'  Devanagari
code.displayLatin      // '19 माणिक प्रकाश 0075'  Western digits
code.plusCode          // '7MW4JQF662R'          normalised
code.formattedPlusCode // '7MW4JQF6+62R'         canonical
code.kid               // '192451960075'
code.latitude          // 27.7172
code.longitude         // 85.3240
code.segmentedPlusCode // '7MW4-JQF6-62R'        for debugging
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

await repository.resolve('7MW4JQF6+62R');        // Plus Code
await repository.resolve('१९ माणिक प्रकाश ००७५');  // Kataho Code
await repository.resolve('192451960075');        // KID
await repository.resolve('27.7172, 85.3240');    // coordinates
```

To go straight from any input to one specific output, use `convert`:

```dart
await repository.convert(userText, KatahoCodeType.kid);
// '192451960075'

await repository.convert('192451960075', KatahoCodeType.latLng);
// '27.717200, 85.324000'
```

Or read any form off a resolved code with `valueFor`:

```dart
final code = await repository.resolve(userText);
code?.valueFor(KatahoCodeType.plusCode); // '7MW4JQF6+62R'
```

Or call a direction explicitly:

```dart
await repository.katahoCodeFor('7MW4JQF6+62R');
await repository.katahoCodeForLatLng(27.7172, 85.3240);
await repository.katahoCodeForDisplay('१९ माणिक प्रकाश ००७५');
await repository.katahoCodeForKid('192451960075');
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

**KIDs** are exactly 12 digits with no separators, in Devanagari or Western
script. The layout is fixed-width, so it parses unambiguously:

```
19   245   196   0075
└ region    └ word halves   └ house number
     JQ->245  F6->196
```

The two 3-digit word groups come from splitting the 4-character word segment
of the Plus Code (`JQF6` -> `JQ` + `F6`) and mapping each half through
`geocode_word_kids`.

**Coordinates** are accepted as `"lat,lng"` or `"lat lng"`.

A lookup returns `null` for invalid input or an unmapped code.

## Data tooling

The scripts in `tool/` are for dataset administrators who have the encryption
key. See [tool/README.md](tool/README.md) before decrypting or re-encrypting
the assets.

## License

MIT. See [LICENSE](LICENSE).
