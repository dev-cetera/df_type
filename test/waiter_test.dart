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
///
/// As of the medical-grade refactor, the queue stores [WaiterOperation]
/// value objects rather than bare closures, so most tests use the
/// `addFn(...)` convenience wrapper. The wrapper-form API is exercised in
/// the "value-object surface" group near the bottom.
void main() {
  group('Waiter — queue management', () {
    test('starts empty', () {
      final w = Waiter<int>();
      expect(w.operations, isEmpty);
    });

    test('addFn appends to the queue', () {
      final w = Waiter<int>()
        ..addFn(() => 1)
        ..addFn(() => 2);
      expect(w.operations, hasLength(2));
    });

    test('addAll appends every supplied operation', () {
      final w = Waiter<int>()
        ..addAll([
          WaiterOperation(() => 1),
          WaiterOperation(() => 2),
          WaiterOperation(() => 3),
        ]);
      expect(w.operations, hasLength(3));
    });

    test('remove drops a matching operation by identity', () {
      final a = WaiterOperation<int>(() => 1, id: 'a');
      final b = WaiterOperation<int>(() => 2, id: 'b');
      final w = Waiter<int>()..addAll([a, b]);
      w.remove(a);
      expect(w.operations, hasLength(1));
      expect(w.operations.single, same(b));
    });

    test('removeWhere drops every op the predicate matches', () {
      final w = Waiter<int>()
        ..addFn(() => 1, id: 'keep')
        ..addFn(() => 2, id: 'drop')
        ..addFn(() => 3, id: 'drop');
      w.removeWhere((op) => op.id == 'drop');
      expect(w.operations, hasLength(1));
      expect(w.operations.single.id, 'keep');
    });

    test('clear empties the queue', () {
      final w = Waiter<int>()
        ..addFn(() => 1)
        ..addFn(() => 2);
      w.clear();
      expect(w.operations, isEmpty);
    });

    test('operations getter is unmodifiable', () {
      final w = Waiter<int>()..addFn(() => 1);
      expect(
        () => w.operations.add(WaiterOperation(() => 2)),
        throwsUnsupportedError,
      );
    });

    test('operations supplied to the ctor are copied, not aliased', () {
      // If the ctor stored the caller's list directly, later mutation of the
      // original list would leak in. Confirm defensive copy.
      final source = <WaiterOperation<int>>[
        WaiterOperation(() => 1),
        WaiterOperation(() => 2),
      ];
      final w = Waiter<int>(operations: source);
      source.add(WaiterOperation(() => 99));
      expect(w.operations, hasLength(2));
    });

    test('operations getter returns a copy — outer mutation does not affect it',
        () {
      final w = Waiter<int>()..addFn(() => 1);
      final snapshot = w.operations;
      w.addFn(() => 2);
      expect(snapshot, hasLength(1),
          reason: 'snapshot must be a frozen copy, not a live view',);
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
        ..addFn(() {
          ran++;
          return 1;
        });
      expect(ran, 0);
      await w.wait();
      expect(ran, 1);
    });

    test('preserves the order operations were registered', () async {
      final w = Waiter<String>()
        ..addFn(() => 'a')
        ..addFn(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return 'b';
        })
        ..addFn(() => 'c');
      final out = await w.wait();
      expect(out.toList(), ['a', 'b', 'c']);
    });

    test('all-sync operations resolve synchronously', () {
      final w = Waiter<int>()
        ..addFn(() => 1)
        ..addFn(() => 2)
        ..addFn(() => 3);
      final out = w.wait();
      expect(out, isA<Iterable<int>>());
      expect(out, isNot(isA<Future<dynamic>>()));
      expect((out as Iterable<int>).toList(), [1, 2, 3]);
    });

    test('mixed sync/async operations resolve asynchronously', () async {
      final w = Waiter<int>()
        ..addFn(() => 1)
        ..addFn(() async => 2);
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
        ..addFn(() => throw StateError('boom'));
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
        ..addFn(() => throw StateError('first'))
        ..addFn(() {
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
        ..addFn(() async => throw StateError('a'))
        ..addFn(() async {
          ranAfter = true;
          return 2;
        });
      try {
        await w.wait(eagerError: false);
      } catch (_) {}
      expect(ranAfter, isTrue);
    });
  });

  group('WaiterOperation — value-object surface', () {
    test('exposes the id verbatim', () {
      final op = WaiterOperation<int>(() => 1, id: 'unit-test-op');
      expect(op.id, 'unit-test-op');
    });

    test('toString includes the id for auditability', () {
      final op = WaiterOperation<int>(() => 1, id: 'audit-marker');
      expect(op.toString(), contains('audit-marker'));
    });

    test('toString flags unnamed ops so log readers spot anonymous ones', () {
      final op = WaiterOperation<int>(() => 1);
      expect(op.toString(), contains('unnamed'));
    });

    test('equality is identity-based — two ops with the same id are distinct',
        () {
      final a = WaiterOperation<int>(() => 1, id: 'x');
      final b = WaiterOperation<int>(() => 1, id: 'x');
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse,
          reason: 'identity, not field-equality, was the historical contract',);
    });

    test('a Waiter built from existing operations preserves them in order', () {
      final ops = <WaiterOperation<int>>[
        WaiterOperation(() => 1, id: 'a'),
        WaiterOperation(() => 2, id: 'b'),
        WaiterOperation(() => 3, id: 'c'),
      ];
      final w = Waiter<int>(operations: ops);
      expect(
        w.operations.map((op) => op.id).toList(),
        ['a', 'b', 'c'],
      );
    });
  });
}
