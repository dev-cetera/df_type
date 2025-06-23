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

import '../future_or/consec.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A collection of static utility methods for working with [Stream].
///
/// Provides convenient access via the singleton instance `StreamUtils.i`.
@Deprecated('May be removed from package in the future!')
final class StreamUtils {
  // A private constructor to prevent instantiation.
  const StreamUtils._();

  /// The singleton instance for accessing stream helpers.
  static final i = const StreamUtils._();

  /// Returns a [Future] that completes with the first value from the [stream].
  ///
  /// Unlike `stream.first`, this method completes with `null` if the stream
  /// finishes without emitting any values, rather than throwing a [StateError].
  /// If the stream emits an error before the first data event, the returned
  /// [Future] will complete with that error.
  ///
  /// {@tool snippet}
  /// ```dart
  /// final numbers = Stream.fromIterable([10, 20]);
  /// final first = await StreamHelper.i.firstToFuture(numbers);
  /// print(first); // Prints: 10
  ///
  /// final emptyStream = Stream<int>.empty();
  /// final result = await StreamHelper.i.firstToFuture(emptyStream);
  /// print(result); // Prints: null
  /// ```
  /// {@end-tool}
  Future<T?> firstToFuture<T>(Stream<T> stream) {
    // A Completer<T?> is required because the Future can complete with null.
    final completer = Completer<T?>();
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        if (!completer.isCompleted) {
          completer.complete(data);
          subscription?.cancel();
        }
      },
      onError: (Object e, StackTrace s) {
        if (!completer.isCompleted) {
          completer.completeError(e, s);
          subscription?.cancel();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Creates a [Stream] that periodically executes a [callback] function.
  ///
  /// The stream emits the result of the [callback] at each [interval]. The
  /// polling starts as soon as the stream is listened to and pauses/resumes
  /// or cancels automatically with the stream subscription.
  ///
  /// This is useful for polling a resource, such as an API endpoint, to get
  /// periodic updates.
  ///
  /// {@tool snippet}
  /// ```dart
  /// int counter = 0;
  /// Future<String> fetchData() async {
  ///   await Future.delayed(Duration(milliseconds: 50));
  ///   return 'Data packet #${++counter}';
  /// }
  ///
  /// final poller = StreamHelper.i.periodic(fetchData, Duration(seconds: 1));
  ///
  /// final subscription = poller.listen(print);
  ///
  /// // After 3 seconds, it will have printed 'Data packet #1', '#2', '#3'
  /// await Future.delayed(Duration(seconds: 3, milliseconds: 100));
  /// subscription.cancel();
  /// ```
  /// {@end-tool}
  Stream<T> periodic<T extends Object>(
    FutureOr<T> Function() callback,
    Duration interval,
  ) {
    final controller = StreamController<T>();
    Timer? timer;
    void poll() {
      if (controller.isClosed) return;
      try {
        consec(callback(), (value) {
          if (!controller.isClosed) {
            controller.add(value);
          }
        });
      } catch (e, s) {
        if (!controller.isClosed) {
          controller.addError(e, s);
        }
      }
    }

    void startTimer() {
      poll();
      timer = Timer.periodic(interval, (_) => poll());
    }

    void stopTimer() {
      timer?.cancel();
      timer = null;
    }

    controller
      ..onListen = startTimer
      ..onPause = stopTimer
      ..onResume = startTimer
      ..onCancel = stopTimer;
    return controller.stream;
  }
}
