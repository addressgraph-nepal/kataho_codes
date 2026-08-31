/// One of the four interchangeable representations of a location.
///
/// Pass a value to ask the package for that specific form, rather than
/// reading it off the resolved [KatahoCode] yourself.
enum KatahoCodeType {
  /// Decimal coordinates, formatted as `"27.717200, 85.324000"`.
  latLng,

  /// A Plus Code in canonical form, e.g. `"7MW4JQF6+62R"`.
  plusCode,

  /// A Kataho Code in Devanagari, e.g. `"१९ माणिक प्रकाश ००७५"`.
  katahoCode,

  /// A Kataho Code with Western digits, e.g. `"19 माणिक प्रकाश 0075"`.
  katahoCodeLatin,

  /// A 12-digit KID, e.g. `"192451960075"`.
  kid,
}
