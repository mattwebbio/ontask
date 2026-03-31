import '../../../core/l10n/strings.dart';

/// Status dimension for task search filters.
enum TaskSearchStatus {
  upcoming,
  overdue,
  completed;

  /// Maps to the API query parameter value.
  String toApiValue() {
    switch (this) {
      case TaskSearchStatus.upcoming:
        return 'upcoming';
      case TaskSearchStatus.overdue:
        return 'overdue';
      case TaskSearchStatus.completed:
        return 'completed';
    }
  }

  /// Maps to the user-facing display label via [AppStrings].
  String displayLabel() {
    switch (this) {
      case TaskSearchStatus.upcoming:
        return AppStrings.searchFilterStatusUpcoming;
      case TaskSearchStatus.overdue:
        return AppStrings.searchFilterStatusOverdue;
      case TaskSearchStatus.completed:
        return AppStrings.searchFilterStatusCompleted;
    }
  }
}
