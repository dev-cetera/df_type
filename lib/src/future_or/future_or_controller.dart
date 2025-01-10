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

import 'sequential.dart';
import 'consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A controller for managing [FutureOr] operations and capturing exceptions.
class FutureOrController<T> {
  FutureOrController._();

  /// Factory constructor to create a [FutureOrController] with optional callbacks.
  factory FutureOrController([_CallbackList<T> callbacks = const []]) {
    final instance = FutureOrController<T>._();
    instance.addAll(callbacks);
    return instance;
  }

  /// List of callbacks to be managed by the controller.
  final _callbacks = <TSyncOrAsyncMapper<dynamic, T>>[];

  /// List of exceptions caught during callback execution or added manually via
  /// [addException].
  final _exceptions = <Object>[];

  /// Adds an exception to the list of tracked exceptions.
  @pragma('vm:prefer-inline')
  void addException(Object e) => _exceptions.add(e);

  /// Returns a copy of the list of tracked exceptions.
  @pragma('vm:prefer-inline')
  List<Object> get exceptions => List.unmodifiable(_exceptions);

  /// Adds a single callback to the controller.
  @pragma('vm:prefer-inline')
  void add(TSyncOrAsyncMapper<dynamic, T> callback) => _callbacks.add(callback);

  /// Adds multiple callbacks to the controller.
  @pragma('vm:prefer-inline')
  void addAll(_CallbackList<T> callbacks) => _callbacks.addAll(callbacks);

  /// Evaluates all registered callbacks.
  @pragma('vm:prefer-inline')
  FutureOr<void> complete() => completeWith<void>((results) {});

  /// Evaluates all registered callbacks and returns the first result.
  @pragma('vm:prefer-inline')
  FutureOr<T> completeWithFirst() => completeWith<T>(
        (r) => r is Future<List<T>> ? r.then((e) => e.first) : r.first,
      );

  /// Evaluates all registered callbacks and returns the last result.
  @pragma('vm:prefer-inline')
  FutureOr<T> completeWithLast() => completeWith<T>(
        (r) => r is Future<List<T>> ? r.then((e) => e.last) : r.last,
      );

  /// Evaluates all registered callbacks and returns all the results.
  @pragma('vm:prefer-inline')
  FutureOr<List<T>> completeWithAll() => completeWith((r) => r);

  /// Evaluates all registered callbacks and returns the results, as
  /// determined by the [consolodator] function.
  ///
  /// If any exceptions occur during the execution of callbacks, they are added
  /// to the [exceptions] list.
  FutureOr<R> completeWith<R>(
    FutureOr<R> Function(FutureOr<List<T>> values) consolodator,
  ) {
    final values = <FutureOr<T>>[];
    final sequential = Sequential();

    // Evaluate all callbacks and collect exceptions.
    for (final callback in _callbacks) {
      try {
        final test = sequential.add(callback);
        values.add(test);
        if (test is Future<T>) {
          test.catchError((Object e) {
            addException(e);
            return Future<T>.error(e);
          });
        }
      } catch (e) {
        addException(e);
      }
    }
    final last = sequential.last;
    if (last is Future) {
      return last.then(
        (_) => consolodator(Future.wait(values.map((e) async => await e))),
      );
    } else {
      return consolodator(values.map((e) => e as T).toList());
    }
  }

  /// Waits for multiple [values] to complete, collects their results, and
  /// returns them in the same order.
  static FutureOr<List<T>> wait<T>(
    Iterable<FutureOr<T>> values, {
    bool eagerError = false,
    void Function(T)? cleanUp,
  }) {
    var hasFuture = false;

    for (final value in values) {
      if (value is Future<T>) {
        hasFuture = true;
        break;
      }
    }
    if (hasFuture) {
      return Future.wait(
        values.map((e) async => e),
        eagerError: eagerError,
        cleanUp: cleanUp,
      );
    } else {
      return values.cast<T>().toList();
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Type definition for a list of callback functions.
typedef _CallbackList<T> = List<TSyncOrAsyncMapper<dynamic, T>>;
