[![pub](https://img.shields.io/pub/v/df_type.svg)](https://pub.dev/packages/df_type)
[![tag](https://img.shields.io/badge/Tag-v0.16.0-purple?logo=github)](https://github.com/dev-cetera/df_type/tree/v0.16.0)
[![buymeacoffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dev_cetera)
[![sponsor](https://img.shields.io/badge/Sponsor-grey?logo=github-sponsors&logoColor=pink)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/Patreon-grey?logo=patreon)](https://www.patreon.com/robelator)
[![discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)](https://discord.gg/gEQ8y2nfyX)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE)

---

## Summary

Small, focused utilities for runtime type handling, lenient value coercion,
and mixed sync/async flows in Dart.

What's in the box:

- **Safe value coercion** — `letOrNull<T>(input)` plus a family of
  `let{Int,Double,Bool,Num,Uri,DateTime,String,Iterable,List,Set,Map}OrNull`
  helpers that return `null` on any failure instead of throwing. Rejects
  silently-unsafe inputs (NaN, infinity, out-of-range doubles) rather than
  saturating.
- **Type-level inspection** — `isSubtype<TChild, TParent>()`,
  `typeEquality<T1, T2>()`, and `isNullable<T>()` for generic-level checks
  that aren't otherwise expressible in Dart.
- **`FutureOr` orchestration** — `wait`, `waitF`, and the `consec1..consec9`
  family run mixed sync/async work in argument order, with `eagerError` and
  lifecycle callbacks (`onError`, `onComplete`). Stays synchronous when all
  inputs are synchronous.
- **`Waiter<T>`** — a deferred batch of operations you can build up over
  time and then execute together. Unlike `Future.wait`, the operations
  haven't started yet when you register them.
- **`decodeJsonbStrings`** — recursively decodes JSON-shaped strings inside
  a value tree. Handy for Postgres `jsonb` columns that may arrive
  pre-decoded or as raw JSON depending on the driver.
- **Convenience extensions** — `Function.tryCall` (safe `Function.apply`),
  `Iterable<Enum>.valueOf` (case-insensitive enum lookup), and `FutureOrExt`
  (`isFuture`, `withMinDuration`, etc.).

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
}
```

## Testing

```sh
dart test
```

The package is exercised by a per-module test suite (one `*_test.dart`
file per source file) plus a `hardening_test.dart` of regression cases
for historic bugs. The orchestration core in `lib/src/future_or/` is
covered by abuse tests that exercise the sync/async ordering, error
propagation, and lifecycle-callback contracts.

## Release flow

This package ships through a two-stage GitHub Actions pipeline. See
[`.github/_README.md`](.github/_README.md) for the full story.

Short version: merge to the `prod` branch and you're done. The workflow
runs tests, auto-bumps the version (patch by default, or minor/major if
your commit message says `feat:` / `breaking:` / `feat!:`), updates
`CHANGELOG.md`, tags, and publishes to pub.dev.

If you want full control over the version and changelog instead of
letting the workflow decide, bump `pubspec.yaml` yourself and use the
`/changelog` Claude command at
[`.claude/commands/changelog.md`](.claude/commands/changelog.md) to draft
the entry — the workflow will respect your pre-bumped version.

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
