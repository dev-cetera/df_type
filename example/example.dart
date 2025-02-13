//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: omit_local_variable_types

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:df_type/df_type.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

enum Alphabet { A, B, C }

void main() async {
  print('Convert a String to an enum:\n');
  print(Alphabet.values.valueOf('A') == Alphabet.A); // true
  print(Alphabet.values.valueOf('a') == Alphabet.A); // true
  print(Alphabet.values.valueOf('b')); // Alphabet.B
  print(Alphabet.values.valueOf('qwerty') == null); // true

  print('\n*** Check if a type is nullable:\n');
  print(isNullable<String>()); // false
  print(isNullable<String?>()); // true
  print(isNullable<Null>()); // true

  print('\n*** Check if a type a subtype of another::\n');
  print(isSubtype<int, num>()); // true
  print(isSubtype<num, int>()); // false
  print(isSubtype<Future<int>, Future<dynamic>>()); // true
  print(isSubtype<Future<dynamic>, Future<int>>()); // false
  print(isSubtype<int Function(int), Function>()); // true
  print(isSubtype<Function, int Function(int)>()); // false

  print('\n*** Check if a type can be compared by value:\n');
  print(isEquatable<double>()); // true
  print(isEquatable<Null>()); // true
  print(isEquatable<Map<dynamic, dynamic>>()); // false
  print(isEquatable<Equatable>()); // true

  print('\n*** Only let a value be of a certain type, or return null:\n');
  print(letAsOrNull<String>(DateTime.now())); // null
  print(letAsOrNull<DateTime>(DateTime.now())); // returns the value
  print(letAsOrNull<DateTime?>(DateTime.now())); // returns the value
  print(letAsOrNull<DateTime?>(null)); // null

  print('\n*** Lazy-convert types to an int or return null:\n');
  final int? i = letIntOrNull('55');
  print(i); // 55

  print('\n*** Lazy-convert maps from one type to another or return null:\n');
  final Map<String, int>? m = letMapOrNull<String, int>({55: '56'});
  print(m); // {55, 56}

  print('\n*** Lazy-convert lists or return null:\n');
  print(letListOrNull<int>('1, 2, 3, 4')); // [1, 2, 3, 4]
  print(letListOrNull<int>('[1, 2, 3, 4]')); // [1, 2, 3, 4]
  print(letListOrNull<int>([1, 2, 3, 4])); // [1, 2, 3, 4]
  print(letListOrNull<int>(1)); // [1]

  print('\n*** Lazy-convert to double or return null:\n');
  print(letOrNull<double>('123')); // 123.0

  print('\n*** Convert a String to a Duration:\n');
  final Duration duration = const ConvertStringToDuration('11:11:00.00').toDuration();
  print(duration); // 11:11:00.000000

  print('\n*** Use thenOr with FutureOr:\n');
  print(consec(1, (prev) => prev + 1)); // 2
  FutureOr<double> pi = 3.14159;
  final doublePi = consec(pi, (prev) => prev * 2);
  print(doublePi); // 6.2832
  FutureOr<double> e = Future.value(2.71828);
  final doubleE = consec(e, (prev) => prev * 2);
  print(doubleE); // Instance of 'Future<double>'
  print(await doubleE); // 5.43656

  print('\n*** Manage Futures or values via FutureOrController:\n');
  final a1 = Future.value(1);
  final a2 = 2;
  final a3 = Future.value(3);
  final foc1 = SequentialController<dynamic>([(_) => a1, (_) => a2, (_) => a3]);
  final f1 = foc1.completeWithAll();
  print(f1 is Future); // true
  print(await f1); // [1, 2, 3]
  final b1 = 1;
  final b2 = 2;
  final b3 = 2;
  final foc2 = SequentialController<dynamic>([(_) => b1, (_) => b2, (_) => b3]);
  final f2 = foc2.completeWithAll();
  print(f2 is Future); // false
  print(f2); // [1, 2, 3]
}
