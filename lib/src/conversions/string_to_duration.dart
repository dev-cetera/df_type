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

/// A tool to convert a string to a [Duration].
class ConvertStringToDuration {
  //
  //
  //

  final String? input;

  //
  //
  //

  const ConvertStringToDuration(this.input);

  //
  //
  //

  /// Tries to convert the [input] to a [Duration]. Accepts formats like
  /// `HH`, `HH:MM`, `HH:MM:SS`, and `HH:MM:SS.SSS`. Any components not specified
  /// are set to 0.
  ///
  /// Returns `null` if the conversion fails.
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
          milliseconds =
              int.parse(secParts[1].padRight(3, '0').substring(0, 3));
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
            milliseconds =
                int.parse(secParts[1].padRight(3, '0').substring(0, 3));
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

  /// Tries convert the [input] to a [Duration]. It assumes the
  /// [input] format is `HH:MM:SS.SSS`. Throws [ConvertStringToDurationEx]
  /// on error.
  Duration toDuration() {
    if (input == null) {
      throw const _StringIsNullEx();
    }
    try {
      final duration = toDurationOrNull()!;
      return duration;
    } catch (_) {
      throw const _InvalidInputStringFormatEx();
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Exception thrown by [ConvertStringToDuration] when the input is null.
final class _StringIsNullEx extends ConvertStringToDurationEx {
  const _StringIsNullEx()
      : super('Failed to convert string to duration: string is null.');
}

/// Exception thrown by [ConvertStringToDuration] when the input string format is invalid.
final class _InvalidInputStringFormatEx extends ConvertStringToDurationEx {
  const _InvalidInputStringFormatEx()
      : super(
          'Failed to convert string to duration: invalid input string format.',
        );
}

/// Exception thrown by [ConvertStringToDuration] when a problem occurs.
class ConvertStringToDurationEx implements Exception {
  final String message;
  const ConvertStringToDurationEx(this.message);
  @override
  String toString() => message;
}
