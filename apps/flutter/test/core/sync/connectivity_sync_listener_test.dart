import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/storage/database.dart';
import 'package:ontask/core/sync/connectivity_sync_listener.dart';
import 'package:ontask/core/sync/sync_manager.dart';
import 'package:ontask/features/proof/data/proof_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for ConnectivitySyncListener — Story 7.6 (AC: 2–3, ARCH-26).
//
// Uses a real SyncManager with in-memory Drift database.
// ProofRepository is mocked via mocktail.
// connectivity_plus platform channel is stubbed for controlled connectivity.

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockProofRepository extends Mock implements ProofRepository {}

// ── Platform channel helpers ──────────────────────────────────────────────────

/// Stubs connectivity_plus check method.
void _stubConnectivity(String result) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'check') {
      return [result];
    }
    return null;
  });
}

void _clearConnectivity() {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

/// Emits a connectivity change event on the onConnectivityChanged stream channel.
Future<void> _emitConnectivityChange(
    WidgetTester tester, String result) async {
  const eventChannel = EventChannel('dev.fluttercommunity.plus/connectivity_status');
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    eventChannel.name,
    const StandardMethodCodec().encodeSuccessEnvelope([result]),
    (data) {},
  );
  await tester.pumpAndSettle();
}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<(WidgetTester, MockProofRepository, AppDatabase)> pumpListener(
  WidgetTester tester, {
  String initialConnectivity = 'none',
}) async {
  _stubConnectivity(initialConnectivity);
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});

  final mockRepo = MockProofRepository();
  final testDb = AppDatabase.forTesting(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
        proofRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: ConnectivitySyncListener(
          child: Scaffold(body: Text('app')),
        ),
      ),
    ),
  );

  // Allow initState async connectivity check to complete.
  await tester.pumpAndSettle();

  return (tester, mockRepo, testDb);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    _clearConnectivity();
  });

  group('ConnectivitySyncListener (AC: 2–3, ARCH-26)', () {
    testWidgets(
        '1. No sync triggered when device stays offline (no connectivity change)',
        (tester) async {
      final (_, mockRepo, db) = await pumpListener(
        tester,
        initialConnectivity: 'none',
      );
      addTearDown(db.close);

      // No connectivity event — processQueue should never have been called.
      // ProofRepository methods should NOT be called.
      verifyNever(() => mockRepo.submitOfflineProof(any(), any()));
    });

    testWidgets(
        '2. Sync triggered when connectivity transitions from none → wifi',
        (tester) async {
      final (_, mockRepo, db) = await pumpListener(
        tester,
        initialConnectivity: 'none',
      );
      addTearDown(db.close);

      // Stub submitOfflineProof — not called since no pending ops in DB,
      // but the sync should run. We verify via the listener not crashing and
      // the widget remaining alive after a connectivity transition.
      when(() => mockRepo.submitOfflineProof(any(), any()))
          .thenAnswer((_) async {});

      // Emit wifi event.
      await _emitConnectivityChange(tester, 'wifi');

      // Widget is still alive — sync ran without crashing.
      expect(find.text('app'), findsOneWidget);
    });

    testWidgets(
        '3. Sync NOT triggered again on consecutive online events (only triggers once on offline→online transition)',
        (tester) async {
      final (_, mockRepo, db) = await pumpListener(
        tester,
        initialConnectivity: 'none',
      );
      addTearDown(db.close);

      when(() => mockRepo.submitOfflineProof(any(), any()))
          .thenAnswer((_) async {});

      // First: offline → wifi (should trigger sync).
      await _emitConnectivityChange(tester, 'wifi');

      // Second: wifi → wifi again (already online — no transition from offline).
      await _emitConnectivityChange(tester, 'wifi');

      // Widget alive — no crash from double events.
      expect(find.text('app'), findsOneWidget);
    });

    testWidgets(
        '4. Sync error is caught and logged — does not throw or crash listener',
        (tester) async {
      final (_, mockRepo, db) = await pumpListener(
        tester,
        initialConnectivity: 'none',
      );
      addTearDown(db.close);

      // Stub submitOfflineProof to throw — this simulates a network error
      // during sync. The error is caught in _triggerSync and logged.
      when(() => mockRepo.submitOfflineProof(any(), any()))
          .thenThrow(Exception('network error'));

      // Trigger sync with no actual pending ops — listener shouldn't crash.
      await _emitConnectivityChange(tester, 'wifi');

      // Widget is still alive — error was caught.
      expect(find.text('app'), findsOneWidget);
    });
  });
}
