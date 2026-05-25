//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: require_trailing_commas

import 'dart:async' show Completer, FutureOr, Zone;

import 'package:collection/collection.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Waits for a list of [FutureOr] values and returns them as an [Iterable].
@pragma('vm:prefer-inline')
FutureOr<Iterable<T>> waitAlike<T>(
  Iterable<FutureOr<T>> items, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return wait<Iterable<T>>(
    items,
    (e) => e.cast<T>(),
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
  );
}

/// Executes deferred operations and returns the results as an [Iterable].
@pragma('vm:prefer-inline')
FutureOr<Iterable<T>> waitAlikeF<T>(
  Iterable<_TFactory<dynamic>> itemFactories, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return waitF<Iterable<T>>(
    itemFactories,
    (e) => e.cast<T>(),
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
  );
}

@Deprecated('Renamed to "wait"')
final consecList = wait;

/// Waits for a list of [FutureOr] values and transforms the results.
@pragma('vm:prefer-inline')
FutureOr<R> wait<R>(
  Iterable<FutureOr<dynamic>> items,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return waitF(
    items.map(
      (e) => () => e,
    ),
    callback,
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
  );
}

/// Waits for a list of [FutureOr] values and transforms the results.
FutureOr<R> waitF<R>(
  Iterable<_TFactory<dynamic>> itemFactories,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  // Single in-order buffer: holds either raw sync values or pending Futures.
  // This guarantees the callback observes results in the same order the
  // caller passed them in — `consec2(asyncA, syncB, ...)` must see `[A, B]`,
  // not `[B, A]`. The previous implementation split sync/async into two
  // buffers and concatenated them, silently reordering arguments.
  final buffer = <dynamic>[];
  var hasAsync = false;
  _Error? syncError1;
  for (final itemFactory in itemFactories) {
    try {
      final item = itemFactory();
      buffer.add(item);
      if (item is Future) hasAsync = true;
    } catch (e, s) {
      if (eagerError) {
        return _handleErrorAndComplete(_Error(e, s), onError, onComplete);
      }
      // Record only the first sync error for reporting, but always push a
      // placeholder Future.error into the buffer so its length stays aligned
      // with the input. Otherwise `consecN`'s positional access drifts when
      // multiple sync factories throw under `eagerError: false`.
      syncError1 ??= _Error(e, s);
      buffer.add(Future<dynamic>.error(e, s));
      hasAsync = true;
    }
  }
  if (!hasAsync) {
    return _handleSyncPath(
      syncError1,
      buffer,
      callback,
      onError,
      onComplete,
    );
  }
  final asyncBuffer = buffer
      .map<Future<dynamic>>((e) => e is Future ? e : Future<dynamic>.value(e))
      .toList(growable: false);
  return _handleAsyncPath(
    syncError1,
    asyncBuffer,
    eagerError,
    callback,
    onError,
    onComplete,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

FutureOr<R> _handleSyncPath<R>(
  _Error? syncError1,
  List<dynamic> syncBuffer,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback,
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
) {
  try {
    if (syncError1 != null) {
      return _handleErrorAndComplete(syncError1, onError, onComplete);
    }
    final result = callback(syncBuffer);
    if (result is Future<R>) return result.whenComplete(onComplete ?? () {});
    onComplete?.call();
    return result;
  } catch (e, s) {
    return _handleErrorAndComplete(_Error(e, s), onError, onComplete);
  }
}

FutureOr<R> _handleAsyncPath<R>(
  _Error? syncError1,
  List<Future<dynamic>> buffer,
  bool eagerError,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback,
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
) {
  if (eagerError) {
    return _futureWaitEagerError(
      buffer,
      callback,
      onError: onError,
      onComplete: onComplete,
    );
  } else {
    return _futureWait(
      syncError1,
      buffer,
      callback,
      onError: onError,
      onComplete: onComplete,
    );
  }
}

Future<R> _futureWaitEagerError<R>(
  Iterable<Future<dynamic>> buffer,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
}) {
  return _eagerCollectFutures(buffer)
      .then((values) => Future.value(callback(values)))
      .catchError(
        (Object e, StackTrace? s) => _handleError<R>(_Error(e, s), onError),
      )
      .whenComplete(onComplete ?? () {});
}

/// Eager-error variant of [Future.wait] that **absorbs secondary rejections**.
///
/// Standard `Future.wait(eagerError: true)` reports the first error to the
/// caller but lets every subsequent error bubble through
/// `Zone.current.handleUncaughtError` — polluting the audit log with
/// follow-up failures that the caller never asked about. For life-critical
/// code the caller wants a single attributable failure, so we hand-roll the
/// collector and silently drop rejections that arrive after we've already
/// completed in error.
Future<List<dynamic>> _eagerCollectFutures(Iterable<Future<dynamic>> futures) {
  final list = futures is List<Future<dynamic>>
      ? futures
      : futures.toList(growable: false);
  if (list.isEmpty) return Future<List<dynamic>>.value(<dynamic>[]);
  final completer = Completer<List<dynamic>>();
  final results = List<dynamic>.filled(list.length, null, growable: false);
  var remaining = list.length;
  for (var i = 0; i < list.length; i++) {
    final idx = i;
    list[i].then<void>(
      (Object? v) {
        if (completer.isCompleted) return;
        results[idx] = v;
        remaining--;
        if (remaining == 0) completer.complete(results);
      },
      onError: (Object e, StackTrace? s) {
        if (completer.isCompleted) return;
        completer.completeError(e, s ?? StackTrace.current);
      },
    ).ignore();
  }
  return completer.future;
}

Future<R> _futureWait<R>(
  _Error? syncError1,
  Iterable<Future<dynamic>> buffer,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
}) {
  final bufferAndErrors = buffer.map(
    (e) => e.catchError((Object e, StackTrace? s) => _Error(e, s)),
  );
  return Future.wait(bufferAndErrors)
      .then(
        (valuesAndErrors) => _processItems(syncError1, valuesAndErrors, callback, onError),
      )
      .whenComplete(onComplete ?? () {});
}

Future<R> _processItems<R>(
  _Error? syncError1,
  List<dynamic> valusAndErrors,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback,
  _TOnErrorCallback? onError,
) {
  if (syncError1 != null) {
    return _handleError(syncError1, onError);
  }
  final asyncError1 = valusAndErrors.whereType<_Error>().firstOrNull;
  if (asyncError1 != null) {
    return _handleError(asyncError1, onError);
  }
  return Future.value(callback(valusAndErrors.where((e) => e is! _Error)));
}

/// Invokes the error handler with the original error and rethrows the
/// **original** error after it settles.
///
/// Medical-grade invariant: a bug inside the handler must never substitute
/// itself for the underlying incident. If the handler throws synchronously
/// or rejects asynchronously, that failure is surfaced through
/// `Zone.current.handleUncaughtError` (so it is still observable) but the
/// original error is what propagates to the caller.
FutureOr<R> _handleError<R>(_Error error, _TOnErrorCallback? onError) {
  if (onError == null) {
    _throwError(error.e, error.s);
  }
  FutureOr<void>? errorResult;
  try {
    errorResult = onError(error.e, error.s);
  } catch (handlerError, handlerStack) {
    Zone.current.handleUncaughtError(handlerError, handlerStack);
  }
  if (errorResult is Future<void>) {
    return errorResult.then<void>(
      (_) {},
      onError: (Object e, StackTrace? s) {
        Zone.current.handleUncaughtError(e, s ?? StackTrace.current);
      },
    ).then((_) => _throwError(error.e, error.s));
  }
  _throwError(error.e, error.s);
}

/// As [_handleError], but also runs [onComplete] on every exit path —
/// including when [onError] itself throws.
///
/// Medical-grade invariant: `onComplete` is the cleanup hook (closing
/// streams, releasing locks, flushing audit logs) and **must** run, even if
/// the error handler is broken.
FutureOr<R> _handleErrorAndComplete<R>(
  _Error error,
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
) {
  FutureOr<void>? errorResult;
  if (onError != null) {
    try {
      errorResult = onError(error.e, error.s);
    } catch (handlerError, handlerStack) {
      Zone.current.handleUncaughtError(handlerError, handlerStack);
    }
  }
  FutureOr<void>? onCompleteResult;
  if (onComplete != null) {
    try {
      onCompleteResult = onComplete();
    } catch (completeError, completeStack) {
      Zone.current.handleUncaughtError(completeError, completeStack);
    }
  }
  final hasAsync =
      errorResult is Future<void> || onCompleteResult is Future<void>;
  if (!hasAsync) {
    _throwError(error.e, error.s);
  }
  return Future.wait<void>([
    if (errorResult is Future<void>)
      errorResult.then<void>(
        (_) {},
        onError: (Object e, StackTrace? s) {
          Zone.current.handleUncaughtError(e, s ?? StackTrace.current);
        },
      ),
    if (onCompleteResult is Future<void>)
      onCompleteResult.then<void>(
        (_) {},
        onError: (Object e, StackTrace? s) {
          Zone.current.handleUncaughtError(e, s ?? StackTrace.current);
        },
      ),
  ]).then((_) => _throwError(error.e, error.s));
}

Never _throwError(Object error, [StackTrace? stackTrace]) {
  Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
}

class _Error {
  final Object e;
  final StackTrace? s;
  _Error(this.e, this.s);
}

typedef _TFactory<T> = FutureOr<T> Function();

typedef _TSyncOrAsyncMapper<A, R> = FutureOr<R> Function(A a);

typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

typedef _TOnCompleteCallback = FutureOr<void> Function();
