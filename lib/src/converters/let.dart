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

import 'dart:convert' show jsonDecode;

import 'package:collection/collection.dart' show IterableExtension;

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Safely casts [input] to type [T] using a static type check (`is`),
/// returning `null` if the cast is not possible.
@pragma('vm:prefer-inline')
T? letAsOrNull<T>(dynamic input) => input is T ? input : null;

/// Safely casts [input] to type [T] using a `try-catch` block (`as`),
/// returning `null` if the cast throws an exception.
@pragma('vm:prefer-inline')
T? castAsOrNull<T>(dynamic input) {
  try {
    return input as T;
  } catch (_) {
    return null;
  }
}

/// Attempts to convert a dynamic [input] to the specified type [T].
///
/// This is a high-level dispatcher that uses more specific `let...OrNull`
/// helpers based on the target type [T]. It returns `null` if the conversion
/// is not supported or fails.
///
/// Supported direct conversion types:
/// - `bool`, `double`, `int`, `num`, `String`, `DateTime`, `Uri`
T? letOrNull<T>(dynamic input) {
  try {
    if (T == dynamic) return input as T;
    if (input == null && T != Null) return null;
    if (T == input.runtimeType) return input as T;

    // Dispatch to specific conversion helpers based on the target type.
    if (typeEquality<T, double>() || typeEquality<T, double?>()) {
      return letDoubleOrNull(input) as T;
    } else if (typeEquality<T, int>() || typeEquality<T, int?>()) {
      return letIntOrNull(input) as T;
    } else if (typeEquality<T, num>() || typeEquality<T, num?>()) {
      return letNumOrNull(input) as T;
    } else if (typeEquality<T, bool>() || typeEquality<T, bool?>()) {
      return letBoolOrNull(input) as T;
    } else if (typeEquality<T, DateTime>() || typeEquality<T, DateTime?>()) {
      return letDateTimeOrNull(input) as T;
    } else if (typeEquality<T, Uri>() || typeEquality<T, Uri?>()) {
      return letUriOrNull(input) as T;
    } else if (typeEquality<T, String>() || typeEquality<T, String?>()) {
      return input?.toString() as T;
    }
    // For any other types, fall back to a direct cast.
    return input as T;
  } catch (_) {}
  return null;
}

/// Converts [input] to a [num], returning `null` on failure.
///
/// Handles the following input types:
/// - `num`: Returns the number directly.
/// - `String`: Parses the string as a number.
num? letNumOrNull(dynamic input) {
  if (input is num) return input;
  if (input is String) {
    final trimmed = input.trim();
    return num.tryParse(trimmed);
  }
  return null;
}

/// Converts [input] to an [int], returning `null` on failure.
@pragma('vm:prefer-inline')
int? letIntOrNull(dynamic input) => letNumOrNull(input)?.toInt();

/// Converts [input] to a [double], returning `null` on failure.
@pragma('vm:prefer-inline')
double? letDoubleOrNull(dynamic input) => letNumOrNull(input)?.toDouble();

/// Converts [input] to a [bool], returning `null` on failure.
///
/// Handles the following input types:
/// - `bool`: Returns the boolean directly.
/// - `String`: Returns `true` for `"true"` (case-insensitive) and `false` for
///   `"false"`. Other strings result in `null`.
bool? letBoolOrNull(dynamic input) {
  if (input is bool) return input;
  if (input is String) {
    return bool.tryParse(input.trim(), caseSensitive: false);
  }
  return null;
}

/// Converts [input] to a [Uri], returning `null` on failure.
Uri? letUriOrNull(dynamic input) {
  if (input is Uri) return input;
  if (input is String) return Uri.tryParse(input.trim());
  return null;
}

/// Converts [input] to a [DateTime], returning `null` on failure.
DateTime? letDateTimeOrNull(dynamic input) {
  if (input is DateTime) return input;
  if (input is String) return DateTime.tryParse(input);
  return null;
}

/// Converts a [dynamic] input into a `Map<K, V>`, returning `null` on failure.
///
/// This function is highly flexible and accepts the following inputs:
/// - **A `Map`**: Recursively converts its keys and values to types `K` and `V`.
/// - **A JSON `String`**: Parses the string and then converts the resulting map.
///
/// - [filterNulls]: If `true`, removes entries where a key or value becomes `null`
///   after a failed conversion and the target type is non-nullable.
/// - [nullFallback]: A value to use if a map value converts to `null`.
Map<K, V>? letMapOrNull<K, V>(
  dynamic input, {
  bool filterNulls = false,
  dynamic nullFallback,
}) {
  dynamic decoded;
  try {
    if (input is String) {
      // If input is a string, assume it's JSON.
      final trimmed = input.trim();
      if (trimmed.isEmpty) return <K, V>{};
      decoded = jsonDecode(trimmed);
    } else {
      decoded = input;
    }
    if (decoded is Map) {
      final temp = decoded.entries.map((entry) {
        final convertedKey = letOrNull<K>(entry.key);
        final convertedValue = letOrNull<V>(entry.value) ?? letOrNull<V?>(nullFallback);
        if (filterNulls) {
          if (!isNullable<K>() && convertedKey == null) return const _Empty();
          if (!isNullable<V>() && convertedValue == null) return const _Empty();
        }
        return MapEntry(convertedKey as K, convertedValue as V);
      });
      final filtered = temp.where((e) => e != const _Empty()).cast<MapEntry<K, V>>();
      return Map.fromEntries(filtered);
    }
  } catch (_) {}
  return null;
}

/// Converts a [dynamic] input into an `Iterable<T>`, returning `null` if the
/// input cannot be interpreted as a collection.
///
/// This function is highly flexible and accepts the following inputs:
/// - **An `Iterable`**: Converts each element to type `T`.
/// - **A `String`**: Parses it as a comma-separated list (e.g., `"1,2,3"`).
///
/// - [filterNulls]: If `true`, removes elements that become `null` after conversion.
/// - [nullFallback]: A value to use if an element converts to `null`.
Iterable<T>? letIterableOrNull<T>(
  dynamic input, {
  bool filterNulls = false,
  dynamic nullFallback,
}) {
  final nullable = isNullable<T>();
  if (!nullable && input == null) return null;

  dynamic decoded;
  if (input is String) {
    decoded = parseStringAsIterable(input);
  } else {
    decoded = input;
  }

  if (decoded is Iterable) {
    try {
      final mapped = decoded.map((e) {
        final result = letOrNull<T>(e) ?? letOrNull<T>(nullFallback);
        if (filterNulls && !nullable && result == null) {
          return const _Empty();
        }
        return result;
      });
      final filtered = mapped.where((e) => e != const _Empty()).cast<T>();
      return filterNulls ? filtered.where((e) => e != null) : filtered;
    } catch (_) {}
  }
  return null;
}

/// Converts a [dynamic] input to a `List<T>`, returning `null` on failure.
///
/// See [letIterableOrNull] for details on accepted inputs and behavior.
List<T>? letListOrNull<T>(
  dynamic input, {
  bool filterNulls = false,
  T? nullFallback,
}) {
  return letIterableOrNull<T>(
    input,
    filterNulls: filterNulls,
    nullFallback: nullFallback,
  )?.toList();
}

/// Converts a [dynamic] input to a `Set<T>`, returning `null` on failure.
///
/// See [letIterableOrNull] for details on accepted inputs and behavior.
Set<T>? letSetOrNull<T>(
  dynamic input, {
  bool filterNulls = false,
  T? nullFallback,
}) {
  return letIterableOrNull<T>(
    input,
    filterNulls: filterNulls,
    nullFallback: nullFallback,
  )?.toSet();
}

/// Attempts to convert a String [input] to an enum of type [T].
///
/// The comparison is case-insensitive. Returns `null` if the input is not a
/// [String] or if no matching enum value is found.
T? letEnumOrNull<T extends Enum>(dynamic input, List<T> enumValues) {
  // This function is designed to work with String inputs only.
  if (input is! String) return null;

  // Find the enum by its name, case-insensitively.
  return enumValues.firstWhereOrNull(
    (e) => e.name.toLowerCase() == input.toLowerCase().trim(),
  );
}

/// Internal helper to parse a string as an iterable of strings.
/// Strips common brackets and splits by comma.
Iterable<String> parseStringAsIterable(String input) {
  var temp = input.trim();
  if (temp.isEmpty) return const [];
  // Strip optional surrounding brackets.
  if (temp.length > 1 &&
      ((temp.startsWith('[') && temp.endsWith(']')) ||
          (temp.startsWith('{') && temp.endsWith('}')) ||
          (temp.startsWith('(') && temp.endsWith(')')))) {
    temp = temp.substring(1, temp.length - 1);
  }
  return temp.split(',').map((e) => e.trim());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A private sentinel class used to mark elements for removal during mapping,
/// distinguishing them from legitimate `null` values.
class _Empty {
  const _Empty();
}
