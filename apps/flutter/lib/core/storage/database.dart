import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pending_operations.dart';

part 'database.g.dart';

/// Application-level drift database.
///
/// Includes the offline-queue [PendingOperations] table (required by ARCH-20).
@DriftDatabase(tables: [PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ontask.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod provider for [AppDatabase].
///
/// keepAlive: true — the database MUST NOT be closed/recreated during the app
/// lifecycle. Disposing it mid-session would corrupt in-flight operations.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
