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

typedef _TSyncOrAsyncMapper<A, R> = FutureOr<R> Function(A a);
typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Maps a list containing any mix of synchronous or asynchronous values to a
/// single value.
FutureOr<R> consecList<R>(
  Iterable<FutureOr<dynamic>> items,
  _TSyncOrAsyncMapper<Iterable<dynamic>, R> callback, {
  _TOnErrorCallback? onError,
}) {
  for (final item in items) {
    if (item is Future) {
      return Future.wait(items.map((e) async => await e), eagerError: true)
          .then((resolvedItems) => callback(resolvedItems))
          .catchError((Object e, StackTrace? s) {
            if (onError != null) {
              return Future.sync(() => onError(e, s)).then((_) => throw e);
            }
            throw e;
          });
    }
  }
  try {
    final result = callback(items.cast<dynamic>());
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
      final errorResult = onError(e, s);
      if (errorResult is Future) {
        return errorResult.then((_) => throw e);
      }
    }
    rethrow;
  }
}

/// Maps a synchronous or asynchronous value to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec<A, R>(
  FutureOr<A> a,
  FutureOr<R> Function(A a) callback, {
  _TOnErrorCallback? onError,
}) {
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
  return consecList<R>(
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
