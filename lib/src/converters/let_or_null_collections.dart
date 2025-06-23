//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Converts [input] to `Iterable<Option<T>>`, returning [Null] on failure.
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
Iterable<T?>? letIterableOrNull<T>(dynamic input) {
  final nullable = isNullable<T>();
  if (!nullable && input == null) return null;
  dynamic decoded;
  if (input is String) {
    decoded = jsonDecodeOrNull<Iterable<dynamic>>(input.trim());
  } else {
    decoded = input;
  }
  if (decoded is Iterable) {
    return decoded.map(letOrNull<T>);
  }
  return null;
}

// Converts [input] to `List<Option<T>>`, returning [Null] on failure.
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
@pragma('vm:prefer-inline')
List<T?>? letListOrNull<T>(dynamic input) {
  return letIterableOrNull<T>(input)?.toList();
}

// Converts [input] to `Set<Option<T>>`, returning [Null] on failure.
///
/// Supported types:
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
@pragma('vm:prefer-inline')
Set<T?>? letSetOrNull<T>(dynamic input) {
  return letIterableOrNull<T>(input)?.toSet();
}
