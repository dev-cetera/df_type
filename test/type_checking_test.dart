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
  group('isSubtype', () {
    test('numeric subtyping', () {
      expect(isSubtype<int, num>(), isTrue);
      expect(isSubtype<double, num>(), isTrue);
      expect(isSubtype<num, int>(), isFalse);
      expect(isSubtype<num, double>(), isFalse);
    });

    test('reflexive — every type is a subtype of itself', () {
      expect(isSubtype<int, int>(), isTrue);
      expect(isSubtype<String, String>(), isTrue);
      expect(isSubtype<Object, Object>(), isTrue);
    });

    test('Object/dynamic top-types', () {
      expect(isSubtype<int, Object>(), isTrue);
      expect(isSubtype<int, dynamic>(), isTrue);
      expect(isSubtype<Object, int>(), isFalse);
    });

    test('Never is a subtype of everything', () {
      expect(isSubtype<Never, int>(), isTrue);
      expect(isSubtype<Never, String>(), isTrue);
      expect(isSubtype<Never, Object>(), isTrue);
    });

    test('generic invariance for Lists', () {
      expect(isSubtype<List<int>, List<num>>(), isTrue);
      expect(isSubtype<List<num>, List<int>>(), isFalse);
      expect(isSubtype<List<int>, List<dynamic>>(), isTrue);
    });

    test('generic invariance for Futures', () {
      expect(isSubtype<Future<int>, Future<dynamic>>(), isTrue);
      expect(isSubtype<Future<dynamic>, Future<int>>(), isFalse);
    });

    test('function types', () {
      expect(isSubtype<int Function(int), Function>(), isTrue);
      expect(isSubtype<Function, int Function(int)>(), isFalse);
    });

    test('nullable types', () {
      expect(isSubtype<int, int?>(), isTrue);
      expect(isSubtype<int?, int>(), isFalse);
      expect(isSubtype<Null, int?>(), isTrue);
      expect(isSubtype<Null, int>(), isFalse);
    });

    test('unrelated types', () {
      expect(isSubtype<int, String>(), isFalse);
      expect(isSubtype<List<int>, Set<int>>(), isFalse);
    });
  });

  group('typeEquality', () {
    test('identical concrete types are equal', () {
      expect(typeEquality<int, int>(), isTrue);
      expect(typeEquality<String, String>(), isTrue);
      expect(typeEquality<List<int>, List<int>>(), isTrue);
    });

    test('related-but-distinct types are unequal', () {
      expect(typeEquality<int, num>(), isFalse);
      expect(typeEquality<num, int>(), isFalse);
      expect(typeEquality<int, int?>(), isFalse);
    });

    test('different generic args are unequal', () {
      expect(typeEquality<List<int>, List<num>>(), isFalse);
      expect(typeEquality<Map<String, int>, Map<String, num>>(), isFalse);
    });

    test('dynamic and Object are different identities', () {
      expect(typeEquality<dynamic, Object>(), isFalse);
      expect(typeEquality<dynamic, dynamic>(), isTrue);
      expect(typeEquality<Object, Object>(), isTrue);
    });
  });

  group('isNullable', () {
    test('nullable scalars', () {
      expect(isNullable<int?>(), isTrue);
      expect(isNullable<String?>(), isTrue);
      expect(isNullable<Object?>(), isTrue);
    });

    test('non-nullable scalars', () {
      expect(isNullable<int>(), isFalse);
      expect(isNullable<String>(), isFalse);
      expect(isNullable<Object>(), isFalse);
    });

    test('dynamic admits null', () {
      expect(isNullable<dynamic>(), isTrue);
    });

    test('Null itself is "nullable"', () {
      expect(isNullable<Null>(), isTrue);
    });

    test('Never is not nullable', () {
      expect(isNullable<Never>(), isFalse);
    });

    test('nullability is independent of inner type args', () {
      expect(isNullable<List<int>?>(), isTrue);
      expect(isNullable<List<int?>>(), isFalse);
      expect(isNullable<Map<String, int?>>(), isFalse);
      expect(isNullable<Map<String, int?>?>(), isTrue);
    });
  });
}
