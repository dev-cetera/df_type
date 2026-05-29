# Changelog


## [0.16.0]

- breaking: Remove `DateTimeUtils`, `StreamUtils`, and `StringToDurationConverter`. Moved to the new `df_odd` package.
- breaking: Rename extension `ValueOfOnEnumExtension` to `ValueOfOnEnumExt`.
- breaking: `Waiter.add` now takes a `WaiterOperation<T>` value object; bare-function callers should switch to `addFn(fn, {id})`. The `Waiter` constructor takes `Iterable<WaiterOperation<T>>`.
- breaking: `letAsStringOrNull(null)` returns `null` (previously the literal four-character string `'null'`).
- breaking: `letOrNull<T>` throws `ArgumentError` in every build mode when given a specific collection subtype (e.g. `List<int>`). Previously a debug-only `assert` that was stripped in release, silently returning `null` in production.
- breaking: `letMapOrNull` rejects the conversion when two source keys coerce to the same target key. Previously the second entry silently overwrote the first.
- breaking: `Function.tryCall` no longer absorbs `Error` subtypes (`StackOverflowError`, `OutOfMemoryError`, `AssertionError`, `StateError`, …). It still absorbs `Exception`, `TypeError`, and `NoSuchMethodError`.
- feat: Add `decodeJsonbStrings` — recursively decodes JSON-shaped strings inside Maps and Lists, for normalising Postgres `jsonb` columns. Accepts an optional `maxDepth` parameter (default `64`) so hostile or pathological nesting cannot overflow the stack.
- feat: Add `WaiterOperation<T>` — immutable value-object wrapper around a deferred operation, with optional `id` for auditing. Cross-isolate sendable when `run` is a top-level or `static` function.
- feat: Add `Waiter.addFn(fn, {id})` and `Waiter.removeWhere(test)`.
- feat: Export `isJsRuntime`, `jsSafeIntegerBound`, `vmInt64Bound`, and `defaultDecodeJsonbStringsMaxDepth` for callers that need to branch on runtime or align with the package's safety bounds.
- fix: `letIntOrNull` now rejects `NaN`, `±Infinity`, and values outside the runtime-correct safe-integer range — `[-2^63, 2^63)` on the Dart VM, `[-2^53, 2^53]` on the JS runtime (Flutter web / dart2js / dartdevc) where `int` is backed by a 64-bit double. Previously could throw `UnsupportedError`, silently saturate to `int64.min`/`int64.max`, or hand back a precision-mangled value on JS.
- fix: `wait` / `consec*` now preserves positional argument order across mixed sync/async inputs.
- fix: `wait` / `consec*` / `Waiter`: a buggy `onError` handler no longer masks the original incident. The handler's own failure is surfaced through `Zone.current.handleUncaughtError`, while the caller still sees the original error.
- fix: `wait` / `consec*` / `Waiter`: `onComplete` now runs on every exit path, including when `onError` itself throws.
- fix: `wait` / `consec*` under `eagerError: true` no longer leaks secondary rejections through `Zone.current.handleUncaughtError` — exactly one attributable failure reaches the caller.
- fix: `Waiter` constructor and per-call error handlers are now awaited if they return a `Future`, and one handler's throw no longer prevents the other from running.
- fix: `letDateTimeOrNull` now trims whitespace before parsing.
