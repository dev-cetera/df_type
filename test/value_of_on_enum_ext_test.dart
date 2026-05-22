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

/// Tests for [ValueOfOnEnumExt.valueOf]. The extension's contract is a
/// case-insensitive, whitespace-tolerant lookup on enum value names with a
/// `null` fallback for "not found".
void main() {
  group('valueOf — basic lookup', () {
    test('exact match', () {
      expect(_Status.values.valueOf('pending'), _Status.pending);
    });

    test('case-insensitive match', () {
      expect(_Status.values.valueOf('ACTIVE'), _Status.active);
      expect(_Status.values.valueOf('Done'), _Status.done);
    });

    test('whitespace is trimmed', () {
      expect(_Status.values.valueOf('  active  '), _Status.active);
    });
  });

  group('valueOf — miss cases', () {
    test('unknown name returns null', () {
      expect(_Status.values.valueOf('archived'), isNull);
    });

    test('null input returns null without throwing', () {
      expect(_Status.values.valueOf(null), isNull);
    });

    test('empty / whitespace-only string returns null', () {
      expect(_Status.values.valueOf(''), isNull);
      expect(_Status.values.valueOf('   '), isNull);
    });
  });

  group('valueOf — restricted sublists', () {
    test('the receiver is the lookup set, not the whole enum', () {
      // Calling `valueOf` on a sublist that excludes `done` must not find it.
      final partial = [_Status.pending, _Status.active];
      expect(partial.valueOf('done'), isNull);
      expect(partial.valueOf('active'), _Status.active);
    });

    test('empty iterable always returns null', () {
      expect(<_Status>[].valueOf('pending'), isNull);
    });
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Sample enum used purely for testing — kept local so the production code
/// doesn't gain a dependency on it.
enum _Status { pending, active, done }
