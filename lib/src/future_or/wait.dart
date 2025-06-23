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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Waits for a list of [FutureOr] values and returns them as an [Iterable].
@pragma('vm:prefer-inline')
FutureOr<Iterable<T>> waitAlike<T>(
  Iterable<FutureOr<T>> items, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
}) {
  return wait<Iterable<T>>(
    items,
    (e) => e.cast<T>(),
    onError: onError,
    eagerError: eagerError,
  );
}

/// Executes deferred operations and returns the results as an [Iterable].
@pragma('vm:prefer-inline')
FutureOr<Iterable<T>> waitAlikeF<T>(
  Iterable<_TFactory<dynamic>> itemFactories, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
}) {
  return waitF<Iterable<T>>(
    itemFactories,
    (e) => e.cast<T>(),
    onError: onError,
    eagerError: eagerError,
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
}) {
  return waitF(
    items.map(
      (e) =>
          () => e,
    ),
    callback,
    onError: onError,
    eagerError: eagerError,
  );
}

/// Executes deferred operations and transforms the results via a callback.
FutureOr<R> waitF<R>(
  Iterable<_TFactory<dynamic>> itemFactories,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
}) {
  final buffer = <FutureOr<dynamic>>[];
  Object? firstSyncError;
  StackTrace? firstSyncStackTrace;
  var isFuture = false;
  for (final itemFactory in itemFactories) {
    try {
      if (eagerError && firstSyncError != null) {
        itemFactory();
        continue;
      }

      final item = itemFactory();
      buffer.add(item);
      if (item is Future) {
        isFuture = true;
      }
    } catch (e, s) {
      if (eagerError) {
        if (onError != null) {
          final errorResult = onError(e, s);
          if (errorResult is Future) {
            return errorResult.then((_) => _throwError(e, s));
          }
        }
        _throwError(e, s);
      }
      if (firstSyncError == null) {
        firstSyncError = e;
        firstSyncStackTrace = s;
        buffer.add(Future.error(e, s));
        isFuture = true;
      }
    }
  }
  if (!isFuture) {
    try {
      final result = callback(buffer);
      if (result is Future<R>) {
        return result.catchError((Object e, StackTrace? s) {
          if (onError != null) {
            return Future.sync(() => onError(e, s)).then((_) => throw e);
          }
          throw e;
        });
      }
      return result;
    } catch (e, s) {
      if (onError != null) {
        final errResult = onError(e, s);
        if (errResult is Future) return errResult.then((_) => throw e);
      }
      rethrow;
    }
  } else {
    return Future.wait(
          buffer.map((e) => Future.value(e)),
          eagerError: eagerError,
        )
        .then((items) {
          if (firstSyncError != null) {
            if (onError != null) {
              final errResult = onError(firstSyncError, firstSyncStackTrace);
              if (errResult is Future) {
                return errResult.then(
                  (_) => _throwError(firstSyncError!, firstSyncStackTrace),
                );
              }
            }
            _throwError(firstSyncError, firstSyncStackTrace);
          }
          return callback(items);
        })
        .catchError((Object e, StackTrace? s) {
          if (onError != null) {
            final errResult = onError(e, s);
            if (errResult is Future) {
              return errResult.then((_) => throw e);
            }
          }
          throw e;
        });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TFactory<T> = FutureOr<T> Function();

typedef _TSyncOrAsyncMapper<A, R> = FutureOr<R> Function(A a);

typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

/// Internal helper to rethrow an error with its stack trace.
@pragma('vm:prefer-inline')
Never _throwError(Object error, [StackTrace? stackTrace]) {
  Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
}
