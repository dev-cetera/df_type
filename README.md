<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/.github/refs/heads/main/assets/icons/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![sponsor](https://img.shields.io/badge/sponsor-grey?logo=github-sponsors)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/patreon-grey?logo=patreon)](https://www.patreon.com/c/RobertMollentze)
[![pub](https://img.shields.io/pub/v/df_type.svg)](https://pub.dev/packages/df_type)
[![tag](https://img.shields.io/badge/tag-v0.14.2-purple?logo=github)](https://github.com/dev-cetera/df_type/tree/v0.14.2)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

## Summary

A versatile package that simplifies type conversions, inspections, nested data access, sync/async operations and more.

## Quickstart

```dart
enum Alphabet { A, B, C }

enum Status { pending, active, done }

void main() async {
  // --- Type Checking ---
  print('\n*** Type Checking Utilities ***');
  print('isNullable<String?>: ${isNullable<String?>()}'); // true
  print('isSubtype<int, num>: ${isSubtype<int, num>()}'); // true
  print('typeEquality<int, int>: ${typeEquality<int, int>()}'); // true
  print('typeEquality<int, String>: ${typeEquality<int, String>()}'); // false

  // --- Type Conversion ---
  print('\n*** Type Conversion Utilities ***');
  print("letIntOrNull('55'): ${letIntOrNull('55')}"); // 55
  print(
    "letMapOrNull from JSON: ${letMapOrNull<String, dynamic>('{"a": 1}')}",
  ); // {a: 1}
  print(
    "letListOrNull from CSV: ${letListOrNull<int>('1, 2, 3')}",
  ); // [1, 2, 3]

  // --- Enum Helpers ---
  print('\n*** Enum Helpers ***');
  print(
    "Alphabet.values.valueOf('B'): ${Alphabet.values.valueOf('B')}",
  ); // Alphabet.B

  // --- Function and FutureOr Extensions ---
  print('\n*** Function and FutureOr Extensions ***');
  int Function(int) addOne = (i) => i + 1;
  print('Function.tryCall: ${addOne.tryCall<int, int>([5])}'); // 6

  FutureOr<int> futureOrValue = Future.value(10);
  print('futureOrValue.isFuture: ${futureOrValue.isFuture}'); // true
  print('futureOrValue.toFuture(): ${await futureOrValue.toFuture()}'); // 10

  // --- Asynchronous Helpers ---
  print('\n*** Asynchronous Helpers ***');
  // `consec` for handling a mix of sync/async values
  final result = await consec(Future.value(5), (val) => val * 2);
  print('consec result: $result'); // 10

  // `Waiter` for deferred, batched execution
  final taskQueue = Waiter<String>();
  taskQueue.add(() => 'Task 1');
  taskQueue.add(() async => 'Task 2');
  final waiterResults = await taskQueue.wait();
  print('Waiter results: $waiterResults'); // (Task 1, Task 2)
}
```


<!-- END _README_CONTENT -->

---

☝️ Please refer to the [API reference](https://pub.dev/documentation/df_type/) for more information.

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
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

## 🧑‍⚖️ License

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE) for more information.

