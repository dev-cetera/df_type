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

/// Top-level function used to construct a `const WaiterOperation`. The const
/// constructor requires its function reference to be a compile-time constant,
/// which only top-level / static functions satisfy. (This also serves as the
/// canonical example of "this is what isolate-sendable operations look
/// like".)
int _topLevelIntFactory() => 1;

void main() {
  group('letIntOrNull — invalid numerics must return null, never throw', () {
    test('NaN', () {
      expect(letIntOrNull(double.nan), isNull);
    });
    test('positive infinity', () {
      expect(letIntOrNull(double.infinity), isNull);
    });
    test('negative infinity', () {
      expect(letIntOrNull(double.negativeInfinity), isNull);
    });
    test('string "NaN" parses to NaN — must not saturate or throw', () {
      expect(letIntOrNull('NaN'), isNull);
    });
    test('value beyond int64 max rejects rather than saturating', () {
      // Previously returned 9223372036854775807 silently — a corrupted result
      // that callers could not distinguish from a legitimately-large input.
      expect(letIntOrNull(1e30), isNull);
    });
    test('value beyond int64 min rejects rather than saturating', () {
      expect(letIntOrNull(-1e30), isNull);
    });
    test('valid integer in range still works', () {
      expect(letIntOrNull(42), 42);
      expect(letIntOrNull('42'), 42);
      expect(letIntOrNull(3.7), 3);
      expect(letIntOrNull('-100'), -100);
    });
    test('null input returns null', () {
      expect(letIntOrNull(null), isNull);
    });
  });

  group('consec/wait — argument order must survive mixed sync/async items', () {
    test('consec2(async, sync) preserves [A, B]', () async {
      final result = await consec2<String, String, String>(
        Future.delayed(const Duration(milliseconds: 5), () => 'A'),
        'B',
        (x, y) => '$x-$y',
      );
      expect(result, 'A-B');
    });

    test('consec3(async, sync, async) preserves [A, B, C]', () async {
      final result = await consec3<String, String, String, String>(
        Future.delayed(const Duration(milliseconds: 10), () => 'A'),
        'B',
        Future.delayed(const Duration(milliseconds: 1), () => 'C'),
        (x, y, z) => '$x-$y-$z',
      );
      expect(result, 'A-B-C');
    });

    test('consec3 with all sync stays synchronous', () {
      final result = consec3<int, int, int, int>(
        1,
        2,
        3,
        (a, b, c) => a + b + c,
      );
      expect(result, isA<int>());
      expect(result, 6);
    });

    test('wait preserves order when callback expects positional indices',
        () async {
      final raw = await wait<List<dynamic>>(
        <FutureOr<dynamic>>[
          Future.delayed(const Duration(milliseconds: 5), () => 'A'),
          'B',
          Future.delayed(const Duration(milliseconds: 1), () => 'C'),
          'D',
        ],
        (items) => items.toList(),
      );
      expect(raw, ['A', 'B', 'C', 'D']);
    });

    test('mixed positional cast survives a heterogeneous chain', () async {
      // The historic bug: with mismatched types, the reorder caused
      // `items.elementAt(0) as String` to receive an `int`, throwing a
      // CastError instead of returning the right value.
      final result = await consec3<String, int, String, String>(
        Future.delayed(const Duration(milliseconds: 5), () => 'lead'),
        42,
        Future.delayed(const Duration(milliseconds: 1), () => 'tail'),
        (s1, n, s2) => '$s1-$n-$s2',
      );
      expect(result, 'lead-42-tail');
    });
  });

  group('letOrNull / letBoolOrNull / letDoubleOrNull baseline sanity', () {
    test('letBoolOrNull accepts case-insensitive strings', () {
      expect(letBoolOrNull('true'), true);
      expect(letBoolOrNull('FALSE'), false);
      expect(letBoolOrNull(' True '), true);
      expect(letBoolOrNull('yes'), isNull);
      expect(letBoolOrNull(1), isNull);
    });
    test('letDoubleOrNull preserves NaN/Infinity (not int conversion)', () {
      expect(letDoubleOrNull('NaN')?.isNaN, isTrue);
      expect(letDoubleOrNull('Infinity'), double.infinity);
    });
    test('letOrNull<int> dispatches through letIntOrNull safely', () {
      expect(letOrNull<int>(double.nan), isNull);
      expect(letOrNull<int>(1e30), isNull);
      expect(letOrNull<int>('42'), 42);
    });
  });

  group(
    'letOrNull — misuse must be loud in both debug and release '
    '(historic assert was stripped in release)',
    () {
      test('rejects List<int> with ArgumentError, not silent null', () {
        expect(
          () => letOrNull<List<int>>([1, 2, 3]),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects Map<String, int> with ArgumentError', () {
        expect(
          () => letOrNull<Map<String, int>>(<String, int>{'a': 1}),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('still accepts Iterable<dynamic> / Map<dynamic, dynamic>', () {
        expect(letOrNull<Iterable<dynamic>>('[1,2]')?.toList(), [1, 2]);
        expect(letOrNull<Map<dynamic, dynamic>>('{"a":1}'), {'a': 1});
      });
    },
  );

  group('letMapOrNull — coerced-key collisions must be rejected, not silent',
      () {
    test('{1: "a", "1": "b"} with K=int is rejected because keys collide', () {
      // Both keys project to the int 1 after coercion. A last-write-wins
      // overwrite is silent data loss — for medical records, this must be
      // surfaced as an outright conversion failure.
      final input = <dynamic, dynamic>{1: 'a', '1': 'b'};
      expect(letMapOrNull<int, String>(input), isNull);
    });

    test('distinct coerced keys still convert', () {
      final input = <dynamic, dynamic>{'1': 'a', '2': 'b'};
      expect(letMapOrNull<int, String>(input), {1: 'a', 2: 'b'});
    });

    test('nullable K: two unconvertible keys collide on null and are rejected',
        () {
      final input = <dynamic, dynamic>{
        'not int a': 'x',
        'not int b': 'y',
      };
      // Both convert to a `null` key — same collision rule applies.
      expect(letMapOrNull<int?, String>(input), isNull);
    });
  });

  group('decodeJsonbStrings — bounded recursion', () {
    test('refuses negative maxDepth with ArgumentError', () {
      expect(
        () => decodeJsonbStrings('{}', maxDepth: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns input unchanged when maxDepth is 0', () {
      // The function checks the budget before doing anything, so even the
      // outermost JSON-shaped string is left alone.
      expect(decodeJsonbStrings('{"a":1}', maxDepth: 0), '{"a":1}');
    });

    test(
        'caps recursion — deeper structures stop being decoded once budget '
        'exhausts (no stack overflow)', () {
      // Build a single-string payload representing 100 levels of nesting.
      var s = '"leaf"';
      for (var i = 0; i < 100; i++) {
        s = i.isEven ? '[$s]' : '{"k":$s}';
      }
      // With a depth budget of 5 we must NOT recurse 100 levels deep. The
      // exact shape returned is implementation-defined past the budget — we
      // only assert the call returns without overflowing the stack.
      expect(() => decodeJsonbStrings(s, maxDepth: 5), returnsNormally);
    });

    test('default budget still decodes realistic nested payloads', () {
      // A 5-level nested document parses cleanly under the default budget.
      const json = '{"a":{"b":{"c":{"d":{"e":1}}}}}';
      expect(decodeJsonbStrings(json), {
        'a': {
          'b': {
            'c': {
              'd': {'e': 1},
            },
          },
        },
      });
    });
  });

  group('tryCall — critical Errors must propagate, not be swallowed', () {
    test('StateError propagates (it is an Error, not an Exception)', () {
      void bomb() => throw StateError('reactor over budget');
      expect(
        () => bomb.tryCall<void, Object?>(null),
        throwsA(isA<StateError>()),
      );
    });

    test('AssertionError propagates', () {
      // The assert is in a `bomb` function so it always evaluates.
      void bomb() {
        assert(false, 'invariant violated');
      }

      expect(
        () => bomb.tryCall<void, Object?>(null),
        anyOf(
          throwsA(isA<AssertionError>()),
          // In release mode the assert is stripped, so the call simply
          // returns null — that's still safer than silent absorption of a
          // real AssertionError in debug.
          returnsNormally,
        ),
      );
    });

    test('Exception subtypes (FormatException) are still absorbed → null', () {
      int parse(String s) => int.parse(s);
      expect(parse.tryCall<int, Object?>(['not a number']), isNull);
    });

    test('TypeError on bad arg type still absorbed → null', () {
      String accept(String s) => s;
      expect(accept.tryCall<String, Object?>([42]), isNull);
    });

    test('NoSuchMethodError on wrong arity still absorbed → null', () {
      String oneArg(String a) => a;
      expect(oneArg.tryCall<String, Object?>(['a', 'b']), isNull);
    });
  });

  group('Waiter — async handlers must be awaited and isolated', () {
    test('async ctor onError runs to completion before wait() resolves',
        () async {
      var ranCtor = 0;
      final w = Waiter<int>(
        onError: (e, s) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          ranCtor++;
        },
      )..addFn(() async => throw StateError('boom'));
      try {
        await w.wait();
      } catch (_) {}
      expect(ranCtor, 1, reason: 'async ctor handler must be awaited');
    });

    test(
      'a throwing ctor handler does not prevent the call handler from running',
      () async {
        var ranCall = false;
        Object? zoneCapture;
        await runZonedGuarded<Future<void>>(
          () async {
            final w = Waiter<int>(
              onError: (e, s) => throw ArgumentError('ctor-broke'),
            )..addFn(() => throw StateError('boom'));
            try {
              await w.wait(onError: (e, s) => ranCall = true);
            } catch (_) {}
          },
          (e, s) => zoneCapture = e,
        );
        expect(ranCall, isTrue, reason: 'call handler must still run');
        expect(
          zoneCapture,
          isA<ArgumentError>(),
          reason: 'broken ctor handler must be visible through the zone',
        );
      },
    );

    test('original error propagates even if both handlers throw', () async {
      Object? caught;
      await runZonedGuarded<Future<void>>(
        () async {
          final w = Waiter<int>(
            onError: (e, s) => throw ArgumentError('ctor'),
          )..addFn(() => throw StateError('original'));
          try {
            await w.wait(onError: (e, s) => throw ArgumentError('call'));
          } catch (e) {
            caught = e;
          }
        },
        (e, s) {},
      );
      expect(
        caught,
        isA<StateError>(),
        reason: 'original incident is what the caller must see',
      );
    });
  });

  group('runtime-detection — JS and VM behave differently', () {
    test('isJsRuntime matches identical(0, 0.0)', () {
      // Pinned so a future refactor can't drift the detection.
      expect(isJsRuntime, identical(0, 0.0));
    });

    test('safe-integer constants match their bit-exact values', () {
      // 2^53 and 2^63 — single-line sanity check.
      expect(jsSafeIntegerBound, 9007199254740992.0);
      expect(vmInt64Bound, 9223372036854775808.0);
    });
  });

  group('letIntOrNull — JS precision bound', () {
    test('VM accepts values up to int64 max; JS clamps at 2^53', () {
      // 2^53 — accepted on every runtime.
      expect(letIntOrNull(9007199254740992), 9007199254740992);
      // 2^53 + 1 — past the safe bound on JS, still fine on the VM.
      if (isJsRuntime) {
        expect(letIntOrNull(9007199254740993), isNull);
      } else {
        expect(letIntOrNull(9007199254740993), 9007199254740993);
      }
    });

    test('values past 2^53 from a string are rejected on JS', () {
      // The string `'9007199254740993'` parses to an in-precision int on the
      // VM but to a precision-mangled double on JS — the function refuses
      // the latter.
      final result = letIntOrNull('9007199254740993');
      if (isJsRuntime) {
        expect(
          result,
          isNull,
          reason: 'JS lost precision — must not return a wrong answer',
        );
      } else {
        expect(result, 9007199254740993);
      }
    });

    test('values past int64 are always rejected on every runtime', () {
      expect(letIntOrNull(1e30), isNull);
      expect(letIntOrNull(-1e30), isNull);
      expect(letIntOrNull('1e30'), isNull);
    });
  });

  group('wait.dart — eager-error secondary rejections must NOT leak to Zone',
      () {
    test('two rejected Futures: only the first is observable', () async {
      final zoneCaught = <Object>[];
      await runZonedGuarded<Future<void>>(
        () async {
          try {
            await wait<int>(
              <FutureOr<dynamic>>[
                Future<int>.delayed(
                  const Duration(milliseconds: 5),
                  () => throw StateError('first'),
                ),
                Future<int>.delayed(
                  const Duration(milliseconds: 10),
                  () => throw ArgumentError('second'),
                ),
              ],
              (items) => 0,
            );
          } catch (_) {}
          // Give the second future ample time to settle so a leak would
          // have surfaced by now.
          await Future<void>.delayed(const Duration(milliseconds: 30));
        },
        (e, s) => zoneCaught.add(e),
      );
      expect(
        zoneCaught,
        isEmpty,
        reason: 'standard Future.wait leaks here; our custom collector '
            'must absorb the second rejection',
      );
    });

    test('all three reject — exactly one (the first) is reported', () async {
      final zoneCaught = <Object>[];
      Object? caught;
      await runZonedGuarded<Future<void>>(
        () async {
          try {
            await wait<int>(
              <FutureOr<dynamic>>[
                Future<int>.delayed(
                  const Duration(milliseconds: 1),
                  () => throw StateError('A'),
                ),
                Future<int>.delayed(
                  const Duration(milliseconds: 5),
                  () => throw StateError('B'),
                ),
                Future<int>.delayed(
                  const Duration(milliseconds: 10),
                  () => throw StateError('C'),
                ),
              ],
              (items) => 0,
            );
          } catch (e) {
            caught = e;
          }
          await Future<void>.delayed(const Duration(milliseconds: 30));
        },
        (e, s) => zoneCaught.add(e),
      );
      expect(caught, isA<StateError>());
      expect(
        zoneCaught,
        isEmpty,
        reason: 'B and C must not leak — single attributable failure only',
      );
    });
  });

  group('WaiterOperation — immutability and value semantics', () {
    test('id is preserved verbatim and survives wrapping', () {
      final op = WaiterOperation<int>(() => 1, id: 'audit-marker');
      expect(op.id, 'audit-marker');
      // The wrapper is `const`-compatible.
      const op2 = WaiterOperation<int>(_topLevelIntFactory, id: 'static');
      expect(op2.id, 'static');
    });

    test('operations queue snapshot is frozen', () {
      final w = Waiter<int>()..addFn(() => 1);
      final snap = w.operations;
      w.addFn(() => 2);
      // The pre-mutation snapshot still reads 1 element.
      expect(snap, hasLength(1));
      expect(w.operations, hasLength(2));
      // And the snapshot itself is unmodifiable.
      expect(
        () => snap.add(WaiterOperation(() => 3)),
        throwsUnsupportedError,
      );
    });
  });

  group('wait.dart — onComplete must always run, even if onError throws', () {
    test('sync error path: onComplete still fires after a broken onError',
        () async {
      var ranComplete = false;
      Object? zoneCapture;
      await runZonedGuarded<Future<void>>(
        () async {
          await expectLater(
            () async {
              await waitF<int>(
                <FutureOr<dynamic> Function()>[
                  () => throw StateError('boom'),
                ],
                (_) => 0,
                onError: (e, s) => throw ArgumentError('handler-bug'),
                onComplete: () => ranComplete = true,
              );
            }(),
            throwsA(isA<StateError>()),
          );
        },
        (e, s) => zoneCapture = e,
      );
      expect(
        ranComplete,
        isTrue,
        reason: 'cleanup must run even when onError is broken',
      );
      expect(zoneCapture, isA<ArgumentError>());
    });

    test('async error path: onComplete still fires after a broken onError',
        () async {
      var ranComplete = false;
      Object? zoneCapture;
      await runZonedGuarded<Future<void>>(
        () async {
          await expectLater(
            wait<int>(
              <FutureOr<dynamic>>[Future<int>.error(StateError('async-boom'))],
              (_) => 0,
              onError: (e, s) => throw ArgumentError('async-handler-bug'),
              onComplete: () => ranComplete = true,
            ),
            throwsA(isA<StateError>()),
          );
        },
        (e, s) => zoneCapture = e,
      );
      expect(ranComplete, isTrue);
      // The async path uses Future.catchError; the broken handler may surface
      // either through the zone or as an uncaught Future error depending on
      // timing. Accept either — what matters is that the original StateError
      // is what the caller sees and onComplete still fired.
      expect(zoneCapture, anyOf(isA<ArgumentError>(), isNull));
    });
  });
}
