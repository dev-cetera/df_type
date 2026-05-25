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

/// The default recursion depth for [decodeJsonbStrings].
///
/// Chosen to accommodate realistic Postgres `jsonb` payloads with comfortable
/// headroom while still keeping the worst-case stack/heap footprint bounded.
/// Inputs nested deeper than this are returned unchanged from the point at
/// which the budget is exhausted, rather than risking a stack overflow.
const int defaultDecodeJsonbStringsMaxDepth = 64;

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
///
/// [maxDepth] caps the recursion. Defaults to
/// [defaultDecodeJsonbStringsMaxDepth]; once exhausted, the function stops
/// recursing and returns the partially-decoded value at that node. This
/// prevents a hostile or pathologically nested payload from overflowing the
/// stack — a real concern when consuming `jsonb` from upstream systems.
dynamic decodeJsonbStrings(
  dynamic input, {
  int maxDepth = defaultDecodeJsonbStringsMaxDepth,
}) {
  if (maxDepth < 0) {
    throw ArgumentError.value(maxDepth, 'maxDepth', 'must be non-negative');
  }
  return _decodeJsonbStrings(input, maxDepth);
}

dynamic _decodeJsonbStrings(dynamic input, int depth) {
  if (depth <= 0) return input;
  if (input is String) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return input;
    final first = trimmed.codeUnitAt(0);
    // 0x7B = '{', 0x5B = '['
    if (first != 0x7B && first != 0x5B) return input;
    try {
      final decoded = const JsonDecoder().convert(trimmed);
      return _decodeJsonbStrings(decoded, depth - 1);
    } catch (_) {
      return input;
    }
  }
  if (input is Map) {
    return input.map(
      (k, v) => MapEntry(k, _decodeJsonbStrings(v, depth - 1)),
    );
  }
  if (input is List) {
    return input.map((e) => _decodeJsonbStrings(e, depth - 1)).toList();
  }
  if (input is Iterable) {
    return input.map((e) => _decodeJsonbStrings(e, depth - 1)).toList();
  }
  return input;
}
