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

import 'wait.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Manages a collection of operations for deferred, batched execution.
///
/// Unlike [Future.wait], which requires a list of already-running [Future]
/// instances, a `Waiter` collects functions (operations) that have not yet
/// been executed.
///
/// This allows you to build up a queue of tasks from different parts of your
/// application and then run them all at once by calling [wait].
///
/// {@tool snippet}
/// ```dart
/// final waiter = Waiter<String>();
///
/// // Define tasks without running them.
/// waiter.add(() => 'Sync task complete');
/// waiter.add(() async {
///   await Future.delayed(Duration(milliseconds: 20));
///   return 'Async task complete';
/// });
///
/// // Execute the entire batch.
/// final results = await waiter.wait();
/// print(results); // (Sync task complete, Async task complete)
/// ```
/// {@end-tool}
class Waiter<T> {
  /// An optional, default error handler for all operations run by this waiter.
  final _TOnErrorCallback? _onError;

  /// The list of pending, un-executed operations.
  final List<_TOperation<T>> _operations;

  /// A read-only view of the pending operations.
  List<_TOperation<T>> get operations => List.unmodifiable(_operations);

  /// Creates a waiter to queue and manage deferred operations.
  Waiter({
    _TOnErrorCallback? onError,
    List<_TOperation<T>> operations = const [],
  }) : _onError = onError,
       _operations = [...operations];

  /// Adds a deferred operation to the queue.
  void add(_TOperation<T> operation) {
    _operations.add(operation);
  }

  /// Adds multiple deferred operations to the queue.
  void addAll(Iterable<_TOperation<T>> operations) {
    _operations.addAll(operations);
  }

  /// Removes a specific operation from the queue.
  void remove(_TOperation<T> operation) {
    _operations.remove(operation);
  }

  /// Removes all pending operations from the queue.
  void clear() {
    _operations.clear();
  }

  /// Executes all queued operations and returns their results.
  ///
  /// This triggers the invocation of all pending functions. It returns a
  /// `FutureOr<Iterable<T>>` that completes with the results.
  ///
  /// - [onError]: A specific error handler for this call, which runs in
  ///   addition to the waiter's default error handler.
  /// - [eagerError]: If `true` (the default), fails as soon as one
  ///   operation fails, similar to `Future.wait`.
  FutureOr<Iterable<T>> wait({
    _TOnErrorCallback? onError,
    bool eagerError = true,
  }) {
    return waitAlikeF(
      _operations,
      onError: (Object e, StackTrace? s) {
        _onError?.call(e, s);
        onError?.call(e, s);
      },
      eagerError: eagerError,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A function that handles an error.
typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

/// A deferred operation: a function that produces a value when called.
typedef _TOperation<T> = FutureOr<T> Function();
