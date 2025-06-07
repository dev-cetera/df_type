<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

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
}
```

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_type/main/LICENSE) for more information.
