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

@Deprecated('May be removed from package in the future!')
final class StreamHelper {
  //
  //
  //

  const StreamHelper._();

  //
  //
  //

  static final i = const StreamHelper._();

  //
  //
  //

  /// Waits for the first value from the [Stream] and returns it as a [Future].
  Future<T> firstToFuture<T>(Stream<T> stream) {
    final completer = Completer<T>();
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        if (!completer.isCompleted) {
          completer.complete(data);
          subscription?.cancel();
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
          subscription?.cancel();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(
              '[firstToFuture] Stream completed without emitting any values',
            ),
          );
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  //
  //
  //

  /// Creates a [Stream] that polls a [callback] at a specified [interval].
  Stream<T> newPoller<T extends Object>(
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
