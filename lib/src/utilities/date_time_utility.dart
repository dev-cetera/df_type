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

final class DateTimeUtility {
  const DateTimeUtility._();

  static final i = const DateTimeUtility._();

  /// Returns the last date in the list of dates, ignoring null values.
  DateTime? last(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>();
    if (filteredDates.isEmpty) return null;
    return filteredDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Returns the first date in the list of dates, ignoring null values.
  DateTime? first(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>();
    if (filteredDates.isEmpty) return null;
    return filteredDates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Returns the average date in the list of dates, ignoring null values.
  DateTime? avg(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>();
    if (filteredDates.isEmpty) return null;
    final totalMs = filteredDates.fold<int>(
      0,
      (sum, date) => sum + date.millisecondsSinceEpoch,
    );
    final avgMs = totalMs ~/ filteredDates.length;
    return DateTime.fromMillisecondsSinceEpoch(avgMs);
  }

  /// Returns the median date in the list of dates, ignoring null values.
  DateTime? median(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>().toList()..sort();
    if (filteredDates.isEmpty) return null;
    final middleIndex = filteredDates.length ~/ 2;
    if (filteredDates.length.isOdd) {
      return filteredDates[middleIndex];
    } else {
      final medianMs =
          (filteredDates[middleIndex - 1].millisecondsSinceEpoch +
              filteredDates[middleIndex].millisecondsSinceEpoch) ~/
          2;
      return DateTime.fromMillisecondsSinceEpoch(medianMs);
    }
  }
}
