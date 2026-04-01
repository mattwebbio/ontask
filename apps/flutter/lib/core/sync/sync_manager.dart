import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/database.dart';

part 'sync_manager.g.dart';

// ── Conflict resolution policy (FR94) ────────────────────────────────────────
//
// | Data Type                             | Policy                              |
// |---------------------------------------|-------------------------------------|
// | Task properties (title, notes, etc.)  | Last-write-wins with clientTimestamp|
// | Task completion status                | Client timestamp preserved          |
// | Structural (list membership,          | Server wins                         |
// |   assignment, schedule/calendar)      |                                     |
//
// A conflict exists when:
//   - The server has a more recent lastModified than the operation's clientTimestamp
//     for STRUCTURAL properties → server wins unconditionally.
//   - The client has a more recent clientTimestamp than the server's lastModified
//     for CONTENT properties → client wins.
//
// After resolution, if any conflict was detected, the caller should surface
// AppStrings.syncConflictResolvedMessage to the user (NFR-UX2).

// ── Data types ────────────────────────────────────────────────────────────────

/// Content properties (title, notes, due date, priority, completion status)
/// are resolved by last-write-wins with [clientTimestamp].
///
/// Structural properties (list membership, assignment, schedule, calendar)
/// are always server-authoritative regardless of timestamps.
enum _PropertyType { content, structural }

/// The result of resolving a single pending operation against the server state.
enum ConflictResolutionOutcome {
  /// No conflict — operation applied cleanly.
  noConflict,

  /// Content conflict resolved: client timestamp was newer, client wins.
  clientWins,

  /// Structural conflict resolved: server wins unconditionally.
  serverWins,
}

/// Represents a resolved conflict event — surfaced to callers for user messaging.
@immutable
class ConflictEvent {
  final String operationType;
  final ConflictResolutionOutcome outcome;

  const ConflictEvent({
    required this.operationType,
    required this.outcome,
  });
}

// ── Sync Manager ─────────────────────────────────────────────────────────────

/// Manages the offline operation queue and conflict resolution.
///
/// On reconnect, processes [PendingOperations] from the local drift DB via FIFO.
/// Applies conflict resolution per the architecture policy (FR94):
///   - Content properties → last-write-wins with [clientTimestamp].
///   - Structural properties → server always wins.
///
/// After sync, if any conflicts were detected, returns a non-empty list of
/// [ConflictEvent] objects so the caller can surface a plain-language message
/// (NFR-UX2) — e.g. [AppStrings.syncConflictResolvedMessage].
///
/// ARCH NOTE: [connectivity_plus] integration (network reconnect triggering) is
/// wired externally — this class exposes [processQueue] for the caller to invoke
/// when connectivity is restored. This keeps the sync manager testable without
/// platform channel dependencies.
@Riverpod(keepAlive: true)
class SyncManager extends _$SyncManager {
  @override
  void build() {
    // No reactive state — SyncManager is a command object.
  }

  /// Processes all pending operations in FIFO order.
  ///
  /// Returns the list of [ConflictEvent]s detected during this sync cycle.
  /// An empty list means no conflicts — caller should not show any message.
  ///
  /// The [serverStateResolver] callback receives the operation type and
  /// payload, and returns the server's current state for that entity as a
  /// JSON map (or `null` if the entity no longer exists on the server).
  ///
  /// The [applyOperation] callback performs the actual API write for
  /// operations that pass conflict resolution.
  ///
  /// In practice, these callbacks are injected by the repository layer.
  /// In tests, they are replaced with fakes for deterministic behaviour.
  Future<List<ConflictEvent>> processQueue({
    required Future<Map<String, dynamic>?> Function(
      String operationType,
      Map<String, dynamic> payload,
    ) serverStateResolver,
    required Future<void> Function(
      String operationType,
      Map<String, dynamic> payload,
    ) applyOperation,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final pending = await db
        .select(db.pendingOperations)
        .get();

    // Sort by createdAt ascending — FIFO.
    pending.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final conflicts = <ConflictEvent>[];

    for (final op in pending) {
      final payload =
          jsonDecode(op.payload) as Map<String, dynamic>;

      final serverState = await serverStateResolver(op.type, payload);

      if (serverState == null) {
        // Entity deleted server-side — drop the pending operation.
        await (db.delete(db.pendingOperations)
              ..where((t) => t.id.equals(op.id)))
            .go();
        continue;
      }

      final outcome = _resolveConflict(
        operationType: op.type,
        payload: payload,
        clientTimestamp: op.clientTimestamp,
        serverState: serverState,
      );

      switch (outcome) {
        case ConflictResolutionOutcome.noConflict:
        case ConflictResolutionOutcome.clientWins:
          // Apply the client operation.
          try {
            await applyOperation(op.type, payload);
            await (db.delete(db.pendingOperations)
                  ..where((t) => t.id.equals(op.id)))
                .go();
          } catch (_) {
            // Enforce max 3 retries (ARCH-26, NFR-R5).
            final nextRetryCount = op.retryCount + 1;
            if (nextRetryCount >= 3) {
              // Max retries exceeded — mark failed and notify.
              await (db.update(db.pendingOperations)
                    ..where((t) => t.id.equals(op.id)))
                  .write(
                PendingOperationsCompanion(
                  retryCount: Value(nextRetryCount),
                  status: const Value('failed'),
                ),
              );
              _onOperationFailed(op);
            } else {
              // Stay in queue for next sync cycle with incremented retry count.
              await (db.update(db.pendingOperations)
                    ..where((t) => t.id.equals(op.id)))
                  .write(
                PendingOperationsCompanion(
                  retryCount: Value(nextRetryCount),
                  status: const Value('pending'),
                ),
              );
            }
          }

        case ConflictResolutionOutcome.serverWins:
          // Discard the client operation — server state is authoritative.
          await (db.delete(db.pendingOperations)
                ..where((t) => t.id.equals(op.id)))
              .go();
      }

      if (outcome != ConflictResolutionOutcome.noConflict) {
        conflicts.add(ConflictEvent(
          operationType: op.type,
          outcome: outcome,
        ));
      }
    }

    return conflicts;
  }

  // ── Conflict resolution logic ───────────────────────────────────────────────

  ConflictResolutionOutcome _resolveConflict({
    required String operationType,
    required Map<String, dynamic> payload,
    required DateTime clientTimestamp,
    required Map<String, dynamic> serverState,
  }) {
    final propertyType = _classifyOperation(operationType, payload);
    final serverLastModified = _parseServerLastModified(serverState);

    if (serverLastModified == null) {
      // No server timestamp — assume no conflict.
      return ConflictResolutionOutcome.noConflict;
    }

    if (propertyType == _PropertyType.structural) {
      // Structural properties: server always wins.
      if (clientTimestamp.isAfter(serverLastModified) ||
          clientTimestamp == serverLastModified) {
        // Client is newer but server still wins for structural.
        return ConflictResolutionOutcome.serverWins;
      }
      return ConflictResolutionOutcome.serverWins;
    }

    // Content properties: last-write-wins by timestamp.
    if (clientTimestamp.isAfter(serverLastModified)) {
      // Client is newer → client wins.
      return ConflictResolutionOutcome.clientWins;
    } else if (clientTimestamp == serverLastModified) {
      // Same timestamp — no conflict.
      return ConflictResolutionOutcome.noConflict;
    } else {
      // Server is newer → server already has the latest; client operation is stale.
      return ConflictResolutionOutcome.serverWins;
    }
  }

  /// Classifies an operation as content or structural based on its type and
  /// the fields present in [payload].
  _PropertyType _classifyOperation(
    String operationType,
    Map<String, dynamic> payload,
  ) {
    // Structural operation types — server always wins.
    const structuralTypes = {
      'ADD_TO_LIST',
      'REMOVE_FROM_LIST',
      'ASSIGN_TASK',
      'UNASSIGN_TASK',
      'MOVE_TO_LIST',
      'SCHEDULE_TASK',
      'SET_CALENDAR_BLOCK',
    };

    if (structuralTypes.contains(operationType)) {
      return _PropertyType.structural;
    }

    // For UPDATE_TASK operations, inspect which fields are being updated.
    if (operationType == 'UPDATE_TASK') {
      final fields = payload.keys.toSet()
        ..remove('taskId')
        ..remove('clientTimestamp');

      const structuralFields = {
        'listId',
        'assigneeId',
        'calendarBlockId',
        'scheduledAt',
      };

      if (fields.any(structuralFields.contains)) {
        return _PropertyType.structural;
      }
    }

    return _PropertyType.content;
  }

  DateTime? _parseServerLastModified(Map<String, dynamic> serverState) {
    final raw = serverState['lastModifiedAt'] ?? serverState['updatedAt'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw as String);
    } catch (_) {
      return null;
    }
  }

  /// Called when an operation exceeds max retries.
  /// Story 7.6: logs the failure. Real push notification deferred to Story 11.x.
  void _onOperationFailed(PendingOperation op) {
    debugPrint(
      'SyncManager: operation ${op.type} (id=${op.id}) '
      'exceeded max retries and is marked failed (ARCH-26, NFR-R5).',
    );
    // TODO(11.x): push a local notification to the user via flutter_local_notifications
  }
}
