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
