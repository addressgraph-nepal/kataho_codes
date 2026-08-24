# Encrypted geocode assets

The three geocode JSON files ship as AES-256-GCM blobs instead of plaintext.

## What this does and does not protect against

**Does:** stop someone who unzips the APK/IPA from reading the geocode mapping
as plain JSON.

**Does not:** stop a determined reverse-engineer. The decryption key ships
inside the binary, so anyone who unpacks the app can recover it — with `strings`
and a disassembler, or by hooking `GeocodeCipher.decryptJson` with Frida and
reading the plaintext out of memory. This is inherent to decrypting offline: if
the app can decrypt without a server, so can an attacker holding the app.

Secure storage protects the key *at rest on device* (Keychain / Android
EncryptedSharedPreferences) once seeded. It cannot be the key's origin, because
it is empty on first launch — the key is seeded there from a compile-time
constant on first run.

If the data ever needs real protection, the only workable answer is a backend
that gates access, which is out of scope for this design.

## Workflow

The geocode data is treated as **final**, so only the encrypted `.enc` blobs
live in the repo — there is no plaintext JSON to maintain, and normal feature
work never re-encrypts anything. `assets/data/` contains only:

```
nepal_geocode.json.enc
geocode_words.json.enc
geocode_number_suffixes.json.enc
```

### If the data ever does need to change

Round trip through the recovery tool:

```bash
# 1. recover the readable JSON (into build/decrypted_geocode/)
dart run tool/decrypt_assets.dart <base64-key>

# 2. edit the JSON there

# 3. re-encrypt with the SAME key
dart run tool/encrypt_assets.dart <base64-key> build/decrypted_geocode
```

The key is the Base64-encoded 32-byte AES key supplied to
`GeocodeCipher(encryptionKey: ...)`.

**Pass the existing key.** Running `encrypt_assets.dart` with no argument mints
a new key. If you ship blobs encrypted under a new key, every consumer must be
given that new key.

Do not leave the recovered plaintext lying around in `build/` once you are
done — it is the thing the encryption exists to avoid shipping.

## Files

| File | Role |
|---|---|
| `tool/encrypt_assets.dart` | Encryptor, for the rare data change. Not compiled into the app. |
| `tool/decrypt_assets.dart` | Recovery tool — turns `.enc` back into readable JSON. |
| `lib/src/geocode_cipher.dart` | Consumer-provided key + decryption. |
| `lib/src/geocode_repository.dart` | Loads assets, caches decrypted models. |
| `lib/src/models/` | `GeocodeNumber`, `GeocodeWord`, `GeocodeNumberSuffix`. |

Because the plaintext is gone, **the consumer-provided encryption key is the
only way to read this data.** Losing it means losing the dataset.

## Usage in app code

`GeocodeRepository` is registered in `lib/core/di/injection.dart` and preloaded
in `main()`, so reads after startup resolve from the in-memory cache:

```dart
final words = await getIt<GeocodeRepository>().words();
final suffixes = await getIt<GeocodeRepository>().suffixes();
```

## Do not commit the key

The key belongs in a secret build configuration. Keep it out of commit messages,
issues, and CI logs. Anyone with the key plus a shipped `.enc` blob has the
plaintext.
