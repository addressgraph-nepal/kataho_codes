# kataho_code

Flutter package for converting 11-character Plus Codes into Kataho Codes. The
package owns the geocode models, encrypted datasets, repository, cubit, and UI
builder.

## Required encryption key

**The package does not contain the decryption key. Every package consumer must
provide the Base64-encoded 32-byte AES key as the required `authKey` argument.**

For the example app, provide it at build/run time:

```bash
flutter run --dart-define=KATAHO_AUTH_KEY=<base64-aes-key>
```

Example usage:

```dart
KatahoCodeBuilder(
  authKey: '<admin-generated-key>',
  plusCode: '7MV7P8CF+J68',
  builder: (context, code) => Text(code.display),
  placeholder: const Text('Loading...'),
)
```

Never commit the real key to the public repository.

As the dataset administrator, generate a key once with:

```bash
dart run tool/generate_key.dart
```

Store the generated key in your password manager or secret vault. Give the
same key privately only to authorized users of this package. Do not commit it
to the public GitHub repository.

The encrypted datasets must be created with this same key. If you rotate the
key, re-encrypt the datasets and distribute the replacement key to users.

The app currently uses this package through a local path dependency:

```yaml
kataho_code:
  path: packages/kataho_code
```

When the package is moved to a private GitHub repository, replace it with:

```yaml
kataho_code:
  git:
    url: git@github.com:<organization>/<private-repository>.git
    ref: main
```

The package expects Plus Codes in the `4 + 4 + 3` format, for example
`7MV7P8CF+J68`, and resolves them as `०९ लक्ष निवास १८३८` when the datasets
contain the corresponding entries.
# kataho_codes
