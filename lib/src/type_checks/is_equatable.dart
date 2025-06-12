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

import 'package:equatable/equatable.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Checks if T is any of the following types, which are directly comparable
/// using the `==` operator and are passed by value:
///
/// - BigInt
/// - bool
/// - DateTime
/// - double
/// - Duration
/// - Enum
/// - int
/// - Null
/// - num
/// - Pattern
/// - RegExp
/// - Runes
/// - StackTrace
/// - String
/// - Symbol
/// - Type
/// - Uri
///
/// Additionally, if T implements Equatable, it is also considered comparable.
///
/// Returns `true` if T is one of these types or implements Equatable.
bool isEquatable<T>() {
  return <Type>{
    Equatable,
    BigInt,
    bool,
    DateTime,
    double,
    Duration,
    Enum,
    int,
    Null,
    num,
    Pattern,
    RegExp,
    Runes,
    StackTrace,
    String,
    Symbol,
    Type,
    Uri,
  }.contains(T);
}
