[![pub](https://img.shields.io/pub/v/df_type.svg)](https://pub.dev/packages/df_type)
[![tag](https://img.shields.io/badge/Tag-v0.16.0-purple?logo=github)](https://github.com/dev-cetera/df_type/tree/v0.16.0)
[![buymeacoffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dev_cetera)
[![sponsor](https://img.shields.io/badge/Sponsor-grey?logo=github-sponsors&logoColor=pink)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/Patreon-grey?logo=patreon)](https://www.patreon.com/robelator)
[![discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)](https://discord.gg/gEQ8y2nfyX)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

## Summary

Small, focused utilities for runtime type handling, lenient value coercion,
and mixed sync/async flows in Dart. Hardened for **life-critical use**:
silent data corruption, masked errors, and silent saturations are all
defects, not features.

What's in the box:

- **Safe value coercion** — `letOrNull<T>(input)` plus a family of
  `let{Int,Double,Bool,Num,Uri,DateTime,String,Iterable,List,Set,Map}OrNull`
  helpers that return `null` on any failure instead of throwing. Rejects
  silently-unsafe inputs (NaN, infinity, out-of-range doubles) rather than
  saturating. `letIntOrNull` uses the runtime-correct safe bound on web
  (`±2^53`) versus VM (`±2^63`). `letMapOrNull` rejects coerced-key
  collisions instead of letting one entry overwrite another.
- **Type-level inspection** — `isSubtype<TChild, TParent>()`,
  `typeEquality<T1, T2>()`, and `isNullable<T>()` for generic-level checks
  that aren't otherwise expressible in Dart.
- **`FutureOr` orchestration** — `wait`, `waitF`, and the `consec1..consec9`
  family run mixed sync/async work in argument order, with `eagerError` and
  lifecycle callbacks (`onError`, `onComplete`). Stays synchronous when all
  inputs are synchronous. The original error always reaches the caller —
  buggy handlers are surfaced through `Zone.handleUncaughtError` but never
  mask the incident. `onComplete` runs on every exit path.
- **`Waiter<T>`** — a deferred batch of operations you can build up over
  time and then execute together. Operations are stored as immutable
  [`WaiterOperation<T>`](#waiteroperation--cross-isolate-friendly) value
  objects, which makes the queue auditable and (when callers use top-level
  functions) sendable across isolates.
- **`decodeJsonbStrings`** — recursively decodes JSON-shaped strings inside
  a value tree. Handy for Postgres `jsonb` columns that may arrive
  pre-decoded or as raw JSON depending on the driver. Bounded by a
  `maxDepth` parameter (default `64`) so hostile or pathological nesting
  can't overflow the stack.
- **Convenience extensions** — `Function.tryCall` (safe `Function.apply`,
  but it deliberately does **not** swallow `Error` subtypes like
  `StackOverflowError` or `AssertionError`), `Iterable<Enum>.valueOf`
  (case-insensitive enum lookup), and `FutureOrExt` (`isFuture`,
  `withMinDuration`, etc.).

## Installation

```sh
dart pub add df_type
# or, for a Flutter project:
flutter pub add df_type
```

## Usage

```dart
import 'package:df_type/df_type.dart';

void main() async {
  // Lenient scalar coercion.
  letIntOrNull('42');           // 42
  letIntOrNull('not a number'); // null
  letIntOrNull(double.nan);     // null (never throws, never saturates)

  // Nested collection coercion from a JSON string.
  letMapOrNull<String, int>('{"a":1,"b":2}'); // {a: 1, b: 2}

  // Mixed sync/async, results delivered in the order you passed them in.
  final greeting = await consec3<String, int, String, String>(
    Future.delayed(const Duration(milliseconds: 10), () => 'hello'),
    42,
    Future.value('world'),
    (a, b, c) => '$a $b $c',
  );
  print(greeting); // hello 42 world

  // Deferred batch of operations via Waiter — `addFn` is the
  // closure-friendly shortcut; `add(WaiterOperation(...))` is the
  // isolate-portable form.
  final waiter = Waiter<String>()
    ..addFn(() => 'sync result', id: 'a')
    ..addFn(() async => 'async result', id: 'b');
  final results = await waiter.wait();
  print(results); // (sync result, async result)
}
```

### `WaiterOperation` — cross-isolate friendly

`Waiter` stores its queue as immutable `WaiterOperation<T>` value objects.
Each carries a `run` function plus an optional `id` for auditing / logging.
When `run` is a top-level or `static` function, the operation (and a list of
them) is safely sendable across an `Isolate` boundary:

```dart
int heavyTask() { /* ... */ }

await Isolate.run(() async {
  final w = Waiter<int>(
    operations: const [
      WaiterOperation(heavyTask, id: 'compute-1'),
      WaiterOperation(heavyTask, id: 'compute-2'),
    ],
  );
  return (await w.wait()).toList();
});
```

Closures (`() => ...`) capture their enclosing isolate and cannot cross a
`SendPort` — that's a Dart runtime restriction, not something the package
imposes. The value-object wrapper exists precisely so the choice between
"sendable" (top-level/static) and "local-only" (closure) is explicit and
inspectable at call sites.

## Safety guarantees

- **No silent failures.** Misused calls throw `ArgumentError` in every
  build mode (no debug-only `assert`s). Coerced-key collisions in maps
  cause the whole conversion to fail rather than silently overwriting.
- **The original error always wins.** A buggy `onError` / `onComplete`
  handler never replaces the underlying incident; its own failure is
  surfaced via `Zone.handleUncaughtError` so it is still observable but
  not in the caller's catch block.
- **Cleanup always runs.** `onComplete` fires on every exit path,
  including when `onError` itself throws.
- **No critical-`Error` absorption.** `Function.tryCall` swallows
  `Exception`, `TypeError`, and `NoSuchMethodError` only — `StackOverflow`,
  `OutOfMemory`, `AssertionError`, and `StateError` propagate.
- **Bounded recursion.** `decodeJsonbStrings` enforces a `maxDepth` (default
  `64`) so hostile input cannot overflow the stack.
- **No silent saturation of integers.** `letIntOrNull` returns `null`
  outside the runtime-appropriate safe bound — `±2^63` on the VM, `±2^53`
  on the JS runtime where `int` is double-backed.

## Cross-platform and isolate safety

The library targets the Dart VM, the JS runtime (Flutter web, dart2js,
dartdevc), and **WebAssembly via `dart compile wasm` / `flutter build web
--wasm`**. It has no `dart:io` or `dart:isolate` imports under `lib/`, and
all `lib/` sources are pure Dart with no JS-interop or platform conditional
imports. A minimal program exercising the public surface bundles to roughly
100 KB minified via dart2js, or ~85 KB of `.wasm` + ~13 KB of JS glue via
dart2wasm — both dominated by the SDK runtime rather than this library.

Every top-level binding under `lib/` is `const` or `final` of an immutable
expression — there is **no shared mutable static state**, so multiple
isolates can use the package concurrently without interference. A dedicated
[`test/isolate_safety_test.dart`](test/isolate_safety_test.dart) suite
proves this end-to-end on the VM by sending `Waiter`s and operations
through `Isolate.run`.

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/df_type/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE) for more information.
