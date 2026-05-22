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

import 'dart:convert' show JsonDecoder;

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Attempts to convert a dynamic [input] to the specified type [T], returning
/// [Null] on failure.
///
/// This is a high-level dispatcher that uses more specific `let...OrNull`
/// helpers based on the target type [T].
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
T? letOrNull<T>(dynamic input) {
  assert(
    !(isSubtype<T, List<dynamic>>() && !isSubtype<List<dynamic>, T>()) &&
        !(isSubtype<T, Set<dynamic>>() && !isSubtype<Set<dynamic>, T>()) &&
        !(isSubtype<T, Iterable<dynamic>>() &&
            !isSubtype<Iterable<dynamic>, T>()) &&
        !(isSubtype<T, Map<dynamic, dynamic>>() &&
            !isSubtype<Map<dynamic, dynamic>, T>()),
    'letOrNull<$T> cannot be used with specific collection types due to type safety. '
    'Only generic collection types are supported.',
  );
  if (input is T) return input;
  if (input == null) return null;
  final raw = () {
    if (typeEquality<T, double>() || typeEquality<T, double?>()) {
      return letDoubleOrNull(input);
    } else if (typeEquality<T, int>() || typeEquality<T, int?>()) {
      return letIntOrNull(input);
    } else if (typeEquality<T, bool>() || typeEquality<T, bool?>()) {
      return letBoolOrNull(input);
    } else if (typeEquality<T, DateTime>() || typeEquality<T, DateTime?>()) {
      return letDateTimeOrNull(input);
    } else if (typeEquality<T, Uri>() || typeEquality<T, Uri?>()) {
      return letUriOrNull(input);
    } else if (isSubtype<T, List<dynamic>>()) {
      return letListOrNull<dynamic>(input);
    } else if (isSubtype<T, Set<dynamic>>()) {
      return letSetOrNull<dynamic>(input);
    } else if (isSubtype<T, Iterable<dynamic>>()) {
      return letIterableOrNull<dynamic>(input);
    } else if (isSubtype<T, Map<dynamic, dynamic>>()) {
      return letMapOrNull<dynamic, dynamic>(input);
    } else if (typeEquality<T, String>() || typeEquality<T, String?>()) {
      return letAsStringOrNull(input);
    }
    return input;
  }();

  return letAsOrNull<T>(raw);
}

/// Casts [input] to type [T], returning [Null] on failure.
///
/// Supported types:
///
/// - [Object]
@pragma('vm:prefer-inline')
T? letAsOrNull<T>(dynamic input) => input is T ? input : null;

/// Converts [input] to [String], returning [Null] on failure.
///
/// Supported types:
///
/// - [Object]
String? letAsStringOrNull(dynamic input) {
  try {
    return input.toString();
  } catch (_) {
    return null;
  }
}

/// Parses a JSON [input] into an object of type [T], returning [Null] on
/// failure.
///
/// Supported types:
///
/// - [Object]
T? jsonDecodeOrNull<T>(String input) {
  try {
    final decoded = const JsonDecoder().convert(input);
    return decoded is T ? decoded : null;
  } catch (e) {
    return null;
  }
}

/// Converts [input] to [num], returning [Null] on failure.
///
/// Supported types:
///
/// - [String]
/// - [num]
/// - [double]
/// - [int]
/// - [String]
num? letNumOrNull(dynamic input) {
  if (input is num) return input;
  if (input is String) {
    final trimmed = input.trim();
    return num.tryParse(trimmed);
  }
  return null;
}

/// Converts [input] to [int], returning [Null] on failure.
///
/// Returns [Null] for `NaN`, `Infinity`, `-Infinity`, and any value outside
/// the signed 64-bit integer range — calling `num.toInt()` on those would
/// throw `UnsupportedError` or silently saturate to `int64.min` / `int64.max`,
/// both of which are unacceptable for mission-critical code.
///
/// Supported types:
///
/// - [String]
/// - [num]
/// - [double]
/// - [int]
/// - [String]
int? letIntOrNull(dynamic input) {
  final n = letNumOrNull(input);
  if (n == null) return null;
  if (n is int) return n;
  final d = n.toDouble();
  if (!d.isFinite) return null;
  // 9.223372036854776e18 is the smallest double strictly greater than
  // int64.max; the symmetric bound on the negative side is exact.
  if (d >= 9223372036854775808.0 || d < -9223372036854775808.0) {
    return null;
  }
  return d.toInt();
}

/// Converts [input] to [double], returning [Null] on failure.
///
/// Supported types:
///
/// - [String]
/// - [num]
/// - [double]
/// - [int]
/// - [String]
@pragma('vm:prefer-inline')
double? letDoubleOrNull(dynamic input) => letNumOrNull(input)?.toDouble();

/// Converts [input] to [bool], returning [Null] on failure.
///
/// Supported types:
///
/// - [String]
/// - [bool]
bool? letBoolOrNull(dynamic input) {
  if (input is bool) return input;
  if (input is String) {
    return bool.tryParse(input.trim(), caseSensitive: false);
  }
  return null;
}

/// Converts [input] to [Uri], returning [Null] on failure.
///
/// Supported types:
///
/// - [String]
/// - [Uri]
Uri? letUriOrNull(dynamic input) {
  if (input is Uri) return input;
  if (input is String) return Uri.tryParse(input.trim());
  return null;
}

/// Converts [input] to [bool], returning [Null] on failure.
///
/// Supported types:
///
/// - [String]
/// - [DateTime]
DateTime? letDateTimeOrNull(dynamic input) {
  if (input is DateTime) return input;
  if (input is String) return DateTime.tryParse(input.trim());
  return null;
}
