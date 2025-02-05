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

/// A utility for producing and completing [FutureOr] objects.
///
/// Similar to [CompleterOr], this class allows you to handle both synchronous
/// and asynchronous results. It provides methods to complete the object with
/// a value, and to retrieve the result.
class CompleterOr<T> {
  //
  //
  //

  final _completer = Completer<T>();

  FutureOr<T>? _value;

  //
  //
  //

  /// Completes the operation with the provided [value]. If [value] is a
  /// [Future], the [CompleterOr] will wait for it to complete. If [value] is
  /// synchronous, it will be stored directly.
  ///
  /// This method can only be called once. Subsequent calls have no effect if
  /// the [CompleterOr] has already been completed.
  void complete(FutureOr<T> value) {
    if (isCompleted) return;
    if (value is Future<T>) {
      _completer.complete(value);
    } else {
      _value = value;
      _completer.complete(value);
    }
  }

  /// Returns the stored synchronous value if available, otherwise returns
  /// the [Future] that resolves to the value.
  ///
  /// If the [CompleterOr] has been completed with a synchronous value, that
  /// value is returned directly. Otherwise, the [Future] is returned.
  FutureOr<T> get futureOr {
    return _value ?? _completer.future;
  }

  /// Checks if the value has been set or if the [CompleterOr] is completed.
  ///
  /// This is `true` if either the synchronous value is set or the [CompleterOr]
  /// has been completed through [complete].  When `true`, [complete] should
  /// not be called again.
  bool get isCompleted => _completer.isCompleted || _value != null;
}
