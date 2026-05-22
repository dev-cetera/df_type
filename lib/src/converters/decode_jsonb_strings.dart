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

import 'dart:convert' show JsonDecoder;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Recursively walks [input] and decodes any [String] value that begins with
/// `{` or `[` as JSON, replacing it with the decoded [Map] or [List].
///
/// Intended for Postgres `jsonb` columns: depending on the driver (and codec
/// configuration), a `jsonb` value may arrive as either a pre-decoded
/// `Map`/`List` or as a raw JSON [String]. Applying this once to a row before
/// handing it to a generated `Model.fromJson` removes that difference so the
/// model's field-level mappers see the same shape either way.
///
/// Strings that do not start with `{` / `[` (after trimming), or that fail to
/// parse, are returned unchanged — so non-jsonb text columns are unaffected.
dynamic decodeJsonbStrings(dynamic input) {
  if (input is String) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;
    final first = trimmed.codeUnitAt(0);
    // 0x7B = '{', 0x5B = '['
    if (first != 0x7B && first != 0x5B) return input;
    try {
      final decoded = const JsonDecoder().convert(trimmed);
      return decodeJsonbStrings(decoded);
    } catch (_) {
      return input;
    }
  }
  if (input is Map) {
    return input.map(
      (k, v) => MapEntry(k, decodeJsonbStrings(v)),
    );
  }
  if (input is List) {
    return input.map(decodeJsonbStrings).toList();
  }
  if (input is Iterable) {
    return input.map(decodeJsonbStrings).toList();
  }
  return input;
}
