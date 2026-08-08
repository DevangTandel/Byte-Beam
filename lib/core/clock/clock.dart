// Abstract class enables test doubles; ignore one_member_abstracts.
// ignore_for_file: one_member_abstracts

/// Provides a testable abstraction over system time.
abstract class Clock {
  /// Returns the current date and time.
  DateTime now();
}
