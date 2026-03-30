import 'package:drift/drift.dart';

/// Offline-queue table for operations that need to be synced with the server.
///
/// ARCH RULE (FR94): [clientTimestamp] is set at operation CREATION time and
/// is NEVER updated when sync happens. This preserves commitment contract
/// timestamp integrity.
///
/// status values: 'pending' | 'failed'
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Operation type, e.g. 'COMPLETE_TASK', 'SUBMIT_PROOF'.
  TextColumn get type => text()();

  /// JSON-encoded operation payload.
  TextColumn get payload => text()();

  /// Wall-clock time when this operation was enqueued locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Number of sync retry attempts.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Timestamp captured at operation CREATION — never updated on sync.
  DateTimeColumn get clientTimestamp => dateTime()();

  /// Sync status: 'pending' or 'failed'.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}
