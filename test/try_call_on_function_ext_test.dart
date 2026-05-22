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

/// Tests for [TryCallOnFunctionExt.tryCall].
///
/// The extension is a thin wrapper around `Function.apply` that converts any
/// thrown exception into a `null` return value. The tests below verify both
/// the happy path (positional, named, mixed arguments) and the failure modes
/// it must absorb (wrong arity, wrong types, callee throws, missing required
/// arg, etc.).
///
/// `tryCall<T, A>` has two type parameters: `T` is the return type, `A` is the
/// element type of the argument lists. We use `Object?` for `A` in nearly
/// every test because Dart's strict-inference linter rejects single-arg use of
/// the extension (the source's docstring example is misleading in that
/// regard — it predates strict-inference being enforced).
void main() {
  group('tryCall — happy path', () {
    test('positional arguments of a single type', () {
      String repeat(String s, int times) => s * times;
      expect(repeat.tryCall<String, Object?>(['hi ', 2]), 'hi hi ');
    });

    test('mixed positional argument types', () {
      String f(String s, int n, bool flag) => '$s-$n-$flag';
      expect(f.tryCall<String, Object?>(['x', 1, true]), 'x-1-true');
    });

    test('named arguments', () {
      String greet({required String name, String title = 'Dr.'}) =>
          '$title $name';
      expect(
        greet.tryCall<String, Object?>([], {#name: 'Ada', #title: 'Ms.'}),
        'Ms. Ada',
      );
    });

    test('default named argument is honoured when not passed', () {
      String greet({required String name, String title = 'Dr.'}) =>
          '$title $name';
      expect(
        greet.tryCall<String, Object?>([], {#name: 'Ada'}),
        'Dr. Ada',
      );
    });

    test('zero-argument function', () {
      int answer() => 42;
      expect(answer.tryCall<int, Object?>(null), 42);
      expect(answer.tryCall<int, Object?>([]), 42);
    });

    test('explicit null arg lists are treated as empty', () {
      int answer() => 7;
      expect(answer.tryCall<int, Object?>(null, null), 7);
    });
  });

  group('tryCall — failure absorption', () {
    test('callee throws → returns null', () {
      int parse(String s) => int.parse(s);
      expect(parse.tryCall<int, Object?>(['not a number']), isNull);
    });

    test('wrong arity (too few) → null', () {
      String f(String a, String b) => '$a$b';
      expect(f.tryCall<String, Object?>(['only one']), isNull);
    });

    test('wrong arity (too many) → null', () {
      String f(String a) => a;
      expect(f.tryCall<String, Object?>(['a', 'b']), isNull);
    });

    test('wrong positional type → null', () {
      String f(String s) => s;
      // Calling with an int where a String is required must not throw.
      expect(f.tryCall<String, Object?>([42]), isNull);
    });

    test('missing required named arg → null', () {
      String f({required String name}) => name;
      expect(
        f.tryCall<String, Object?>([], <Symbol, Object?>{}),
        isNull,
      );
    });

    test('unknown named arg → null', () {
      String f({required String name}) => name;
      expect(
        f.tryCall<String, Object?>([], {#name: 'Ada', #unknown: 1}),
        isNull,
      );
    });

    test('return-type mismatch with T → null', () {
      // The function returns String; we ask for int. The `as T?` cast in
      // `Function.apply`'s wrapper throws, which tryCall swallows to null.
      String f() => 'hi';
      expect(f.tryCall<int, Object?>(null), isNull);
    });
  });

  group('tryCall — edge cases', () {
    test('function that returns null is allowed', () {
      String? f() => null;
      expect(f.tryCall<String, Object?>(null), isNull);
    });

    test('function that returns a Future is returned as-is', () async {
      Future<int> f() async => 99;
      final result = f.tryCall<Future<int>, Object?>(null);
      expect(result, isA<Future<int>>());
      expect(await result, 99);
    });

    test('void function returns null via cast', () {
      // `void` apply returns null; the cast to T? = String? succeeds with null.
      void f() {}
      expect(f.tryCall<String, Object?>(null), isNull);
    });
  });
}
