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

/// Tests for [letMapOrNull] — `let_or_null_map.dart`.
///
/// Behavioural contract:
/// - Accepts a `Map<dynamic, dynamic>` or a JSON-object string.
/// - Coerces each key/value through [letOrNull] using the requested K/V.
/// - If a key/value fails to coerce AND its type parameter is non-nullable,
///   the entire conversion fails (returns null) — partial maps are never
///   produced.
/// - If the type parameter is nullable, individual failures become `null`
///   entries instead of killing the conversion.
void main() {
  group('letMapOrNull — happy path', () {
    test('passes through an already-correct Map', () {
      final m = <String, int>{'a': 1, 'b': 2};
      // Note: the implementation builds a fresh buffer; identity not preserved.
      expect(letMapOrNull<String, int>(m), {'a': 1, 'b': 2});
    });

    test('coerces stringy keys/values', () {
      final result = letMapOrNull<String, int>(<dynamic, dynamic>{
        'a': '1',
        'b': 2,
      });
      expect(result, {'a': 1, 'b': 2});
    });

    test('decodes a JSON-object string and trims whitespace', () {
      expect(letMapOrNull<String, int>('  {"a":1,"b":2}  '), {'a': 1, 'b': 2});
    });
  });

  group('letMapOrNull — rejection cases', () {
    test('returns null when JSON decodes to a non-map', () {
      expect(letMapOrNull<String, int>('[1,2,3]'), isNull);
    });

    test('returns null on malformed JSON', () {
      expect(letMapOrNull<String, int>('{not json'), isNull);
    });

    test('returns null for non-Map, non-String inputs', () {
      expect(letMapOrNull<String, int>(42), isNull);
      expect(letMapOrNull<String, int>(null), isNull);
      expect(letMapOrNull<String, int>(<int>[]), isNull);
    });

    test('returns null if a key cannot be coerced (non-nullable K)', () {
      // Key 'abc' cannot become an int → whole conversion fails.
      final input = <dynamic, dynamic>{'abc': 1, '2': 2};
      expect(letMapOrNull<int, int>(input), isNull);
    });

    test('returns null if a value cannot be coerced (non-nullable V)', () {
      final input = <dynamic, dynamic>{'a': 'oops', 'b': 2};
      expect(letMapOrNull<String, int>(input), isNull);
    });
  });

  group('letMapOrNull — nullable type parameters', () {
    test('nullable V tolerates per-entry failures with null', () {
      final result = letMapOrNull<String, int?>(<dynamic, dynamic>{
        'a': 1,
        'b': 'oops',
        'c': 3,
      });
      expect(result, {'a': 1, 'b': null, 'c': 3});
    });

    test('nullable K tolerates an unconvertible key as a literal null key', () {
      // Under non-nullable K, this would reject. Under nullable K it must
      // record the failure as a null key entry. The Map will then collapse
      // multiple null keys into the last-write-wins value — documented.
      final result = letMapOrNull<int?, String>(<dynamic, dynamic>{
        'not an int': 'x',
        42: 'y',
      });
      expect(result, {null: 'x', 42: 'y'});
    });
  });

  group('letMapOrNull — empty inputs', () {
    test('empty Map round-trips to empty Map', () {
      expect(letMapOrNull<String, int>(<dynamic, dynamic>{}), <String, int>{});
    });

    test('empty JSON object string round-trips to empty Map', () {
      expect(letMapOrNull<String, int>('{}'), <String, int>{});
    });
  });
}
