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

/// Maps a synchronous or asynchronous value to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec<A, R>(
  FutureOr<A> a,
  FutureOr<R> Function(A a) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a],
    (items) => callback(items.elementAt(0) as A),
    onError: onError,
  );
}

/// Maps two synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec2<A, B, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<R> Function(A a, B b) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b],
    (items) => callback(items.elementAt(0) as A, items.elementAt(1) as B),
    onError: onError,
  );
}

/// Maps three synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec3<A, B, C, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<R> Function(A a, B b, C c) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
    ),
    onError: onError,
  );
}

/// Maps four synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec4<A, B, C, D, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<R> Function(A a, B b, C c, D d) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
    ),
    onError: onError,
  );
}

/// Maps five synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec5<A, B, C, D, E, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<E> e,
  FutureOr<R> Function(A a, B b, C c, D d, E e) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d, e],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
      items.elementAt(4) as E,
    ),
    onError: onError,
  );
}

/// Maps six synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec6<A, B, C, D, E, F, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<E> e,
  FutureOr<F> f,
  FutureOr<R> Function(A a, B b, C c, D d, E e, F f) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d, e, f],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
      items.elementAt(4) as E,
      items.elementAt(5) as F,
    ),
    onError: onError,
  );
}

/// Maps seven synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec7<A, B, C, D, E, F, G, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<E> e,
  FutureOr<F> f,
  FutureOr<G> g,
  FutureOr<R> Function(A a, B b, C c, D d, E e, F f, G g) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d, e, f, g],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
      items.elementAt(4) as E,
      items.elementAt(5) as F,
      items.elementAt(6) as G,
    ),
    onError: onError,
  );
}

/// Maps eight synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec8<A, B, C, D, E, F, G, H, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<E> e,
  FutureOr<F> f,
  FutureOr<G> g,
  FutureOr<H> h,
  FutureOr<R> Function(A a, B b, C c, D d, E e, F f, G g, H h) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d, e, f, g, h],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
      items.elementAt(4) as E,
      items.elementAt(5) as F,
      items.elementAt(6) as G,
      items.elementAt(7) as H,
    ),
    onError: onError,
  );
}

/// Maps nine synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec9<A, B, C, D, E, F, G, H, I, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<D> d,
  FutureOr<E> e,
  FutureOr<F> f,
  FutureOr<G> g,
  FutureOr<H> h,
  FutureOr<I> i,
  FutureOr<R> Function(A a, B b, C c, D d, E e, F f, G g, H h, I i) callback, {
  _TOnErrorCallback? onError,
}) {
  return wait<R>(
    [a, b, c, d, e, f, g, h, i],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
      items.elementAt(3) as D,
      items.elementAt(4) as E,
      items.elementAt(5) as F,
      items.elementAt(6) as G,
      items.elementAt(7) as H,
      items.elementAt(8) as I,
    ),
    onError: onError,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TFactory<T> = FutureOr<T> Function();
typedef _TSyncOrAsyncMapper<A, R> = FutureOr<R> Function(A a);
typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

Never _throwError(Object error, [StackTrace? stackTrace]) =>
    Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
