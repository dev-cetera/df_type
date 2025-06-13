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

import 'dart:async' show FutureOr;

import '../df_type.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ExecuteOperations<T> {
  //
  //
  //

  final _TOnErrorCallback? _onError;
  final List<_TOperation<T>> _operations;

  //
  //
  //

  ExecuteOperations({
    _TOnErrorCallback? onError,
    List<_TOperation<T>> operations = const [],
  }) : _onError = onError,
       _operations = [...operations];

  //
  //
  //

  void add(_TOperation<T> operation) {
    _operations.add(operation);
  }

  //
  //
  //

  void remove(_TOperation<T> operation) {
    _operations.remove(operation);
  }

  //
  //
  //

  void clear(_TOperation<T> operation) {
    _operations.clear();
  }

  //
  //
  //

  FutureOr<Iterable<T>> execute({_TOnErrorCallback? onError}) {
    return consecMap(
      _operations.map((e) => e()),
      onError: (Object e, StackTrace? s) {
        _onError?.call(e, s);
        onError?.call(e, s);
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef _TOnErrorCallback = FutureOr<void> Function(Object e, StackTrace? s);
typedef _TOperation<T> = FutureOr<T> Function();
