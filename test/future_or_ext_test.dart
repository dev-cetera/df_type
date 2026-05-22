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

/// Tests for [FutureOrExt]. The extension distinguishes the two arms of a
/// `FutureOr<T>` (sync value vs. Future) and adds the `withMinDuration`
/// helper used to stop loading spinners flickering.
void main() {
  group('isFuture / isNotFuture', () {
    test('sync value is not a Future', () {
      const FutureOr<int> v = 7;
      expect(v.isFuture, isFalse);
      expect(v.isNotFuture, isTrue);
    });

    test('Future is a Future', () {
      final FutureOr<int> v = Future<int>.value(7);
      expect(v.isFuture, isTrue);
      expect(v.isNotFuture, isFalse);
    });
  });

  group('asFutureOrNull / asNonFutureOrNull', () {
    test('sync value: asNonFutureOrNull returns it, asFutureOrNull is null',
        () {
      const FutureOr<int> v = 7;
      expect(v.asNonFutureOrNull(), 7);
      expect(v.asFutureOrNull(), isNull);
    });

    test('Future: asFutureOrNull returns it, asNonFutureOrNull is null',
        () async {
      final f = Future<int>.value(7);
      final FutureOr<int> v = f;
      expect(v.asFutureOrNull(), same(f));
      expect(v.asNonFutureOrNull(), isNull);
      // sanity: the returned future still resolves correctly.
      expect(await v.asFutureOrNull(), 7);
    });
  });

  group('toFuture', () {
    test('sync value is wrapped', () async {
      const FutureOr<int> v = 7;
      expect(v.toFuture(), isA<Future<int>>());
      expect(await v.toFuture(), 7);
    });

    test('Future is wrapped in another Future (Future.value semantics)',
        () async {
      // Future.value(f) where f is itself a Future flattens — the resulting
      // Future completes with f's value, not with f. Document this.
      final inner = Future<int>.value(7);
      final FutureOr<int> v = inner;
      final wrapped = v.toFuture();
      expect(wrapped, isA<Future<int>>());
      expect(await wrapped, 7);
    });
  });

  group('withMinDuration', () {
    test('null duration returns synchronously', () {
      const FutureOr<int> v = 7;
      final result = v.withMinDuration(null);
      // Identity preserved when no duration is requested.
      expect(result, 7);
    });

    test('forces the elapsed time to be at least the duration', () async {
      const FutureOr<int> v = 7;
      const min = Duration(milliseconds: 80);
      final sw = Stopwatch()..start();
      final result = await v.withMinDuration(min);
      sw.stop();
      expect(result, 7);
      // Allow a generous lower bound: even a 5–10 ms slop is fine on CI.
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(70));
    });

    test('if the underlying Future is already slower, the value is preserved',
        () async {
      final FutureOr<int> v =
          Future<int>.delayed(const Duration(milliseconds: 50), () => 99);
      final sw = Stopwatch()..start();
      final result = await v.withMinDuration(const Duration(milliseconds: 10));
      sw.stop();
      expect(result, 99);
      // The 50ms delay dominates the 10ms minimum.
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });

    test('propagates errors from the underlying Future', () async {
      final FutureOr<int> v = Future<int>.error(StateError('boom'));
      await expectLater(
        v.withMinDuration(const Duration(milliseconds: 5)),
        throwsA(isA<StateError>()),
      );
    });
  });
}
