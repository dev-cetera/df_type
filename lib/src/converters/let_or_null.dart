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

/// True when running on the JS runtime (Flutter web / dart2js / dartdevc).
///
/// Detection is via `identical(0, 0.0)`: on the Dart VM the int `0` and the
/// double `0.0` are distinct objects (different runtime types), but on JS
/// both are the same `Number`, so the identity check passes there. Computed
/// once at load and held in a `final` to avoid per-call overhead.
final bool isJsRuntime = identical(0, 0.0);

/// 2^53 — the largest integer that JS `Number` (IEEE 754 double) can
/// represent exactly. Beyond this, integer arithmetic silently loses
/// precision. Used as the safe-integer bound on the JS runtime.
const double jsSafeIntegerBound = 9007199254740992.0;

/// 2^63 — one past the maximum signed 64-bit integer. The VM's `int` is a
/// true int64, so this is the (positive-side) bound. Negative-side bound is
/// `-2^63` and *is* in range, hence the asymmetric comparison in
/// [letIntOrNull].
const double vmInt64Bound = 9223372036854775808.0;

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
  // Enforced in release as well: a stripped assert would let a misuse like
  // `letOrNull<List<int>>(...)` silently return null, which is
  // indistinguishable from a real conversion failure. For medical-grade
  // code that's an unacceptable silent failure.
  if ((isSubtype<T, List<dynamic>>() && !isSubtype<List<dynamic>, T>()) ||
      (isSubtype<T, Set<dynamic>>() && !isSubtype<Set<dynamic>, T>()) ||
      (isSubtype<T, Iterable<dynamic>>() &&
          !isSubtype<Iterable<dynamic>, T>()) ||
      (isSubtype<T, Map<dynamic, dynamic>>() &&
          !isSubtype<Map<dynamic, dynamic>, T>())) {
    throw ArgumentError(
      'letOrNull<$T> cannot be used with specific collection types due to '
      'type safety. Only the broadest collection types '
      '(Iterable<dynamic>, Map<dynamic, dynamic>) are supported.',
    );
  }
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
/// `null` in produces `null` out — never the literal four-character string
/// `'null'` that `null.toString()` would otherwise yield. Leaking that
/// sentinel into a medical record is unacceptable, so the null guard is the
/// safer default.
///
/// Supported types:
///
/// - [Object]
String? letAsStringOrNull(dynamic input) {
  if (input == null) return null;
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
/// Returns [Null] for `NaN`, `Infinity`, `-Infinity`, and any value whose
/// integer representation would lose precision or saturate on the current
/// runtime. Calling `num.toInt()` on out-of-range doubles would throw
/// `UnsupportedError` or silently clamp to `int64.min` / `int64.max` —
/// both unacceptable for life-critical code.
///
/// **Cross-runtime safety.** The accepted range adapts to the runtime:
///
/// - On the **Dart VM**, `int` is a true 64-bit integer, so values in
///   `[-2^63, 2^63)` round-trip exactly.
/// - On the **JS runtime** (Flutter web / dart2js / dartdevc), `int` is
///   backed by a 64-bit double, so only `[-2^53, 2^53]` is exact. Values
///   outside that band have already lost precision by the time we see
///   them, so [letIntOrNull] returns `null` rather than handing back a
///   silently-rounded value.
///
/// Supported input types:
///
/// - [int]
/// - [num] / [double]
/// - [String]
int? letIntOrNull(dynamic input) {
  final n = letNumOrNull(input);
  if (n == null) return null;
  if (n is int) {
    // On JS, an `n is int` value past 2^53 may have already lost precision
    // during parsing — refuse it for life-critical use.
    if (isJsRuntime && (n > 9007199254740992 || n < -9007199254740992)) {
      return null;
    }
    return n;
  }
  final d = n.toDouble();
  if (!d.isFinite) return null;
  if (isJsRuntime) {
    if (d > jsSafeIntegerBound || d < -jsSafeIntegerBound) return null;
  } else {
    // VM: 2^63 itself is *not* in int64 (max is 2^63 - 1), but -2^63 *is*.
    if (d >= vmInt64Bound || d < -vmInt64Bound) return null;
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
