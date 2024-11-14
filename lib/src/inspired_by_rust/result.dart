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

import 'option.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// Get the [Ok] value or throw an error if it's [Err].
  Ok<T, E> get ok {
    try {
      return this as Ok<T, E>;
    } catch (e) {
      throw Exception('Attempted to get Ok from Err: $e');
    }
  }

  /// Get the [Err] value or throw an error if it's [Ok].
  Err<T, E> get err {
    try {
      return this as Err<T, E>;
    } catch (e) {
      throw Exception('Attempted to get Err from Ok: $e');
    }
  }

  /// Unwrap the value or throw an error if it's [Err].
  T unwrap() {
    return ok.value;
  }

  /// Fold is used to handle both [Ok] and [Err] cases.
  B fold<B>(B Function(T value) onOk, B Function(E error) onErr);

  /// Convert to [Option], where [Ok] becomes [Some] and [Err] becomes [None].
  Option<T> toOption() => isOk ? Some((this as Ok<T, E>).value) : const None();

  /// Maps the value inside [Ok] if it exists, keeping [Err] unchanged.
  Result<U, E> map<U>(U Function(T value) fn) {
    if (this is Ok<T, E>) {
      return Ok(fn((this as Ok<T, E>).value));
    }
    return this as Result<U, E>;
  }

  /// Maps the value inside [Ok] asynchronously, keeping [Err] unchanged.
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T value) fn) async {
    if (this is Ok<T, E>) {
      try {
        final result = await fn((this as Ok<T, E>).value);
        return Ok(result);
      } catch (e) {
        return Err(e as E); // Cast carefully or handle the type properly.
      }
    }
    return this as Result<U, E>;
  }

  /// Maps the error inside [Err] if it exists, keeping [Ok] unchanged.
  Result<T, F> mapErr<F>(F Function(E error) fn) {
    if (this is Err<T, E>) {
      return Err(fn((this as Err<T, E>).error));
    }
    return this as Result<T, F>;
  }

  /// Applies a function to the value inside [Ok] if it exists, otherwise
  /// returns [Err].
  Result<U, E> andThen<U>(Result<U, E> Function(T value) fn) {
    if (this is Ok<T, E>) {
      return fn((this as Ok<T, E>).value);
    }
    return this as Result<U, E>;
  }

  /// If this [Result] is [Err], provides a default value (or another [Result]).
  Result<T, E> orElse(Result<T, E> Function() alternative) {
    if (this is Ok<T, E>) {
      return this;
    }
    return alternative();
  }

  /// If the [Result] is [Ok], provides a default value; otherwise, executes
  /// the error function.
  T getOrElse(T Function() defaultValue) {
    return fold(
      (value) => value,
      (error) => defaultValue(),
    );
  }

  /// If it's [Ok], apply the function to the value; otherwise, return the
  /// original [Result].
  Result<U, E> mapOrElse<U>(
    U Function(T value) onOk,
    U Function(E error) onErr,
  ) {
    if (this is Ok<T, E>) {
      return Ok(onOk((this as Ok<T, E>).value));
    }
    return Err((this as Err<T, E>).error);
  }

  /// Check if [Result] is [Ok] and the value satisfies a predicate.
  bool isOkAnd(bool Function(T value) predicate) {
    if (this is Ok<T, E>) {
      final value = (this as Ok<T, E>).value;
      return predicate(value);
    }
    return false;
  }

  /// Check if [Result] is [Err] and the error satisfies a predicate.
  bool isErrAnd(bool Function(E error) predicate) {
    if (this is Err<T, E>) {
      final error = (this as Err<T, E>).error;
      return predicate(error);
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    return this.fold(
      (value) => other is Ok && value == other.value,
      (error) => other is Err && error == other.error,
    );
  }

  @override
  int get hashCode => fold(
        (value) => value.hashCode,
        (error) => error.hashCode,
      );

  /// Constructs a new [Result] from a function that might throw.
  static Result<T, E> tryCatch<T, E, F extends Object>(
    T Function() fn,
    E Function(F e) onError,
  ) {
    try {
      return Ok(fn());
    } on F catch (e) {
      return Err(onError(e));
    }
  }

  /// Constructs a new [Result] from a function that might throw.
  static Future<Result<T, E>> tryCatchAsync<T, E>(
    Future<T> Function() fn,
    E Function(Object error) onError,
  ) async {
    try {
      return Ok(await fn());
    } catch (e) {
      return Err(onError(e));
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a successful value.
final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);

  @override
  B fold<B>(B Function(T value) onOk, B Function(E error) onErr) => onOk(value);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a failed value.
final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);

  @override
  B fold<B>(B Function(T value) onOk, B Function(E error) onErr) =>
      onErr(error);
}
