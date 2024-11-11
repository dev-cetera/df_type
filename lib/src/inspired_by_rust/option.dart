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

sealed class Option<T> {
  const Option();

  bool get isSome => this is Some<T>;
  bool get isNone => this is None<T>;

  /// Unwrap the value or throw an error if it's [None].
  T unwrap() {
    return fold(
      (value) => value,
      () => throw Exception('Attempted to unwrap None'),
    );
  }

  /// Fold is used to handle both Some and [None] cases.
  T fold(T Function(T value) onSome, T Function() onNone);

  /// Maps the value inside [Some] if it exists.
  Option<U> map<U>(U Function(T value) fn) {
    if (this is Some<T>) {
      return Some(fn((this as Some<T>).value));
    }
    return None<U>();
  }

  /// Applies the function only if the [Option] is [Some], otherwise returns
  /// [None].
  Option<T> filter(bool Function(T value) predicate) {
    if (this is Some<T>) {
      final value = (this as Some<T>).value;
      if (predicate(value)) {
        return this;
      }
    }
    return None<T>();
  }

  /// Transform the [Option] into a value using a default if [None].
  T getOrElse(T Function() defaultValue) {
    return fold(
      (value) => value,
      defaultValue,
    );
  }

  /// Checks if the [Option] contains a value.
  bool isSomeAnd(bool Function(T value) predicate) {
    if (this is Some<T>) {
      final value = (this as Some<T>).value;
      return predicate(value);
    }
    return false;
  }

  /// Returns [Option] if [Some], or [None] otherwise.
  Option<T> orElse(Option<T> Function() alternative) {
    if (this is Some<T>) {
      return this;
    }
    return alternative();
  }

  /// If it's [Some], apply the function to the value, else return [None].
  Option<U> andThen<U>(Option<U> Function(T value) fn) {
    if (this is Some<T>) {
      return fn((this as Some<T>).value);
    }
    return None<U>();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a value that exists.
final class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);

  @override
  T fold(T Function(T value) onSome, T Function() onNone) => onSome(value);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a value that does not exist.
final class None<T> extends Option<T> {
  const None();

  @override
  T fold(T Function(T value) onSome, T Function() onNone) => onNone();
}
