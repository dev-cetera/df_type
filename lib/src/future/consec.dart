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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSyncOrAsyncMapper<A, R> = FutureOr<R> Function(A a);

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Maps a synchronous or asynchronous list of values to a single value.
FutureOr<R> consecList<R>(
  List<FutureOr<dynamic>> items,
  FutureOr<R> Function(List<dynamic> resolvedItems) callback, {
  void Function(Object e)? onError,
}) {
  try {
    if (items.whereType<Future<dynamic>>().isNotEmpty) {
      return Future.wait(
        items.map((item) async => item),
      ).then((resolvedItems) {
        return callback(resolvedItems);
      });
    } else {
      return callback(items);
    }
  } catch (e) {
    onError?.call(e);
    rethrow;
  }
}

/// Maps a synchronous or asynchronous value to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec<A, R>(
  FutureOr<A> a,
  FutureOr<R> Function(A a) callback, {
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a],
    (items) => callback(
      items[0] as A,
    ),
  );
}

/// Maps two synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec2<A, B, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<R> Function(A a, B b) callback, {
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b],
    (items) => callback(
      items[0] as A,
      items[1] as B,
    ),
  );
}

/// Maps three synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec3<A, B, C, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<C> c,
  FutureOr<R> Function(A a, B b, C c) callback, {
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d, e],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
      items[4] as E,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d, e, f],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
      items[4] as E,
      items[5] as F,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d, e, f, g],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
      items[4] as E,
      items[5] as F,
      items[6] as G,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d, e, f, g, h],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
      items[4] as E,
      items[5] as F,
      items[6] as G,
      items[7] as H,
    ),
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
  void Function(Object e)? onError,
}) {
  return consecList<R>(
    [a, b, c, d, e, f, g, h, i],
    (items) => callback(
      items[0] as A,
      items[1] as B,
      items[2] as C,
      items[3] as D,
      items[4] as E,
      items[5] as F,
      items[6] as G,
      items[7] as H,
      items[8] as I,
    ),
  );
}
