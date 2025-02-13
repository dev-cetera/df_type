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

import 'consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A queue that manages the execution of functions sequentially, allowing for
/// optional throttling.
class Sequential {
  //
  //
  //

  final Duration? _buffer;

  /// The current value or future in the queue.
  FutureOr<dynamic>? _current;

  /// Indicates whether the queue is empty or processing.
  bool get isEmpty => _isEmpty;
  bool _isEmpty = true;

  //
  //
  //

  /// Creates an [Sequential] with an optional [buffer] for throttling
  /// execution.
  Sequential({Duration? buffer}) : _buffer = buffer;

  /// Adds a [function] to the queue that processes the previous value.
  /// Applies an optional [buffer] duration to throttle the execution.
  FutureOr<T> add<T>(
    FutureOr<T> Function(dynamic previous) function, {
    Duration? buffer,
  }) {
    final buffer1 = buffer ?? _buffer;
    if (buffer1 == null) {
      return _enqueue<T>(function);
    } else {
      return _enqueue<T>((previous) {
        return Future.wait<dynamic>([
          Future.value(function(previous)),
          Future<void>.delayed(buffer1),
        ]).then((e) => e.first as T);
      });
    }
  }

  /// Adds multiple [functions] to the queue for sequential execution. See
  /// [add].
  List<FutureOr<T>> addAll<T>(
    Iterable<FutureOr<T> Function(dynamic previous)> functions, {
    Duration? buffer,
  }) {
    final results = <FutureOr<T>>[];
    for (final function in functions) {
      results.add(add(function, buffer: buffer));
    }
    return results;
  }

  /// Eenqueue a [function] without buffering.
  FutureOr<T> _enqueue<T>(FutureOr<T> Function(dynamic previous) function) {
    _isEmpty = false;
    final temp = consec(
      consec(_current, (previous) {
        return function(previous);
      }),
      (result) {
        _isEmpty = true;
        return result;
      },
    );
    _current = temp;
    return temp;
  }

  /// Retrieves the last value in the queue without altering the queue.
  FutureOr<void> get last => add<void>((e) => e);

  /// Indicates whether the last value in the queue is a [Future]. Use
  /// [isEmpty] instead to check if the queue is empty.
  bool get hasLast => last is Future<void>;
}
