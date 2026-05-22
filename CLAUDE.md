# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The workspace-level `df_packages/CLAUDE.md` two levels up still applies (umbrella layout, `pubspec_overrides.yaml`, `dart format`/`analyze`/`test`, `_src.g.dart` is generated and must not be hand-edited, `lib/_common.dart` as the internal umbrella). The notes below are df_type-specific and **override** anything that conflicts with the workspace file — most importantly, the release flow.

## What this package is

A small utilities package, no Flutter dependency. Surfaces:

- **Lenient value coercion** — `letOrNull<T>` dispatcher plus a family of `let{Int,Double,Bool,Num,Uri,DateTime,String,Iterable,List,Set,Map}OrNull`. Contract: return `T` on success, `null` on any failure, **never throw**.
- **Type-level inspection** — `isSubtype<TChild, TParent>()`, `typeEquality<T1, T2>()`, `isNullable<T>()`.
- **`FutureOr` orchestration** — `wait` / `waitF` and `consec1..consec9` for mixed sync/async work. Stays synchronous when all inputs are synchronous.
- **`Waiter<T>`** — a deferred batch of operations registered now, executed all-at-once later via `Waiter.wait()`.
- **`decodeJsonbStrings`** — recursively decodes JSON-shaped strings inside a value tree (for Postgres `jsonb` columns).
- **Extensions** — `Function.tryCall`, `Iterable<Enum>.valueOf`, `FutureOrExt` (`isFuture`, `withMinDuration`, …).

## Load-bearing design decisions

Tests will fail noisily if these get broken — don't "fix" them without checking why they're the way they are:

- **`letIntOrNull` rejects rather than saturates.** NaN, ±Infinity, and values outside the signed-int64 range all return `null`. Calling `num.toInt()` on them would either throw `UnsupportedError` or silently produce `int64.min`/`int64.max`, both unacceptable. See `lib/src/converters/let_or_null.dart` and the regression cases in `test/hardening_test.dart`.
- **`letOrNull<T>` asserts T is not a *strict* subtype of `Iterable<dynamic>`/`List<dynamic>`/`Set<dynamic>`/`Map<dynamic, dynamic>`.** Only the absolute-top generic collection types (`Iterable<dynamic>`, `Map<dynamic, dynamic>`) pass — `List<dynamic>` and `Set<dynamic>` do *not*, because they are strict subtypes of `Iterable<dynamic>`. Element-typed collections (`List<int>` etc.) are deliberately rejected by the assert.
- **`wait`/`consec` preserves positional order across mixed sync/async inputs.** A historic bug split sync vs async into two buffers and concatenated them, silently reordering arguments. The current implementation keeps a single in-order buffer. The `mixed positional cast` test in `test/hardening_test.dart` and the ordering tests in `test/wait_test.dart` are there to lock this down.
- **Lifecycle callbacks (`onError`, `onComplete`) must fire on every exit path** — sync success, sync error, async success, async error. `test/wait_test.dart` has a dedicated `onComplete behaviour` group covering each path.
- **Known limitation:** under `eagerError: false`, the `_futureWait` path uses `Future.catchError` to rewrite each pending future into a value-or-error sentinel. This only works when the Future is `Future<dynamic>`; passing a strongly-typed `Future<T>.error(...)` produces an `ArgumentError` because the sentinel is not a `T`. Pinned by two tests in `test/wait_test.dart` and `consec3 with eagerError=false ...` — those tests intentionally assert `throwsA(isA<ArgumentError>())` so any future fix to the source forces a test update.

## Tests

Layout — one `*_test.dart` per source file, plus a regression file:

```
test/
  type_checking_test.dart                 # isSubtype, typeEquality, isNullable
  let_or_null_test.dart                   # scalar coercers + letOrNull dispatcher
  let_or_null_collections_test.dart       # letIterableOrNull / letListOrNull / letSetOrNull
  let_or_null_map_test.dart               # letMapOrNull
  decode_jsonb_strings_test.dart
  try_call_on_function_ext_test.dart
  value_of_on_enum_ext_test.dart
  future_or_ext_test.dart
  wait_test.dart                          # abuse tests for wait / waitF / consec1..9
  waiter_test.dart
  hardening_test.dart                     # regression cases for historic bugs
```

Tests follow the standard `*_test.dart` naming, so plain `dart test` discovers them all. Running a single file: `dart test test/wait_test.dart`. Single test by name: `dart test --plain-name 'mixed sync/async items preserve positional order'`.

When adding a new source file under `lib/src/`, regenerate `lib/src/_src.g.dart` (via `df_generate_dart_indexes`) and add a matching `test/<name>_test.dart`.

## Release flow — automated

**Do not use** the workspace-level `+` / `++` commit-message workflow described in the parent `CLAUDE.md`. That workflow has been removed for df_type and replaced with a `prod`-branch pipeline:

```
push to prod  ─►  prod.yml  ─►  pushes tag v{version}  ─►  publish.yml  ─►  pub.dev
                  (test, bump, tag)                       (re-test, publish)
```

`.github/workflows/prod.yml` on push to `prod`:

1. `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `dart test`.
2. **Decides the next version:**
   - If `pubspec.yaml`'s version is *not* yet tagged on the remote → use it as-is (assume the maintainer pre-bumped).
   - Otherwise, inspect the commit subject:
     - Contains `BREAKING CHANGE`, starts with `breaking:`, or uses `feat!:` / `fix!:` → **major**.
     - Starts with `feat` → **minor**.
     - Anything else → **patch**.
3. Rewrites `pubspec.yaml` and prepends a stub `## [version]` section to `CHANGELOG.md` if one doesn't exist.
4. Commits as `ci: release v{version}` and pushes back to `prod`. The bot's commit-author email is filtered at the workflow's `if:` so it doesn't self-trigger.
5. Pushes tag `v{version}`.

`.github/workflows/publish.yml` on push of `v*`: re-runs analyze + test, verifies the tag matches pubspec, then `dart pub publish --force` over OIDC.

**Implications when editing this package:**
- Bumping the version manually is optional — if you don't, the workflow patch-bumps it.
- The auto-written CHANGELOG entry is only the commit subject. For richer entries, run the `/changelog` slash command (`.claude/commands/changelog.md`) locally **before** merging. The workflow checks for an existing entry and won't overwrite yours.
- pub.dev's automated publishing must be enabled once on the package page with tag pattern `v{{version}}`.

## Slash commands

`.claude/commands/changelog.md` — `/changelog [version]`. Drafts a `CHANGELOG.md` entry from `git diff HEAD` + recent commits. Enforces pana's version-must-match-pubspec rule explicitly. Designed to be reusable across other packages in the workspace.
