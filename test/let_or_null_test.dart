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

/// Exercises every scalar `let...OrNull` converter and the top-level
/// [letOrNull] dispatcher. The converters all share the same contract:
/// return the requested type on success, `null` on any kind of failure —
/// never throw. Most of these tests poke around the seams (whitespace,
/// already-typed inputs, malformed strings, etc.) to make sure that
/// contract holds.
void main() {
  group('letAsOrNull — identity-cast helper', () {
    test('returns input when it matches T', () {
      expect(letAsOrNull<int>(7), 7);
      expect(letAsOrNull<String>('hi'), 'hi');
    });

    test('returns null when input does not match T', () {
      expect(letAsOrNull<int>('7'), isNull);
      expect(letAsOrNull<String>(7), isNull);
    });

    test('null input returns null', () {
      expect(letAsOrNull<int>(null), isNull);
    });
  });

  group('letAsStringOrNull', () {
    test('uses toString for primitives', () {
      expect(letAsStringOrNull(42), '42');
      expect(letAsStringOrNull(true), 'true');
      expect(letAsStringOrNull(3.14), '3.14');
    });

    test('strings pass through unchanged', () {
      expect(letAsStringOrNull(' hello '), ' hello '); // no trimming
    });

    test('null input returns null (not the string "null")', () {
      // Earlier revisions of this helper let `null.toString()` through,
      // producing the literal four-character string 'null'. That sentinel
      // leaking into a medical record is unacceptable, so the helper now
      // null-guards explicitly.
      expect(letAsStringOrNull(null), isNull);
    });

    test('survives a throwing toString', () {
      expect(letAsStringOrNull(const _ToStringThrows()), isNull);
    });
  });

  group('jsonDecodeOrNull', () {
    test('decodes a Map', () {
      expect(jsonDecodeOrNull<Map<String, dynamic>>('{"a":1}'), {'a': 1});
    });

    test('decodes a List', () {
      expect(jsonDecodeOrNull<List<dynamic>>('[1,2,3]'), [1, 2, 3]);
    });

    test('returns null for malformed JSON', () {
      expect(jsonDecodeOrNull<Map<String, dynamic>>('{not json'), isNull);
    });

    test('type-checks the decoded result against T', () {
      // Valid JSON whose decoded shape does not match T → null.
      expect(jsonDecodeOrNull<Map<String, dynamic>>('[1,2,3]'), isNull);
      expect(jsonDecodeOrNull<List<dynamic>>('{"a":1}'), isNull);
    });

    test('decodes primitives when T allows', () {
      expect(jsonDecodeOrNull<num>('42'), 42);
      expect(jsonDecodeOrNull<bool>('true'), true);
    });
  });

  group('letNumOrNull', () {
    test('passes numerics straight through', () {
      expect(letNumOrNull(1), 1);
      expect(letNumOrNull(1.5), 1.5);
    });

    test('parses string numerics, trimming whitespace', () {
      expect(letNumOrNull('  42  '), 42);
      expect(letNumOrNull(' -3.14 '), -3.14);
      expect(letNumOrNull('1e3'), 1000);
    });

    test('returns null for non-numeric input', () {
      expect(letNumOrNull('abc'), isNull);
      expect(letNumOrNull(null), isNull);
      expect(letNumOrNull(<int>[]), isNull);
      expect(letNumOrNull(true), isNull);
    });
  });

  group('letIntOrNull', () {
    test('truncates doubles toward zero', () {
      expect(letIntOrNull(3.9), 3);
      expect(letIntOrNull(-3.9), -3);
    });

    test('exact int64 boundaries', () {
      // int64.max and int64.min are accepted; anything one ULP past the
      // boundary in the double domain is rejected.
      expect(letIntOrNull(9223372036854775807), 9223372036854775807);
      expect(letIntOrNull(-9223372036854775808), -9223372036854775808);
    });

    test('rejects non-finite doubles', () {
      expect(letIntOrNull(double.nan), isNull);
      expect(letIntOrNull(double.infinity), isNull);
      expect(letIntOrNull(double.negativeInfinity), isNull);
    });

    test('rejects out-of-range doubles instead of saturating', () {
      // See the comment on `letIntOrNull`: silent saturation is unacceptable
      // because it returns an indistinguishable garbage value.
      expect(letIntOrNull(1e30), isNull);
      expect(letIntOrNull(-1e30), isNull);
    });
  });

  group('letDoubleOrNull', () {
    test('numerics become doubles', () {
      expect(letDoubleOrNull(5), 5.0);
      expect(letDoubleOrNull(2.5), 2.5);
    });

    test('strings parse — including non-finite forms', () {
      expect(letDoubleOrNull('NaN')?.isNaN, isTrue);
      expect(letDoubleOrNull('Infinity'), double.infinity);
      expect(letDoubleOrNull('-Infinity'), double.negativeInfinity);
    });

    test('null and unparseable inputs', () {
      expect(letDoubleOrNull(null), isNull);
      expect(letDoubleOrNull('abc'), isNull);
    });
  });

  group('letBoolOrNull', () {
    test('accepts native bools', () {
      expect(letBoolOrNull(true), isTrue);
      expect(letBoolOrNull(false), isFalse);
    });

    test('accepts case-insensitive, trimmed strings', () {
      expect(letBoolOrNull('true'), isTrue);
      expect(letBoolOrNull(' TRUE '), isTrue);
      expect(letBoolOrNull('False'), isFalse);
    });

    test('rejects 1/0 and yes/no — only literal true/false', () {
      expect(letBoolOrNull(1), isNull);
      expect(letBoolOrNull(0), isNull);
      expect(letBoolOrNull('yes'), isNull);
      expect(letBoolOrNull('no'), isNull);
    });

    test('null input returns null', () {
      expect(letBoolOrNull(null), isNull);
    });
  });

  group('letUriOrNull', () {
    test('passes Uris through', () {
      final u = Uri.parse('https://example.com/path');
      expect(letUriOrNull(u), same(u));
    });

    test('parses string Uris with whitespace trimmed', () {
      expect(
        letUriOrNull('  https://example.com  '),
        Uri.parse('https://example.com'),
      );
    });

    test('Uri.tryParse is very lenient — anything it accepts comes back', () {
      // Note: Dart's Uri.tryParse only rejects truly malformed URIs.
      // We document the actual behaviour rather than imagining strict parsing.
      expect(letUriOrNull('not a url'), isNotNull);
    });

    test('non-string, non-Uri input returns null', () {
      expect(letUriOrNull(42), isNull);
      expect(letUriOrNull(null), isNull);
    });
  });

  group('letDateTimeOrNull', () {
    test('passes DateTime through', () {
      final d = DateTime.utc(2024, 1, 2, 3, 4, 5);
      expect(letDateTimeOrNull(d), same(d));
    });

    test('parses ISO-8601 strings, trimming whitespace', () {
      expect(
        letDateTimeOrNull(' 2024-01-02T03:04:05Z '),
        DateTime.utc(2024, 1, 2, 3, 4, 5),
      );
    });

    test('returns null for unparseable strings', () {
      expect(letDateTimeOrNull('not a date'), isNull);
      expect(letDateTimeOrNull(42), isNull);
      expect(letDateTimeOrNull(null), isNull);
    });
  });

  group('letOrNull dispatcher', () {
    test('returns input unchanged when already the requested type', () {
      expect(letOrNull<int>(7), 7);
      expect(letOrNull<String>('x'), 'x');
    });

    test('dispatches to the right scalar helper', () {
      expect(letOrNull<int>('42'), 42);
      expect(letOrNull<double>('1.5'), 1.5);
      expect(letOrNull<bool>('true'), isTrue);
      expect(letOrNull<DateTime>('2024-01-01'), DateTime.parse('2024-01-01'));
      expect(letOrNull<Uri>('https://x.y'), Uri.parse('https://x.y'));
    });

    test('nullable T is routed the same as non-nullable T', () {
      expect(letOrNull<int?>('42'), 42);
      expect(letOrNull<bool?>('true'), isTrue);
    });

    test('returns null for null input on non-nullable T', () {
      expect(letOrNull<int>(null), isNull);
      expect(letOrNull<String>(null), isNull);
    });

    test('falls back to letAsStringOrNull when T is String', () {
      // letAsStringOrNull uses toString(), so we get textual coercion.
      expect(letOrNull<String>(42), '42');
      expect(letOrNull<String>(true), 'true');
    });

    test('rejects specific collection subtypes with ArgumentError', () {
      // Previously this was guarded by an `assert`, which is stripped in
      // release mode — the function then silently returned null on the same
      // misuse. For medical-grade callers, that silent failure is not
      // acceptable, so the guard is now an explicit `throw ArgumentError`
      // that fires in every build mode.
      expect(
        () => letOrNull<List<int>>([1, 2, 3]),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => letOrNull<Set<int>>(<int>{1}),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => letOrNull<Map<String, int>>(<String, int>{'a': 1}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts the absolute-top generic collection types', () {
      // The assert in letOrNull is strict — even `List<dynamic>` is rejected
      // because List<dynamic> is itself a strict subtype of Iterable<dynamic>.
      // Only the broadest types (`Iterable<dynamic>` and `Map<dynamic, dynamic>`)
      // pass the assertion.
      expect(letOrNull<Iterable<dynamic>>('[1,2,3]')?.toList(), [1, 2, 3]);
      expect(letOrNull<Map<dynamic, dynamic>>('{"a":1}'), {'a': 1});
    });
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A value whose `toString()` always throws — used to confirm that
/// [letAsStringOrNull] swallows exceptions rather than propagating them.
class _ToStringThrows {
  const _ToStringThrows();

  @override
  String toString() => throw StateError('boom');
}
