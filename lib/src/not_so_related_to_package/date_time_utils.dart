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

/// A collection of static utility methods for performing aggregate calculations
/// on lists of [DateTime] objects.
///
/// Provides convenient access via the singleton instance `DateTimeUtils.i`.
///
/// {@tool snippet}
/// ```dart
/// final dates = [
///   DateTime(2023, 10, 20),
///   DateTime(2023, 10, 10),
///   null, // Nulls are safely ignored.
///   DateTime(2023, 10, 30),
/// ];
///
/// final earliest = DateTimeUtils.i.first(dates);
/// print('Earliest date: $earliest'); // 2023-10-10
///
/// final latest = DateTimeUtils.i.last(dates);
/// print('Latest date: $latest'); // 2023-10-30
/// ```
/// {@end-tool}
@Deprecated('May be removed from package in the future!')
final class DateTimeUtils {
  // A private constructor to prevent instantiation of this utility class.
  const DateTimeUtils._();

  /// The singleton instance for accessing DateTime utilities.
  static final i = const DateTimeUtils._();

  /// Returns the latest (most recent) `DateTime` from an iterable.
  ///
  /// Ignores any `null` values within the list. Returns `null` if the
  /// iterable is null or contains no valid dates after filtering.
  DateTime? last(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>();
    if (filteredDates.isEmpty) return null;
    return filteredDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Returns the earliest (oldest) `DateTime` from an iterable.
  ///
  /// Ignores any `null` values within the list. Returns `null` if the
  /// iterable is null or contains no valid dates after filtering.
  DateTime? first(Iterable<DateTime?>? dates) {
    if (dates == null) return null;
    final filteredDates = dates.whereType<DateTime>();
    if (filteredDates.isEmpty) return null;
    return filteredDates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Calculates and returns the average `DateTime` from an iterable.
  ///
  /// Ignores `null` values. The average is computed based on the
  /// `millisecondsSinceEpoch` of all valid dates. Returns `null` if the
  /// iterable is null or contains no valid dates.
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

  /// Calculates and returns the median (middle) `DateTime` from an iterable.
  ///
  /// Ignores `null` values. If the list has an even number of elements, the
  /// average of the two middle dates is returned. Returns `null` if the
  /// iterable is null or contains no valid dates.
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
