import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/storage/database.dart';
import 'package:ontask/core/sync/sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates an in-memory [AppDatabase] for testing.
AppDatabase _makeTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Inserts a [PendingOperation] into [db] and returns it.
Future<void> insertPendingOp(
  AppDatabase db, {
  required String type,
  required Map<String, dynamic> payload,
  required DateTime clientTimestamp,
  String status = 'pending',
}) async {
  await db.into(db.pendingOperations).insert(
        PendingOperationsCompanion.insert(
          type: type,
          payload: jsonEncode(payload),
          createdAt: clientTimestamp,
          clientTimestamp: clientTimestamp,
          status: Value(status),
        ),
      );
}

/// Builds a [ProviderContainer] wired to [testDb].
ProviderContainer _makeContainer(AppDatabase testDb) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(testDb),
    ],
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── Conflict resolution: structural props — server always wins ───────────────

  group('SyncManager — structural properties: server wins', () {
    test('ADD_TO_LIST: server wins regardless of clientTimestamp', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final clientTs = DateTime(2026, 3, 30, 10, 0);
      // Server last-modified is OLDER than client (client would normally win for content)
      // but structural always server-wins.
      final serverTs = DateTime(2026, 3, 30, 9, 0);

      await insertPendingOp(
        db,
        type: 'ADD_TO_LIST',
        payload: {'taskId': 'task_1', 'listId': 'list_A'},
        clientTimestamp: clientTs,
      );

      final manager = container.read(syncManagerProvider.notifier);

      int applyCount = 0;

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': serverTs.toIso8601String(),
          'listId': 'list_B', // server has different list
        },
        applyOperation: (type, payload) async {
          applyCount++;
        },
      );

      // ADD_TO_LIST is structural → server wins → operation dropped, not applied.
      expect(applyCount, 0);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.outcome, ConflictResolutionOutcome.serverWins);
    });

    test('MOVE_TO_LIST: server wins unconditionally', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await insertPendingOp(
        db,
        type: 'MOVE_TO_LIST',
        payload: {'taskId': 'task_2', 'listId': 'list_B'},
        clientTimestamp: DateTime(2026, 3, 30, 12, 0),
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': DateTime(2026, 3, 30, 11, 0).toIso8601String(),
        },
        applyOperation: (_, __) async => applyCount++,
      );

      expect(applyCount, 0);
      expect(conflicts.first.outcome, ConflictResolutionOutcome.serverWins);
    });

    test('ASSIGN_TASK: server wins unconditionally', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await insertPendingOp(
        db,
        type: 'ASSIGN_TASK',
        payload: {'taskId': 'task_3', 'assigneeId': 'user_X'},
        clientTimestamp: DateTime(2026, 3, 30, 12, 0),
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': DateTime(2026, 3, 29).toIso8601String(),
        },
        applyOperation: (_, __) async => applyCount++,
      );

      expect(applyCount, 0);
      expect(conflicts.first.outcome, ConflictResolutionOutcome.serverWins);
    });
  });

  // ── Conflict resolution: content props — client wins if newer ────────────────

  group('SyncManager — content properties: client wins when newer', () {
    test('UPDATE_TASK (title): client wins when clientTimestamp is newer', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final clientTs = DateTime(2026, 3, 30, 12, 0);
      final serverTs = DateTime(2026, 3, 30, 10, 0); // server is older

      await insertPendingOp(
        db,
        type: 'UPDATE_TASK',
        payload: {'taskId': 'task_4', 'title': 'Client title'},
        clientTimestamp: clientTs,
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': serverTs.toIso8601String(),
          'title': 'Server title',
        },
        applyOperation: (_, __) async => applyCount++,
      );

      // Client is newer → client wins → operation applied.
      expect(applyCount, 1);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.outcome, ConflictResolutionOutcome.clientWins);
    });

    test('UPDATE_TASK (notes): client wins when clientTimestamp is newer', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await insertPendingOp(
        db,
        type: 'UPDATE_TASK',
        payload: {'taskId': 'task_5', 'notes': 'Client notes'},
        clientTimestamp: DateTime(2026, 3, 30, 14, 0),
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': DateTime(2026, 3, 30, 13, 0).toIso8601String(),
        },
        applyOperation: (_, __) async => applyCount++,
      );

      expect(applyCount, 1);
    });
  });

  // ── Conflict resolution: content props — server wins if newer ────────────────

  group('SyncManager — content properties: server wins when newer', () {
    test('UPDATE_TASK (title): server wins when server timestamp is newer', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final clientTs = DateTime(2026, 3, 30, 10, 0);
      final serverTs = DateTime(2026, 3, 30, 12, 0); // server is newer

      await insertPendingOp(
        db,
        type: 'UPDATE_TASK',
        payload: {'taskId': 'task_6', 'title': 'Client title (stale)'},
        clientTimestamp: clientTs,
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': serverTs.toIso8601String(),
        },
        applyOperation: (_, __) async => applyCount++,
      );

      // Server is newer → server wins → operation dropped.
      expect(applyCount, 0);
      expect(conflicts.first.outcome, ConflictResolutionOutcome.serverWins);
    });
  });

  // ── No conflict — no message ──────────────────────────────────────────────────

  group('SyncManager — no conflict', () {
    test('returns empty conflict list when no conflicts detected', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final ts = DateTime(2026, 3, 30, 12, 0);

      await insertPendingOp(
        db,
        type: 'UPDATE_TASK',
        payload: {'taskId': 'task_7', 'title': 'Clean update'},
        clientTimestamp: ts,
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        // Same timestamp → no conflict.
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': ts.toIso8601String(),
        },
        applyOperation: (_, __) async => applyCount++,
      );

      // Same timestamp = noConflict → still applies cleanly.
      expect(applyCount, 1);
      // noConflict outcomes are NOT added to the conflicts list.
      expect(conflicts, isEmpty);
    });

    test('returns empty list when pending queue is empty', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final manager = container.read(syncManagerProvider.notifier);

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => null,
        applyOperation: (_, __) async {},
      );

      expect(conflicts, isEmpty);
    });
  });

  // ── Entity deleted on server ──────────────────────────────────────────────────

  group('SyncManager — entity deleted on server', () {
    test('drops pending operation when entity no longer exists server-side',
        () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await insertPendingOp(
        db,
        type: 'UPDATE_TASK',
        payload: {'taskId': 'deleted_task'},
        clientTimestamp: DateTime(2026, 3, 30),
      );

      final manager = container.read(syncManagerProvider.notifier);
      int applyCount = 0;

      final conflicts = await manager.processQueue(
        // null = entity doesn't exist on server.
        serverStateResolver: (_, __) async => null,
        applyOperation: (_, __) async => applyCount++,
      );

      expect(applyCount, 0);
      expect(conflicts, isEmpty);

      // Pending operations table should be empty.
      final remaining = await db.select(db.pendingOperations).get();
      expect(remaining, isEmpty);
    });
  });

  // ── Plain-language conflict message contract ───────────────────────────────

  group('SyncManager — conflict message contract', () {
    test('conflicts list is non-empty when conflict detected', () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await insertPendingOp(
        db,
        type: 'ADD_TO_LIST',
        payload: {'taskId': 'task_8', 'listId': 'list_X'},
        clientTimestamp: DateTime(2026, 3, 30, 10),
      );

      final manager = container.read(syncManagerProvider.notifier);

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {
          'lastModifiedAt': DateTime(2026, 3, 30, 9).toIso8601String(),
        },
        applyOperation: (_, __) async {},
      );

      // Non-empty conflicts list → caller should show syncConflictResolvedMessage.
      expect(conflicts.isNotEmpty, isTrue);
    });

    test('conflicts list is empty when no conflict detected — no message needed',
        () async {
      final db = _makeTestDb();
      final container = _makeContainer(db);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // No pending ops → no conflicts.
      final manager = container.read(syncManagerProvider.notifier);

      final conflicts = await manager.processQueue(
        serverStateResolver: (_, __) async => {},
        applyOperation: (_, __) async {},
      );

      expect(conflicts, isEmpty);
    });
  });
}
