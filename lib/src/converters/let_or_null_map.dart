//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Converts [input] to `Map<K, Option<V>>`, returning [Null] on failure.
///
/// Supported types:
///
/// - [bool]
/// - [num]
/// - [double]
/// - [int]
/// - [String]
/// - [DateTime]
/// - [Uri],
/// - [Iterable] (dynamic)
/// - [List]  (dynamic)
/// - [Set] (dynamic)
/// - [Map] (dynamic, dynamic)
Map<K, V>? letMapOrNull<K, V>(dynamic input) {
  return switch (input) {
    final Map<dynamic, dynamic> m => _convertMapOrNull<K, V>(m),
    final String s => switch (jsonDecodeOrNull<Map<dynamic, dynamic>>(
        s.trim(),
      )) {
        final Map<dynamic, dynamic> d => _convertMapOrNull<K, V>(d),
        _ => null,
      },
    _ => null,
  };
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Map<K, V>? _convertMapOrNull<K, V>(Map<dynamic, dynamic> map) {
  final keyNullable = isNullable<K>();
  final valueNullable = isNullable<V>();
  final buffer = <K, V>{};
  for (final entry in map.entries) {
    final convertedKey = letOrNull<K>(entry.key);
    final convertedValue = letOrNull<V>(entry.value);
    if (!keyNullable && convertedKey == null) return null;
    if (!valueNullable && convertedValue == null) return null;
    // Reject duplicate keys after coercion. For instance,
    // `{1: 'a', '1': 'b'}` with K=int both project to the key `1` — silently
    // letting the second entry overwrite the first is indistinguishable from
    // a successful conversion, which is unsafe for life-critical data.
    if (buffer.containsKey(convertedKey)) return null;
    buffer[convertedKey as K] = convertedValue as V;
  }
  return buffer;
}
