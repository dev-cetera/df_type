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

@Deprecated('May be removed from package in the future!')
class StringToDurationConverter {
  //
  //
  //

  final String? input;

  //
  //
  //

  const StringToDurationConverter(this.input);

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
