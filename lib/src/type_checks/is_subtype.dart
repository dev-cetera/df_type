//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

/// Returns true if A is a subtype of B.
///
/// ```dart
/// print(isSubtype<int, num>()); // true, int is a num
/// print(isSubtype<num, int>()); // false, num is not an int
/// print(isSubtype<Future<int>, Future>()); // true, Future<int> is a Future
/// print(isSubtype<Future, Future<int>>()); // false, Future is not a Future<int>
/// print(isSubtype<int Function(int), Function>()); // true, int Function(int) is a Function
/// print(isSubtype<Function, int Function(int)>()); // false, Function is not a int Function(int)
/// ```
bool isSubtype<TChild, TParent>() => <TChild>[] is List<TParent>;