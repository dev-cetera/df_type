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

import 'dart:async';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Convenience methods for inspecting and converting a [FutureOr].
extension $FutureOrExtension<T> on FutureOr<T> {
  /// Returns true if this is a [Future].
  @pragma('vm:prefer-inline')
  bool get isFuture => this is Future<T>;

  /// Returns true if this is not a [Future].
  @pragma('vm:prefer-inline')
  bool get isNotFuture => !isFuture;

  /// Returns this as a [Future], or `null` if it's a synchronous value.
  @pragma('vm:prefer-inline')
  Future<T>? asFutureOrNull() => isFuture ? this as Future<T> : null;

  /// Returns a [Future], wrapping the value if it's not already one.
  @pragma('vm:prefer-inline')
  Future<T> toFuture() => Future.value(this);

  /// Returns the synchronous value, or `null` if this is a [Future].
  @pragma('vm:prefer-inline')
  T? asNonFutureOrNull() => isNotFuture ? this as T : null;

  /// Ensures that resolving this value takes at least a specified [duration].
  ///
  /// This is useful for preventing UI elements like loading spinners from
  /// flickering on and off too quickly.
  ///
  /// If [duration] is `null`, this method returns the original value
  /// immediately.
  FutureOr<T> withMinDuration(Duration? duration) {
    if (duration == null) {
      return this;
    }
    return Future.wait([
      Future.value(this),
      Future<void>.delayed(duration),
    ]).then((e) => e.first as T);
  }
}
