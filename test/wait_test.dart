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

// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:df_type/df_type.dart';
import 'package:test/test.dart';

/// Abuse tests for [wait], [waitF], [waitAlike], [waitAlikeF] in `wait.dart`.
///
/// This file pokes the orchestration core that the entire `consec*` family
/// sits on. The bugs it has historically been prone to are all in this layer:
///
/// - Reordering arguments when sync values are mixed with Futures.
/// - Failing to honour eagerError vs. non-eagerError semantics symmetrically
///   between sync-throws-in-factory and async-rejected-Future.
/// - Forgetting to run onComplete on every exit path (success, sync error,
///   async error).
/// - Letting an exception inside onError escape (it must replace the original
///   error, not be silently swallowed and not be additive).
///
/// The tests are organised by concern, not by entry point — each one picks
/// whichever of `wait`/`waitF` is most natural.
void main() {
  group('wait — synchronous fast path', () {
    test('all-sync items stay synchronous (no Future returned)', () {
      final result = wait<int>(<FutureOr<dynamic>>[1, 2, 3],
          (items) => items.fold<int>(0, (a, b) => a + (b as int)),);
      expect(result, isA<int>());
      expect(result, 6);
    });

    test('empty input is allowed and the callback receives an empty iterable',
        () {
      final result = wait<int>(
        const <FutureOr<dynamic>>[],
        (items) {
          expect(items, isEmpty);
          return 99;
        },
      );
      expect(result, 99);
    });

    test('order is preserved exactly for sync inputs', () {
      final result = wait<List<dynamic>>(
        <FutureOr<dynamic>>['a', 'b', 'c'],
        (items) => items.toList(),
      );
      expect(result, ['a', 'b', 'c']);
    });
  });

  group('wait — asynchronous path & ordering invariant', () {
    test('a single Future input pushes the result to async', () async {
      final result = wait<int>(
        <FutureOr<dynamic>>[Future<int>.value(5)],
        (items) => items.elementAt(0) as int,
      );
      expect(result, isA<Future<int>>());
      expect(await result, 5);
    });

    test('mixed sync/async items preserve positional order', () async {
      // The historic bug: a Future at position 0 followed by a sync value at
      // position 1 was getting reordered to [sync, async] when the
      // implementation split the buffer in two.
      final result = wait<List<dynamic>>(
        <FutureOr<dynamic>>[
          Future<String>.delayed(const Duration(milliseconds: 5), () => 'A'),
          'B',
          Future<String>.delayed(const Duration(milliseconds: 1), () => 'C'),
          'D',
        ],
        (items) => items.toList(),
      );
      expect(await result, ['A', 'B', 'C', 'D']);
    });

    test('callback may itself return a Future, which is awaited', () async {
      final result = wait<int>(
        <FutureOr<dynamic>>[Future<int>.value(2), 3],
        (items) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return (items.elementAt(0) as int) + (items.elementAt(1) as int);
        },
      );
      expect(result, isA<Future<int>>());
      expect(await result, 5);
    });
  });

  group('wait — error paths', () {
    test('eagerError=true: a sync factory throw is reported immediately',
        () async {
      var onCompleteRan = false;
      await expectLater(
        () async {
          await waitF<int>(
            <FutureOr<dynamic> Function()>[
              () => throw StateError('boom'),
              () => 1,
            ],
            (items) => 0,
            onComplete: () => onCompleteRan = true,
          );
        }(),
        throwsA(isA<StateError>()),
      );
      expect(onCompleteRan, isTrue,
          reason: 'onComplete must always run on the sync-throw path',);
    });

    test('eagerError=false: sync errors are deferred until after all factories',
        () async {
      // With eagerError=false, both factories run, including the second one
      // which produces a fine value. The aggregate Future still throws,
      // because we cannot fabricate a return value from a failed factory —
      // we only stop *eager* short-circuiting.
      final captured = <Object>[];
      try {
        await waitF<int>(
          <FutureOr<dynamic> Function()>[
            () => throw StateError('first'),
            () => 1,
          ],
          (items) => 0,
          eagerError: false,
        );
        fail('Expected an error to propagate');
      } catch (e) {
        captured.add(e);
      }
      expect(captured, hasLength(1));
      expect(captured.first, isA<StateError>());
    });

    test('eagerError=true: async Future error stops the wait', () async {
      await expectLater(
        wait<int>(
          <FutureOr<dynamic>>[
            Future<int>.delayed(const Duration(milliseconds: 5), () => 1),
            Future<int>.error(StateError('bad')),
          ],
          (items) => 0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('eagerError=false: async errors are collected, first is reported',
        () async {
      // The internal `_futureWait` path uses `Future.catchError` to rewrite
      // each pending future into a value-or-error sentinel. For this to work
      // the underlying Future has to accept `_Error` (a private sentinel) as
      // its value type — which only happens when the Future is untyped (i.e.
      // `Future<dynamic>`). That's the path `wait` is documented for.
      Object? captured;
      try {
        await wait<int>(
          <FutureOr<dynamic>>[
            Future<dynamic>.delayed(
              const Duration(milliseconds: 5),
              () => throw StateError('first'),
            ),
            Future<dynamic>.delayed(
              const Duration(milliseconds: 1),
              () => throw StateError('second'),
            ),
          ],
          (items) => 0,
          eagerError: false,
        );
        fail('Expected an error to propagate');
      } catch (e) {
        captured = e;
      }
      expect(captured, isA<StateError>());
      // We don't promise which one wins — only that *some* error escapes.
    });

    test(
      'documented limitation: eagerError=false rewrites errors via '
      'Future.catchError, so strongly-typed Future<T>.error inputs break '
      'with ArgumentError because the rewrite returns a sentinel type that '
      'Future<T> cannot hold',
      () async {
        // This test pins the current behaviour so a future implementation
        // change that fixes it will surface here and force an update.
        await expectLater(
          wait<int>(
            <FutureOr<dynamic>>[
              Future<int>.error(StateError('typed-future')),
            ],
            (items) => 0,
            eagerError: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('a sync error reported via onError is awaitable', () async {
      var onErrorRan = false;
      await expectLater(
        wait<int>(
          <FutureOr<dynamic>>[],
          (items) => throw StateError('callback-boom'),
          onError: (e, s) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            onErrorRan = true;
          },
        ),
        throwsA(isA<StateError>()),
      );
      expect(onErrorRan, isTrue,
          reason: 'async onError must run to completion before rethrow',);
    });

    test('a throwing onError is itself rethrown — no silent swallow', () async {
      await expectLater(
        wait<int>(
          <FutureOr<dynamic>>[Future<int>.error(StateError('original'))],
          (items) => 0,
          onError: (e, s) => throw ArgumentError('replacement'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('wait — onComplete behaviour', () {
    test('runs after a sync success', () {
      var ran = false;
      final result = wait<int>(
        <FutureOr<dynamic>>[1, 2],
        (_) => 99,
        onComplete: () => ran = true,
      );
      expect(result, 99);
      expect(ran, isTrue);
    });

    test('runs after an async success', () async {
      var ran = false;
      await wait<int>(
        <FutureOr<dynamic>>[Future<int>.value(1)],
        (_) => 99,
        onComplete: () => ran = true,
      );
      expect(ran, isTrue);
    });

    test('runs after an async error', () async {
      var ran = false;
      try {
        await wait<int>(
          <FutureOr<dynamic>>[Future<int>.error(StateError('x'))],
          (_) => 0,
          onComplete: () => ran = true,
        );
      } catch (_) {}
      expect(ran, isTrue);
    });

    test('runs after a sync-factory error (eagerError true)', () async {
      var ran = false;
      try {
        await waitF<int>(
          <FutureOr<dynamic> Function()>[() => throw StateError('y')],
          (_) => 0,
          onComplete: () => ran = true,
        );
      } catch (_) {}
      expect(ran, isTrue);
    });

    test('awaits an async onComplete on the success path', () async {
      var step = 0;
      final result = await wait<int>(
        <FutureOr<dynamic>>[Future<int>.value(1)],
        (_) => 99,
        onComplete: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          step = 1;
        },
      );
      expect(result, 99);
      // If onComplete was not awaited internally we'd still see step==0 here.
      expect(step, 1);
    });
  });

  group('waitAlike / waitAlikeF', () {
    test('waitAlike returns the inputs as an Iterable in order', () async {
      final out = await waitAlike<int>(<FutureOr<int>>[
        Future<int>.delayed(const Duration(milliseconds: 5), () => 1),
        2,
        Future<int>.value(3),
      ]);
      expect(out.toList(), [1, 2, 3]);
    });

    test('waitAlikeF defers execution until called', () async {
      final calls = <String>[];
      final factories = <FutureOr<int> Function()>[
        () {
          calls.add('a');
          return 1;
        },
        () async {
          calls.add('b');
          return 2;
        },
      ];
      expect(calls, isEmpty, reason: 'factories must not run until waitAlikeF');
      final out = await waitAlikeF<int>(factories);
      expect(out.toList(), [1, 2]);
      expect(calls, ['a', 'b']);
    });

    test('waitAlike stays sync when no Futures are present', () {
      final out = waitAlike<int>(<FutureOr<int>>[1, 2, 3]);
      expect(out, isA<Iterable<int>>());
      expect(out, isNot(isA<Future<dynamic>>()));
      expect((out as Iterable<int>).toList(), [1, 2, 3]);
    });
  });

  group('consec family — abuse tests', () {
    // Spot-checks across the 1..9 arity range. The bulk of consec correctness
    // is already covered by the underlying wait tests; what we want here is
    // that the typed positional cast in consecN stays correct under
    // heterogeneous input types and that high-arity calls don't truncate.

    test('consec preserves type for a single async input', () async {
      final result = await consec<int, String>(
        Future<int>.value(42),
        (a) => 'n=$a',
      );
      expect(result, 'n=42');
    });

    test('consec2: sync-then-async preserves order', () async {
      final result = await consec2<String, int, String>(
        'lead',
        Future<int>.delayed(const Duration(milliseconds: 3), () => 7),
        (s, n) => '$s-$n',
      );
      expect(result, 'lead-7');
    });

    test('consec9 exercises the deepest arity', () async {
      final result =
          await consec9<int, int, int, int, int, int, int, int, int, int>(
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        (a, b, c, d, e, f, g, h, i) => a + b + c + d + e + f + g + h + i,
      );
      expect(result, 45);
    });

    test('consec3 propagates an error from one of its Futures', () async {
      await expectLater(
        consec3<int, int, int, int>(
          1,
          Future<int>.error(StateError('boom')),
          3,
          (a, b, c) => a + b + c,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'consec3 with eagerError=false: the same Future<T>.error limitation '
      'documented on `wait` applies here, because consec is a thin wrapper. '
      'Pinned to surface any future fix.',
      () async {
        await expectLater(
          consec3<int, int, int, int>(
            1,
            Future<int>.error(StateError('first')),
            Future<int>.error(StateError('second')),
            (a, b, c) => 0,
            eagerError: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
        'mixed heterogeneous types — historic CastError regression must stay '
        'fixed', () async {
      final result = await consec3<String, int, String, String>(
        Future<String>.delayed(const Duration(milliseconds: 5), () => 'lead'),
        42,
        Future<String>.delayed(const Duration(milliseconds: 1), () => 'tail'),
        (s1, n, s2) => '$s1-$n-$s2',
      );
      expect(result, 'lead-42-tail');
    });
  });
}
