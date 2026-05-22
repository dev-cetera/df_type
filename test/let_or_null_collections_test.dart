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

import 'package:df_type/df_type.dart';
import 'package:test/test.dart';

/// Covers the iterable/list/set converters in `let_or_null_collections.dart`.
///
/// They share a single implementation path (`letIterableOrNull` is the core,
/// `letListOrNull`/`letSetOrNull` delegate to it), so the test groups are
/// organised by behaviour rather than by individual function — each function
/// then just gets a thin sanity check that the wrapper preserves the shape.
void main() {
  group('letIterableOrNull — input shape handling', () {
    test('accepts a plain Iterable', () {
      final result = letIterableOrNull<int>([1, 2, 3]);
      expect(result, isNotNull);
      expect(result!.toList(), [1, 2, 3]);
    });

    test('decodes a JSON-array string and trims whitespace', () {
      final result = letIterableOrNull<int>('  [1, 2, 3]  ');
      expect(result?.toList(), [1, 2, 3]);
    });

    test('returns null when JSON decodes to a non-iterable', () {
      // `{"a":1}` is valid JSON but not an iterable.
      expect(letIterableOrNull<int>('{"a":1}'), isNull);
    });

    test('returns null on malformed JSON string', () {
      expect(letIterableOrNull<int>('[1,'), isNull);
    });

    test('non-iterable, non-string input returns null', () {
      expect(letIterableOrNull<int>(42), isNull);
      expect(letIterableOrNull<int>(true), isNull);
    });

    test('null input — nullable T allows null, non-nullable T does not', () {
      expect(letIterableOrNull<int>(null), isNull);
      // T = int? is nullable, so null is allowed and short-circuits to null
      // via the upstream `if (input == null) return null` path of letOrNull —
      // but the iterable wrapper still has to refuse the outer null. The
      // function returns null in both cases; the difference shows up when
      // the iterable *contains* nulls (next group).
      expect(letIterableOrNull<int?>(null), isNull);
    });
  });

  group('letIterableOrNull — element conversion', () {
    test('coerces stringy elements into ints', () {
      final result = letIterableOrNull<int>(['1', '2', '3']);
      expect(result?.toList(), [1, 2, 3]);
    });

    test('mismatched elements become null when T is nullable', () {
      // With nullable T, individual bad elements are tolerated as null gaps.
      final result = letIterableOrNull<int?>([1, 'abc', 3]);
      expect(result?.toList(), [1, null, 3]);
    });

    test('mismatched elements still become null when T is non-nullable', () {
      // The return type is `Iterable<T?>?` regardless, so element-level
      // failures don't kill the whole iterable — the caller decides whether
      // to tolerate nulls. Documenting the actual contract here.
      final result = letIterableOrNull<int>([1, 'abc', 3]);
      expect(result?.toList(), [1, null, 3]);
    });

    test('nested string scalars get parsed lazily on iteration', () {
      // The implementation uses `.map(letOrNull<T>)` which is lazy. Confirm
      // we can iterate multiple times and that re-iteration is consistent.
      final result = letIterableOrNull<int>([1, '2', 3])!;
      expect(result.toList(), [1, 2, 3]);
      expect(result.toList(), [1, 2, 3]);
    });
  });

  group('letListOrNull / letSetOrNull wrappers', () {
    test('letListOrNull realises the iterable into a List', () {
      final result = letListOrNull<int>('[1,2,3]');
      expect(result, isA<List<int?>>());
      expect(result, [1, 2, 3]);
    });

    test('letSetOrNull deduplicates', () {
      final result = letSetOrNull<int>([1, 2, 2, 3, 3, 3]);
      expect(result, {1, 2, 3});
    });

    test('letSetOrNull from JSON', () {
      // JSON decodes to a list; toSet drops duplicates.
      expect(letSetOrNull<int>('[1,1,2]'), {1, 2});
    });

    test('null inputs return null for both wrappers', () {
      expect(letListOrNull<int>(null), isNull);
      expect(letSetOrNull<int>(null), isNull);
    });
  });
}
