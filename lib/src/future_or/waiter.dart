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

import 'dart:async' show FutureOr, Zone;

import 'wait.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An immutable, value-shaped descriptor of a deferred operation managed by
/// [Waiter].
///
/// **Why a value object?** The historic API of `Waiter.add(() => ...)`
/// stored bare closures directly. Closures cannot be safely sent across
/// `Isolate` boundaries (the Dart runtime rejects them at `SendPort.send`
/// time), and they're opaque to logging/audit code — there's nothing to
/// attach an ID or origin to. Wrapping each operation in a value object
/// fixes both issues:
///
/// 1. **Sendability.** If [run] is a top-level or `static` function, the
///    entire [WaiterOperation] graph is `SendPort.send`-compatible. The
///    type system can't enforce "top-level" — that's a runtime check by the
///    isolate machinery — but the wrapping class gives callers a single
///    place to apply the discipline.
/// 2. **Auditability.** [id] survives the function call; cleanup,
///    cancellation, and structured logging code can refer to operations by
///    name instead of `Function` identity.
///
/// **Equality / hashing** is intentionally identity-based. Two operations
/// with the same id but different [run] callbacks are *not* equal; that
/// matches the existing behaviour of `Waiter.remove(operation)` which
/// relied on `Object.==` of the underlying function.
class WaiterOperation<T> {
  /// The function to invoke when the operation is run.
  ///
  /// For cross-isolate transport, this must be a top-level or `static`
  /// function — closures capture frame state and are not sendable.
  final FutureOr<T> Function() run;

  /// Optional, caller-supplied identifier. Used purely for logging and
  /// auditing; the [Waiter] never inspects it.
  final String? id;

  const WaiterOperation(this.run, {this.id});

  @override
  String toString() {
    return id == null ? 'WaiterOperation<$T>(unnamed)' : 'WaiterOperation<$T>($id)';
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Manages a collection of operations for deferred, batched execution.
///
/// Unlike [Future.wait], which requires a list of already-running [Future]
/// instances, a `Waiter` collects [WaiterOperation] descriptors that have
/// not yet been executed. This lets you build up a queue of tasks from
/// different parts of your application and then run them all at once by
/// calling [wait].
///
/// **Per-isolate model.** A `Waiter` instance is owned by exactly one
/// isolate. The internal queue is a mutable `List`, so two isolates must
/// each construct their own `Waiter` — passing a populated `Waiter` across
/// a `SendPort` is rejected at runtime unless every operation's [run] is a
/// top-level/static function and the receiving isolate is willing to
/// reconstruct the wrapper. Use [operations] to extract a sendable snapshot
/// when you need to hand work off to a worker isolate.
///
/// **Web compatibility.** Everything here is pure Dart with no
/// `dart:isolate` or `dart:io` dependencies, so it works unchanged on
/// Flutter web, dart2js, dartdevc, and the VM.
///
/// {@tool snippet}
/// ```dart
/// final waiter = Waiter<String>();
///
/// // Define tasks without running them.
/// waiter.addFn(() => 'Sync task complete');
/// waiter.addFn(() async {
///   await Future.delayed(Duration(milliseconds: 20));
///   return 'Async task complete';
/// });
///
/// // Execute the entire batch.
/// final results = await waiter.wait();
/// print(results); // (Sync task complete, Async task complete)
/// ```
/// {@end-tool}
class Waiter<T> {
  /// An optional, default error handler for all operations run by this
  /// waiter. Like all handlers in the [wait] flow, this is awaited if it
  /// returns a Future, and a throw inside it never masks the original
  /// incident — handler bugs surface through `Zone.current.handleUncaughtError`.
  final _TOnErrorCallback? _onError;

  /// The list of pending, un-executed operations.
  final List<WaiterOperation<T>> _operations;

  /// A read-only snapshot of the pending operations.
  ///
  /// The returned list is unmodifiable; the underlying queue cannot be
  /// mutated through it. The returned value is also a copy, not a live view,
  /// so capturing it and then calling [add] / [clear] does not retro-mutate
  /// what the caller is iterating.
  List<WaiterOperation<T>> get operations =>
      List<WaiterOperation<T>>.unmodifiable(_operations);

  /// Creates a waiter to queue and manage deferred operations.
  ///
  /// The supplied [operations] iterable is fully materialised and copied
  /// into the internal queue at construction time, so post-construction
  /// mutation of the caller's collection has no effect on the waiter.
  Waiter({
    _TOnErrorCallback? onError,
    Iterable<WaiterOperation<T>> operations = const <Never>[],
  })  : _onError = onError,
        _operations = List<WaiterOperation<T>>.of(operations);

  /// Adds a deferred operation to the queue.
  void add(WaiterOperation<T> operation) {
    _operations.add(operation);
  }

  /// Adds a bare function as a deferred operation. Convenience shortcut for
  /// `add(WaiterOperation(fn, id: id))`; behaves identically except the
  /// caller does not have to construct the wrapper.
  void addFn(FutureOr<T> Function() fn, {String? id}) {
    _operations.add(WaiterOperation<T>(fn, id: id));
  }

  /// Adds multiple deferred operations to the queue.
  void addAll(Iterable<WaiterOperation<T>> operations) {
    _operations.addAll(operations);
  }

  /// Removes a specific operation from the queue.
  ///
  /// Equality is identity-based on the [WaiterOperation] instance — two
  /// wrappers with the same [WaiterOperation.id] but distinct instances are
  /// *not* the same operation. If you need find-by-id semantics, use
  /// [removeWhere] or filter [operations] yourself.
  void remove(WaiterOperation<T> operation) {
    _operations.remove(operation);
  }

  /// Removes operations matching [test].
  void removeWhere(bool Function(WaiterOperation<T> op) test) {
    _operations.removeWhere(test);
  }

  /// Removes all pending operations from the queue.
  void clear() {
    _operations.clear();
  }

  /// Executes all queued operations and returns their results.
  ///
  /// This triggers the invocation of all pending functions. It returns a
  /// `FutureOr<Iterable<T>>` that completes with the results.
  ///
  /// - [onError]: A specific error handler for this call, which runs in
  ///   addition to the waiter's default error handler.
  /// - [eagerError]: If `true` (the default), fails as soon as one
  ///   operation fails, similar to `Future.wait` — but secondary
  ///   rejections are absorbed rather than being leaked to the surrounding
  ///   `Zone` (a deliberate divergence from `Future.wait` for
  ///   audit-trail cleanliness).
  ///
  /// Both the ctor-level handler and the call-level handler are awaited if
  /// they return a Future, and a throw inside one never prevents the other
  /// from running — handler failures are surfaced through
  /// `Zone.current.handleUncaughtError` instead, preserving the original
  /// incident as the caller-facing error.
  FutureOr<Iterable<T>> wait({
    _TOnErrorCallback? onError,
    bool eagerError = true,
  }) {
    final ctorHandler = _onError;
    final callHandler = onError;
    final factories = _operations.map((op) => op.run);
    if (ctorHandler == null && callHandler == null) {
      return waitAlikeF(factories, eagerError: eagerError);
    }
    return waitAlikeF(
      factories,
      onError: (Object e, StackTrace? s) =>
          _runHandlers(ctorHandler, callHandler, e, s),
      eagerError: eagerError,
    );
  }

  /// Run [a] then [b] (if present), each isolated so that a throw or rejected
  /// Future in one cannot prevent the other from running. Handler failures
  /// are reported through the surrounding [Zone] but do not propagate; the
  /// caller-facing error remains the original incident.
  static FutureOr<void> _runHandlers(
    _TOnErrorCallback? a,
    _TOnErrorCallback? b,
    Object e,
    StackTrace? s,
  ) {
    final ra = _runSafely(a, e, s);
    final rb = _runSafely(b, e, s);
    final futures = <Future<void>>[
      if (ra != null) ra,
      if (rb != null) rb,
    ];
    if (futures.isEmpty) return null;
    return Future.wait<void>(futures).then<void>((_) {});
  }

  /// Runs [handler] in isolation. Returns `null` if it completes
  /// synchronously (with or without throwing), or a `Future<void>` that
  /// always succeeds — any thrown exception or rejected Future is forwarded
  /// to the surrounding zone instead of escaping.
  static Future<void>? _runSafely(
    _TOnErrorCallback? handler,
    Object e,
    StackTrace? s,
  ) {
    if (handler == null) return null;
    final Future<void>? maybeFuture;
    try {
      maybeFuture = _invokeAndExtractFuture(handler, e, s);
    } catch (handlerError, handlerStack) {
      Zone.current.handleUncaughtError(handlerError, handlerStack);
      return null;
    }
    if (maybeFuture == null) return null;
    return maybeFuture.then<void>(
      (_) {},
      onError: (Object he, StackTrace? hs) {
        Zone.current.handleUncaughtError(he, hs ?? StackTrace.current);
      },
    );
  }

  /// Invokes [handler] and returns the result as `Future<void>?` — `null`
  /// when the handler completed synchronously, or the Future otherwise.
  /// Wrapping the call here keeps the [_runSafely] body free of `void_checks`
  /// noise. Any thrown exception propagates back to the caller (which
  /// surfaces it through the zone).
  static Future<void>? _invokeAndExtractFuture(
    _TOnErrorCallback handler,
    Object e,
    StackTrace? s,
  ) {
    // ignore: void_checks
    final dynamic ret = handler(e, s);
    if (ret is Future<void>) return ret;
    return null;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A function that handles an error.
typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);
