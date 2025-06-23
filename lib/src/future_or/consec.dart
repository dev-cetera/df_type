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

import 'wait.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Maps a synchronous or asynchronous value to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec<A, R>(
  FutureOr<A> a,
  FutureOr<R> Function(A a) callback, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return wait<R>(
    [a],
    (items) => callback(items.elementAt(0) as A),
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
  );
}

/// Maps two synchronous or asynchronous values to a single value.
@pragma('vm:prefer-inline')
FutureOr<R> consec2<A, B, R>(
  FutureOr<A> a,
  FutureOr<B> b,
  FutureOr<R> Function(A a, B b) callback, {
  _TOnErrorCallback? onError,
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return wait<R>(
    [a, b],
    (items) => callback(items.elementAt(0) as A, items.elementAt(1) as B),
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
}) {
  return wait<R>(
    [a, b, c],
    (items) => callback(
      items.elementAt(0) as A,
      items.elementAt(1) as B,
      items.elementAt(2) as C,
    ),
    onError: onError,
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
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
  bool eagerError = true,
  _TOnCompleteCallback? onComplete,
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
    eagerError: eagerError,
    onComplete: onComplete,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);

typedef _TOnCompleteCallback = FutureOr<void> Function();
