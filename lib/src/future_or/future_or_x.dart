//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async' show FutureOr;

import 'consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension FutureOrX<T extends Object> on FutureOr<T> {
  /// Maps a synchronous or asynchronous value to another.
  FutureOr<R> thenOr<R extends Object?>(
    TSyncOrAsyncMapper<T, R> callback, {
    void Function(Object e)? onError,
  }) {
    return mapSyncOrAsync<T, R>(
      this,
      callback,
      onError: onError,
    );
  }

  /// Casts a value to a synchronous value or throws a [TypeError] if the value
  /// is a [Future].
  T get asSync {
    try {
      return asSyncOrNull!;
    } catch (e) {
      throw TypeError();
    }
  }

  /// Casts a value to a synchronous value or returns `null` if the value is a
  /// [Future].
  T? get asSyncOrNull => this is T ? this as T : null;

  /// Casts a value to a [Future] wrap the value in a [Future] if it is
  /// synchronous.
  Future<T> get asAsync {
    return this is Future<T> ? this as Future<T> : Future<T>.value(this);
  }
}
