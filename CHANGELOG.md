# Changelog


## [0.15.0]

- breaking: Rename extension `ValueOfOnEnumExtension` to `ValueOfOnEnumExt`.
- feat: Add `decodeJsonbStrings` — recursively decodes JSON-shaped strings inside Maps and Lists, for normalising Postgres `jsonb` columns.
- fix: `letIntOrNull` now rejects `NaN`, `±Infinity`, and values outside the signed-int64 range. Previously could throw `UnsupportedError` or silently saturate to `int64.min`/`int64.max`.
- fix: `wait` / `consec*` now preserves positional argument order across mixed sync/async inputs.
- fix: `letDateTimeOrNull` now trims whitespace before parsing.
