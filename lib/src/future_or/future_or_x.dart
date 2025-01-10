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

import 'dart:async' show FutureOr;

import 'package:df_safer_dart/df_safer_dart.dart';

import 'consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension FutureOrX<T extends Object> on FutureOr<T> {
  /// Maps a synchronous or asynchronous value to another.
  @pragma('vm:prefer-inline')
  FutureOr<R> thenOr<R extends Object?>(
    TSyncOrAsyncMapper<T, R> callback, {
    void Function(Object e)? onError,
  }) {
    return consec<T, R>(
      this,
      callback,
      onError: onError,
    );
  }

  /// Casts a value to a synchronous value.
  @pragma('vm:prefer-inline')
  Result<T> get asSync => this is T ? Ok(this as T) : const Err('Value is not synchronous.');

  /// Casts a value to a [Future] wrap the value in a [Future] if it is
  /// synchronous.
  @pragma('vm:prefer-inline')
  Future<T> get asAsync => this is Future<T> ? this as Future<T> : Future<T>.value(this);
}
