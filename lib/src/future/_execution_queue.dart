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

import 'finisher.dart';
import 'consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A queue for sequentially executing functions one at a time.
///
/// This class ensures that functions are executed in the order they are added,
/// with only one function running at a time. When a function is added using
/// the [add] method, it is placed at the end of the queue. The queue processes
/// each function sequentially, starting the next function only after the
/// current one has completed. The queue continues processing until it is empty.
///
/// The [add] method immediately schedules the function for execution, but it
/// does not execute it until all previously added functions have finished. This
/// allows for accurate control over the order and timing of function execution.
///
/// You can introduce a delay before a function executes by specifying a
/// `buffer` duration. This is useful for scenarios where you need to throttle
/// execution.
@Deprecated('"ExecutionQueue" has been replaced with "Sequential".')
class ExecutionQueue {
  //
  //
  //

  final _queue = <_Executable<dynamic>>[];

  /// Checks if the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Checks if the queue is not empty.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Adds a new [function] to the queue. The [function] will be executed
  /// immediately after all previously added functions have completed.
  ///
  /// If the [buffer] parameter is provided, the function is executed alongside
  /// a buffer duration. This ensures that the total execution time of the
  /// function is at least as long as the [buffer] duration, which can be useful
  /// for throttling operations and ensuring a minimum duration for each task.
  ///
  /// The method returns a [FutureOr] that completes when both the function and
  /// all preceding functions in the queue have completed. This means, when
  /// awaiting, the returned [FutureOr] will resolve only after all prev
  /// functions, including any added with a buffer, have finished executing.
  FutureOr<T> add<T>(
    TSyncOrAsyncMapper<dynamic, T> function, {
    Duration? buffer,
  }) {
    final executable = _Executable<T>(
      buffer == null
          ? function
          : (prev) async => (await Future.wait<T>([
              Future.value(function(prev)),
              Future.delayed(buffer),
            ])).first,
    );
    _queue.add(executable);
    final result = consec(_execute(), (_) => executable.completer.futureOr);
    return result;
  }

  /// Adds multiple [functions] to the queue for sequential execution. See
  /// [add].
  List<FutureOr<dynamic>> addAll(
    Iterable<TSyncOrAsyncMapper<dynamic, dynamic>> functions, {
    Duration? buffer,
  }) {
    final results = <FutureOr<dynamic>>[];
    for (final function in functions) {
      results.add(add(function, buffer: buffer));
    }
    return results;
  }

  /// Waits for all functions in the queue to complete, and return the
  /// result of the last function in the queue.
  FutureOr<dynamic> last() {
    return add<dynamic>((e) => e);
  }

  /// Processes the next executable in the queue that isn't already RUNNING,
  /// until the queue is empty.
  FutureOr<void> _execute() {
    // Garbage-collect functions from the queue that have already been executed.
    _queue.removeWhere((e) => e.status == _ExecutionStatus.RAN);

    for (final executable in _queue) {
      final status = executable.status;

      // Stop processing if a function is currently running.
      if (status == _ExecutionStatus.RUNNING) return null;

      // Start executing the function if it is ready.
      if (status == _ExecutionStatus.READY) {
        executable.status = _ExecutionStatus.RUNNING;
        final result = executable.function(_previous);

        // Complete the function's execution based on its result type.
        return consec(result, (dynamic value) {
          _previous = value;
          executable.completer.complete(result);
          executable.status = _ExecutionStatus.RAN;
          return _execute();
        });
      }
    }
  }

  /// Always stores the result of the prev function in the queue.
  dynamic _previous;

  /// Resets the prev result to `null`.
  void reset() {
    _previous = null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents a function that has been added to the queue for execution.
///
/// Each _Executable object holds the function to be executed, a completer
/// that will be used to return the result, and its execution status.
class _Executable<T> {
  final completer = Finisher<T>();
  var status = _ExecutionStatus.READY;
  final TSyncOrAsyncMapper<dynamic, T> function;
  _Executable(this.function);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Represents the execution status of a function within the queue.
///
/// - [READY]: The function is in the queue and ready to be executed.
/// - [RUNNING]: The function is currently being executed.
/// - [RAN]: The function has been executed and completed, and is ready for garbage collection.
enum _ExecutionStatus { READY, RUNNING, RAN }
