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
}
