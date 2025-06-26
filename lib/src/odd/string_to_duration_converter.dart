//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

/// A utility to safely parse a string into a [Duration].
///
/// This class handles various time formats commonly used to represent durations,
/// such as `HH:MM:SS`. It is used by creating an instance with the input
/// string and then calling the [toDurationOrNull] method.
///
/// {@tool snippet}
/// ```dart
/// final duration = const StringToDurationConverter('01:30:45').toDurationOrNull();
/// print(duration); // Prints: 1:30:45.000000
///
/// final invalid = const StringToDurationConverter('not a duration').toDurationOrNull();
/// print(invalid); // Prints: null
/// ```
/// {@end-tool}
@Deprecated('May be removed from package in the future!')
class StringToDurationConverter {
  /// The string to be converted into a [Duration].
  final String? input;

  /// Creates a converter for the given string [input].
  const StringToDurationConverter(this.input);

  /// Tries to convert the stored `input` string to a [Duration].
  ///
  /// This method supports the following formats:
  /// - `HH:MM:SS.mmm` (e.g., '01:23:45.678')
  /// - `HH:MM:SS` (e.g., '01:23:45')
  /// - `HH:MM` (e.g., '01:23')
  /// - `HH` (e.g., '1' or '01')
  /// - `SS.mmm` (e.g., '45.678', when a single decimal value is provided)
  ///
  /// Components not provided in the string (like seconds or minutes) default to 0.
  ///
  /// Returns `null` if the input string is empty, null, or does not match any
  /// of the supported formats.
  Duration? toDurationOrNull() {
    if (input == null || input!.isEmpty) return null;
    final parts = input!.trim().split(':');
    var hours = 0;
    var minutes = 0;
    var seconds = 0;
    var milliseconds = 0;
    try {
      if (parts.length == 3) {
        // Format: HH:MM:SS[.SSS].
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        seconds = int.parse(secParts[0]);
        if (secParts.length > 1) {
          milliseconds = int.parse(
            secParts[1].padRight(3, '0').substring(0, 3),
          );
        }
      } else if (parts.length == 2) {
        // Format: HH:MM.
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
      } else if (parts.length == 1) {
        // Format: HH or SS[.SSS] if it's single number.
        final secParts = parts[0].split('.');
        if (secParts.length > 1 || parts[0].contains('.')) {
          seconds = int.parse(secParts[0]);
          if (secParts.length > 1) {
            milliseconds = int.parse(
              secParts[1].padRight(3, '0').substring(0, 3),
            );
          }
        } else {
          hours = int.parse(parts[0]);
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
