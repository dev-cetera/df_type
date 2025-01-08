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

sealed class Option<T> {
  const Option();

  @pragma('vm:prefer-inline')
  bool get isSome => this is Some<T>;

  @pragma('vm:prefer-inline')
  bool get isNone => this is None<T>;

  /// Get the [Some] value or throw an error if it's [None].
  @pragma('vm:prefer-inline')
  Some<T> get some {
    try {
      return this as Some<T>;
    } catch (e) {
      throw Exception('Attempted to get Some from None: $e');
    }
  }

  /// Get the [None] value or throw an error if it's [Some].
  @pragma('vm:prefer-inline')
  None<T> get none {
    try {
      return this as None<T>;
    } catch (e) {
      throw Exception('Attempted to get None from Some: $e');
    }
  }

  /// Unwrap the value or throw an error if it's [None].
  @pragma('vm:prefer-inline')
  T unwrap() => some.value;

  /// Fold is used to handle both Some and [None] cases.
  @pragma('vm:prefer-inline')
  B fold<B>(B Function(T value) onSome, B Function() onNone);

  /// Maps the value inside [Some] if it exists.
  @pragma('vm:prefer-inline')
  Option<U> map<U>(U Function(T value) fn) {
    if (this is Some<T>) {
      return Some(fn((this as Some<T>).value));
    }
    return None<U>();
  }

  /// Applies the function only if the [Option] is [Some], otherwise returns
  /// [None].
  @pragma('vm:prefer-inline')
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
  @pragma('vm:prefer-inline')
  T getOrElse(T Function() defaultValue) {
    return fold(
      (value) => value,
      defaultValue,
    );
  }

  /// Checks if the [Option] contains a value.
  @pragma('vm:prefer-inline')
  bool isSomeAnd(bool Function(T value) predicate) {
    if (this is Some<T>) {
      final value = (this as Some<T>).value;
      return predicate(value);
    }
    return false;
  }

  /// Returns [Option] if [Some], or [None] otherwise.
  @pragma('vm:prefer-inline')
  Option<T> orElse(Option<T> Function() alternative) {
    if (this is Some<T>) {
      return this;
    }
    return alternative();
  }

  /// If it's [Some], apply the function to the value, else return [None].
  @pragma('vm:prefer-inline')
  Option<U> andThen<U>(Option<U> Function(T value) fn) {
    if (this is Some<T>) {
      return fn((this as Some<T>).value);
    }
    return None<U>();
  }

  @override
  @pragma('vm:prefer-inline')
  bool operator ==(Object other) {
    return this.fold(
      (value) => other is Some && value == other.value,
      () => other is None && none == other.none,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  int get hashCode => fold(
        (value) => value.hashCode,
        () => null.hashCode,
      );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a value that exists.
final class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);

  @override
  @pragma('vm:prefer-inline')
  B fold<B>(B Function(T value) onSome, B Function() onNone) => onSome(value);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a value that does not exist.
final class None<T> extends Option<T> {
  const None();

  @override
  @pragma('vm:prefer-inline')
  B fold<B>(B Function(T value) onSome, B Function() onNone) => onNone();
}
