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

import 'package:collection/collection.dart';

/// Provides a safe, string-based lookup method for enum iterables.
extension ValueOfOnEnumExt<T extends Enum> on Iterable<T> {
  /// Returns the enum value from this iterable that matches the given string [value].
  ///
  /// The comparison is case-insensitive. Returns `null` if no match is found.
  /// This is commonly used with `MyEnum.values`.
  ///
  /// {@tool snippet}
  /// ```dart
  /// enum Status { pending, active, done }
  ///
  /// void main() {
  ///   // Successful lookup (case-insensitive)
  ///   final status = Status.values.valueOf('ACTIVE');
  ///   print(status); // Prints: Status.active
  ///
  ///   // Failed lookup
  ///   final unknown = Status.values.valueOf('archived');
  ///   print(unknown); // Prints: null
  /// }
  /// ```
  /// {@end-tool}
  @pragma('vm:prefer-inline')
  T? valueOf(String? value) {
    return firstWhereOrNull(
      (type) => type.name.toLowerCase() == value?.toLowerCase().trim(),
    );
  }

  /// Like [valueOf], but throws instead of returning `null` when [value] is
  /// `null` or matches no enum value in this iterable.
  ///
  /// Matching is the same as [valueOf]: case-insensitive, with surrounding
  /// whitespace trimmed.
  ///
  /// Throws an [ArgumentError] naming [value] and the names it was compared
  /// against.
  ///
  /// {@tool snippet}
  /// ```dart
  /// enum Status { pending, active, done }
  ///
  /// void main() {
  ///   print(Status.values.valueOfOrThrow('ACTIVE')); // Status.active
  ///   Status.values.valueOfOrThrow('archived'); // throws ArgumentError
  /// }
  /// ```
  /// {@end-tool}
  T valueOfOrThrow(String? value) {
    final match = valueOf(value);
    if (match != null) return match;
    final names = map((type) => type.name).join(', ');
    throw ArgumentError.value(
      value,
      'value',
      'No enum value matches (case-insensitive) among [$names]',
    );
  }
}
