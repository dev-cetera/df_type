<a href="https://www.buymeacoffee.com/robmllze" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![pub package](https://img.shields.io/pub/v/df_type.svg)](https://pub.dev/packages/df_type)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE)

---

## Summary

This package is designed to simplify and enhance interactions with Dart types. It provides tools for converting between types, checking type properties, and managing synchronous and asynchronous operations.

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_type/).

## Quickstart

```dart
enum Alphabet { A, B, C }

void main() async {
  print('Convert a String to an enum:\n');
  print(Alphabet.values.valueOf('A') == Alphabet.A); // true
  print(Alphabet.values.valueOf('a') == Alphabet.A); // true
  print(Alphabet.values.valueOf('b')); // Alphabet.B
  print(Alphabet.values.valueOf('qwerty') == null); // true

  print('\n*** Check if a type is nullable:\n');
  print(isNullable<String>()); // false
  print(isNullable<String?>()); // true
  print(isNullable<Null>()); // true

  print('\n*** Check if a type a subtype of another::\n');
  print(isSubtype<int, num>()); // true
  print(isSubtype<num, int>()); // false
  print(isSubtype<Future<int>, Future<dynamic>>()); // true
  print(isSubtype<Future<dynamic>, Future<int>>()); // false
  print(isSubtype<int Function(int), Function>()); // true
  print(isSubtype<Function, int Function(int)>()); // false

  print('\n*** Check if a type can be compared by value:\n');
  print(isEquatable<double>()); // true
  print(isEquatable<Null>()); // true
  print(isEquatable<Map<dynamic, dynamic>>()); // false
  print(isEquatable<Equatable>()); // true

  print('\n*** Only let a value be of a certain type, or return null:\n');
  print(letAsOrNull<String>(DateTime.now())); // null
  print(letAsOrNull<DateTime>(DateTime.now())); // returns the value
  print(letAsOrNull<DateTime?>(DateTime.now())); // returns the value
  print(letAsOrNull<DateTime?>(null)); // null

  print('\n*** Lazy-convert types to an int or return null:\n');
  final int? i = letIntOrNull('55');
  print(i); // 55

  print('\n*** Lazy-convert maps from one type to another or return null:\n');
  final Map<String, int>? m = letMapOrNull<String, int>({55: '56'});
  print(m); // {55, 56}

  print('\n*** Lazy-convert lists or return null:\n');
  print(letListOrNull<int>('1, 2, 3, 4')); // [1, 2, 3, 4]
  print(letListOrNull<int>('[1, 2, 3, 4]')); // [1, 2, 3, 4]
  print(letListOrNull<int>([1, 2, 3, 4])); // [1, 2, 3, 4]
  print(letListOrNull<int>(1)); // [1]

  print('\n*** Lazy-convert to double or return null:\n');
  print(letOrNull<double>('123')); // 123.0

  print('\n*** Convert a String to a Duration:\n');
  final Duration duration = const ConvertStringToDuration('11:11:00.00').toDuration();
  print(duration); // 11:11:00.000000

  print('\n*** Use thenOr with FutureOr:\n');
  print(1.thenOr((prev) => prev + 1)); // 2
  FutureOr<double> pi = 3.14159;
  final doublePi = pi.thenOr((prev) => prev * 2);
  print(doublePi); // 6.2832
  FutureOr<double> e = Future.value(2.71828);
  final doubleE = e.thenOr((prev) => prev * 2);
  print(doubleE); // Instance of 'Future<double>'
  print(await doubleE); // 5.43656

  print('\n*** Manage Futures or values via FutureOrController:\n');
  final a1 = Future.value(1);
  final a2 = 2;
  final a3 = Future.value(3);
  final foc1 = FutureOrController<dynamic>([(_) => a1, (_) => a2, (_) => a3]);
  final f1 = foc1.completeWithAll();
  print(f1 is Future); // true
  print(await f1); // [1, 2, 3]
  final b1 = 1;
  final b2 = 2;
  final b3 = 2;
  final foc2 = FutureOrController<dynamic>([(_) => b1, (_) => b2, (_) => b3]);
  final f2 = foc2.completeWithAll();
  print(f2 is Future); // false
  print(f2); // [1, 2, 3]

  print('\n*** CompleterOr works with async or sync values:\n');
  final completer1 = CompleterOr<int>();
  completer1.complete(1);
  final c1 = completer1.futureOr;
  print(c1 is Future); // false
  final completer2 = CompleterOr<int>();
  completer2.complete(Future.value(1));
  final c2 = completer2.futureOr;
  print(c2 is Future); // true

  // The Sequential guarantees that functions will execute in the same
  // order as they are added:
  print('\n*** Test function queue:\n');
  final sequential = Sequential();
  sequential.add((prev) async {
    print('Previous: $prev');
    print('Function 1 running');
    await Future<void>.delayed(const Duration(seconds: 3));
    print('Function 1 completed');
    return 1;
  });
  sequential.add((prev) async {
    print('Previous: $prev');
    await Future<void>.delayed(const Duration(seconds: 2));
    print('Function 2 completed');
    return 2;
  });
  sequential.add((prev) async {
    print('Previous: $prev');
    await Future<void>.delayed(const Duration(seconds: 1));
    print('Function 3 completed');
    return 3;
  });
  await sequential.add((prev) async {
    print('Previous: $prev');
    await Future<void>.delayed(const Duration(seconds: 1));
    print('Function 3 completed');
  });
  // Prints:
  // Function 1 running
  // Function 1 completed
  // Function 2 running
  // Function 2 completed
  // Function 3 running
  // Function 3 completed
  print(sequential.add((_) => 'Hello').runtimeType); // String
  print(sequential.add((prev) => '$prev World!')); // Hello World!
}
```

## Installation

Use this package as a dependency by adding it to your `pubspec.yaml` file (see [here](https://pub.dev/packages/df_type/install)).

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute:

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/robmllze). Your support helps cover the costs of development and keeps the project growing.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### Discord Server

Feel free to ask questions and engage with the community here: https://discord.gg/8hcxk6ZD

## Chief Maintainer:

📧 Email _Robert Mollentze_ at robmllze@gmail.com

## Dontations:

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here:

https://www.buymeacoffee.com/robmllze

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE) for more information.
