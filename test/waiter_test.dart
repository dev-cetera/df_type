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

import 'dart:async';

import 'package:df_type/df_type.dart';
import 'package:test/test.dart';

/// Tests for the [Waiter] class — a deferred batch of operations that runs
/// when its [Waiter.wait] is called. Distinct from `Future.wait`, which
/// expects already-running futures.
void main() {
  group('Waiter — queue management', () {
    test('starts empty', () {
      final w = Waiter<int>();
      expect(w.operations, isEmpty);
    });

    test('add appends to the queue', () {
      final w = Waiter<int>();
      w.add(() => 1);
      w.add(() => 2);
      expect(w.operations, hasLength(2));
    });

    test('addAll appends every supplied operation', () {
      final w = Waiter<int>()..addAll([() => 1, () => 2, () => 3]);
      expect(w.operations, hasLength(3));
    });

    test('remove drops a matching operation', () {
      FutureOr<int> a() => 1;
      FutureOr<int> b() => 2;
      final w = Waiter<int>()..addAll([a, b]);
      w.remove(a);
      expect(w.operations, hasLength(1));
      expect(w.operations.single, same(b));
    });

    test('clear empties the queue', () {
      final w = Waiter<int>()..addAll([() => 1, () => 2]);
      w.clear();
      expect(w.operations, isEmpty);
    });

    test('operations getter is unmodifiable', () {
      final w = Waiter<int>()..add(() => 1);
      expect(() => w.operations.add(() => 2), throwsUnsupportedError);
    });

    test('operations supplied to the ctor are copied, not aliased', () {
      // If the ctor stored the caller's list directly, later mutation of the
      // original list would leak in. Confirm defensive copy.
      final source = <FutureOr<int> Function()>[() => 1, () => 2];
      final w = Waiter<int>(operations: source);
      source.add(() => 99);
      expect(w.operations, hasLength(2));
    });
  });

  group('Waiter — execution', () {
    test('returns nothing for an empty queue', () async {
      final w = Waiter<String>();
      final out = await w.wait();
      expect(out, isEmpty);
    });

    test('operations are not invoked until wait() is called', () async {
      var ran = 0;
      final w = Waiter<int>()
        ..add(() {
          ran++;
          return 1;
        });
      expect(ran, 0);
      await w.wait();
      expect(ran, 1);
    });

    test('preserves the order operations were registered', () async {
      final w = Waiter<String>()
        ..add(() => 'a')
        ..add(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return 'b';
        })
        ..add(() => 'c');
      final out = await w.wait();
      expect(out.toList(), ['a', 'b', 'c']);
    });

    test('all-sync operations resolve synchronously', () {
      final w = Waiter<int>()
        ..add(() => 1)
        ..add(() => 2)
        ..add(() => 3);
      final out = w.wait();
      expect(out, isA<Iterable<int>>());
      expect(out, isNot(isA<Future<dynamic>>()));
      expect((out as Iterable<int>).toList(), [1, 2, 3]);
    });

    test('mixed sync/async operations resolve asynchronously', () async {
      final w = Waiter<int>()
        ..add(() => 1)
        ..add(() async => 2);
      final out = w.wait();
      expect(out, isA<Future<Iterable<int>>>());
      expect((await out).toList(), [1, 2]);
    });
  });

  group('Waiter — error handling', () {
    test('both ctor onError and per-call onError fire on a sync throw',
        () async {
      // On the sync-throw path `Waiter.wait` rethrows synchronously rather
      // than returning a rejected Future — wrap in a closure so expect can
      // catch it.
      var ctorCount = 0;
      var callCount = 0;
      final w = Waiter<int>(onError: (e, s) => ctorCount++)
        ..add(() => throw StateError('boom'));
      expect(
        () => w.wait(onError: (e, s) => callCount++),
        throwsA(isA<StateError>()),
      );
      expect(ctorCount, 1, reason: 'ctor onError must run');
      expect(callCount, 1, reason: 'call-site onError must run');
    });

    test('errors short-circuit by default (eagerError: true)', () async {
      // Under eagerError, the very first failing factory aborts the loop —
      // the second factory's body never runs.
      var ranSecond = false;
      final w = Waiter<int>()
        ..add(() => throw StateError('first'))
        ..add(() {
          ranSecond = true;
          return 2;
        });
      try {
        await w.wait();
      } catch (_) {}
      expect(
        ranSecond,
        isFalse,
        reason: 'eagerError must abort before reaching the second factory',
      );
    });

    test('eagerError=false keeps going on async failures', () async {
      var ranAfter = false;
      final w = Waiter<int>()
        ..add(() async => throw StateError('a'))
        ..add(() async {
          ranAfter = true;
          return 2;
        });
      try {
        await w.wait(eagerError: false);
      } catch (_) {}
      expect(ranAfter, isTrue);
    });
  });
}
