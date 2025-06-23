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

// ignore_for_file: require_trailing_commas

import 'dart:async' show FutureOr;

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
  final syncBuffer = <dynamic>[];
  final asyncBuffer = <Future<dynamic>>[];
  _Error? syncError1;
  for (final itemFactory in itemFactories) {
    try {
      final item = itemFactory();
      if (item is Future) {
        asyncBuffer.add(item);
      } else {
        syncBuffer.add(item);
      }
    } catch (e, s) {
      if (eagerError) {
        return _handleErrorAndComplete(_Error(e, s), onError, onComplete);
      }
      if (syncError1 == null) {
        syncError1 = _Error(e, s);
        asyncBuffer.add(Future.error(e, s));
      }
    }
  }
  if (asyncBuffer.isEmpty) {
    return _handleSyncPath(
      syncError1,
      syncBuffer,
      callback,
      onError,
      onComplete,
    );
  }
  return _handleAsyncPath(
    syncError1,
    syncBuffer,
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
  List<dynamic> syncBuffer,
  List<Future<dynamic>> asyncBuffer,
  bool eagerError,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback,
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
) {
  final buffer = [...syncBuffer.map((e) => Future.value(e)), ...asyncBuffer];
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
  return Future.wait(buffer, eagerError: true)
      .then((values) => Future.value(callback(values)))
      .catchError(
        (Object e, StackTrace? s) => _handleError<R>(_Error(e, s), onError),
      )
      .whenComplete(onComplete ?? () {});
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

FutureOr<R> _handleError<R>(_Error error, _TOnErrorCallback? onError) {
  FutureOr<void>? errorResult;
  try {
    errorResult = onError?.call(error.e, error.s);
  } catch (e, s) {
    _throwError(e, s);
  }
  if (errorResult is Future<void>) {
    return Future.value(errorResult).then((_) => _throwError(error.e, error.s));
  }
  _throwError(error.e, error.s);
}

FutureOr<R> _handleErrorAndComplete<R>(
  _Error error,
  _TOnErrorCallback? onError,
  _TOnCompleteCallback? onComplete,
) {
  FutureOr<void>? errorResult;
  FutureOr<void>? onCompleteResult;
  try {
    errorResult = onError?.call(error.e, error.s);
    onCompleteResult = onComplete?.call();
  } catch (e, s) {
    _throwError(e, s);
  }
  if (errorResult is Future<void> || onCompleteResult is Future<void>) {
    return Future.wait([
      Future.value(errorResult),
      Future.value(onCompleteResult),
    ]).then((_) => _throwError(error.e, error.s));
  }
  _throwError(error.e, error.s);
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
