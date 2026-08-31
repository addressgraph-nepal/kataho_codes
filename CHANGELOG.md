## 0.3.0

Added the KID — a 12-digit, separator-free form of a Kataho Code. Coordinates,
Plus Codes, Kataho Codes, and KIDs now all convert to each other.

* Added the `geocode_word_kids` dataset, mapping each 2-character Plus Code
  word segment to a 3-digit group. A KID is the region number (2), both word
  halves (3 + 3), and the house number (4): `7MW4JQF6+62R` ->
  `192451960075`.
* Added `katahoCodeForKid` and `kidForKatahoCode`, plus the `wordKidForCode`
  and `wordKidForKid` dataset lookups.
* `GeocodeRepository.resolve` now also detects a KID, so any of the four
  representations resolves through the same call.
* `KatahoCode` carries `kid` alongside `plusCode`, `latitude`, and
  `longitude`.
* `KatahoCodeBuilder` accepts a `kid` argument.
* Added `tool/encrypt_word_kids.dart`, which encrypts the KID dataset with the
  existing key instead of rotating it the way `encrypt_assets.dart` would.

## 0.2.0

Conversion is now bidirectional: coordinates, Plus Codes, and Kataho Codes all
convert to each other.

* Added `plusCodeToArea`, decoding a full Plus Code back to its bounding box
  and centre point — the inverse of `plusCodeFromLatLng`.
* Added `GeocodeRepository.resolve`, which detects whether the input is a Plus
  Code, a Kataho Code, or a `"lat,lng"` pair.
* Added `katahoCodeForDisplay` and `katahoCodeForLatLng`, plus the
  `numberForName`/`wordForName`/`suffixForName` reverse dataset lookups.
  Matching accepts Devanagari or Western digits, unpadded house numbers, and
  dataset hints.
* `KatahoCode` now carries `latitude`, `longitude`, and `formattedPlusCode`.
* `KatahoCodeBuilder` accepts `katahoCode` and a free-form `input` alongside
  `plusCode` and coordinates.

Breaking changes:

* `KatahoCodeCubit.resolve` now routes through `GeocodeRepository.resolve`
  rather than `katahoCodeFor`, so a custom `GeocodeRepository` must override
  `resolve` to intercept lookups.
* `KatahoCodeUnavailable.plusCode` is renamed to `input`, since it may now
  hold any of the three input forms.

## 0.1.1

* Added package metadata, API documentation, and a Flutter example.

## 0.1.0

* Initial public release.
