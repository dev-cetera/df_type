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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class StreamUtility {
  const StreamUtility._();

  static final i = const StreamUtility._();

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

  /// Creates a [Stream] that polls a [callback] at a specified [interval].
  Stream<T> newPoller<T>(Future<T> Function() callback, Duration interval) {
    final controller = StreamController<T>.broadcast();
    Timer? timer;

    Future<void> poll() async {
      try {
        final result = await callback();
        controller.add(result);
      } catch (e) {
        controller.addError(e);
      }
    }

    controller.onListen = () {
      timer = Timer.periodic(interval, (_) => poll());
    };

    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
