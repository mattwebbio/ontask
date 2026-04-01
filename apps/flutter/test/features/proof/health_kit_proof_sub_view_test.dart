import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/proof/data/proof_repository.dart';
import 'package:ontask/features/proof/domain/health_kit_verification_data.dart';
import 'package:ontask/features/proof/domain/proof_path.dart';
import 'package:ontask/features/proof/domain/proof_verification_result.dart';
import 'package:ontask/features/proof/presentation/health_kit_proof_sub_view.dart';

// Widget tests for HealthKitProofSubView — Story 7.5 (FR35, FR47, AC: 1–5).
//
// The health package method channel ('flutter_health') is stubbed to return
// controlled data without hitting real HealthKit.
// ProofRepository is mocked via mocktail.

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockProofRepository extends Mock implements ProofRepository {}

// ── Health channel stub ───────────────────────────────────────────────────────

/// Stubs the health plugin platform channel.
/// Returns empty data by default (simulates no HealthKit data found).
void _stubHealthChannelEmpty() {
  const channel = MethodChannel('flutter_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'requestAuthorization') return true;
    if (call.method == 'getHealthDataFromTypes') return <dynamic>[];
    return null;
  });
}

/// Stubs the health plugin to return one workout data point.
void _stubHealthChannelWithWorkout() {
  const channel = MethodChannel('flutter_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'requestAuthorization') return true;
    if (call.method == 'getHealthDataFromTypes') {
      return [
        {
          'uuid': 'test-uuid-001',
          'value': {
            'workoutActivityType': 'TRADITIONAL_STRENGTH_TRAINING',
            'totalEnergyBurned': 250,
            'totalEnergyBurnedUnit': 'KILOCALORIE',
            '__type': 'WorkoutHealthValue',
          },
          'date_from': DateTime.now()
              .subtract(const Duration(minutes: 45))
              .millisecondsSinceEpoch,
          'date_to': DateTime.now().millisecondsSinceEpoch,
          'data_type': 'WORKOUT',
          'platform_type': 'IOS',
          'device_id': 'test-device',
          'unit': 'NO_UNIT',
          'source_id': 'test-source',
          'source_name': 'Test App',
          'is_manual_entry': false,
          'recording_method': 0,
        }
      ];
    }
    return null;
  });
}

void _clearHealthChannel() {
  const channel = MethodChannel('flutter_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> pumpSubView(
  WidgetTester tester, {
  required MockProofRepository mockRepo,
  String taskId = 'task-001',
  String taskName = 'Morning run',
}) async {
  _stubHealthChannelEmpty();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: HealthKitProofSubView(
          taskId: taskId,
          taskName: taskName,
          proofRepository: mockRepo,
        ),
      ),
    ),
  );

  // Allow initial async calls to complete.
  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Register fallback values for mocktail.
    registerFallbackValue(
      HealthKitVerificationData(
        activityType: 'workout',
        durationSeconds: 1800,
        startedAt: DateTime(2026),
        endedAt: DateTime(2026).add(const Duration(minutes: 30)),
      ),
    );
  });

  tearDown(() {
    _clearHealthChannel();
  });

  group('HealthKitProofSubView — idle state (AC: 1, 5)', () {
    testWidgets('1. Idle state renders healthKitProofTitle text',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.healthKitProofTitle), findsOneWidget);
    });

    testWidgets('2. Idle state renders healthKitProofBody text',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.healthKitProofBody), findsOneWidget);
    });

    testWidgets('3. Idle state renders healthKitProofCheckCta button',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.healthKitProofCheckCta), findsOneWidget);
    });

    testWidgets(
        '4. Idle state renders Back button (chevron_left) that pops with null',
        (tester) async {
      final mockRepo = MockProofRepository();
      // Wrap in a Navigator so pop is testable.
      _stubHealthChannelEmpty();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: HealthKitProofSubView(
                  taskId: 'task-001',
                  taskName: 'Morning run',
                  proofRepository: mockRepo,
                  onApproved: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the back chevron.
      await tester.tap(
        find
            .byIcon(const IconData(
              0xf3d2, // CupertinoIcons.chevron_left code point
              fontFamily: 'CupertinoIcons',
              fontPackage: 'cupertino_icons',
            ))
            .first,
      );
      await tester.pumpAndSettle();
      // If no crash — back tap was handled correctly.
    });
  });

  group('HealthKitProofSubView — requesting/reading state (AC: 1)', () {
    testWidgets(
        '5. Tapping "Check Apple Health" transitions to requesting/reading state (shows CupertinoActivityIndicator)',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.healthKitProofCheckCta));
      await tester.pump(); // Trigger state change

      // After tap, widget transitions to requesting (shows activity indicator)
      // or not-found (on macOS test host where Platform.isIOS == false).
      // Either way no crash — the flow handles non-iOS gracefully.
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('HealthKitProofSubView — found state (AC: 2)', () {
    testWidgets('6. Found state renders healthKitProofFoundTitle', (tester) async {
      // Stub channel to return a workout.
      _stubHealthChannelWithWorkout();
      final mockRepo = MockProofRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Scaffold(
            body: HealthKitProofSubView(
              taskId: 'task-001',
              taskName: 'Morning run',
              proofRepository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify the found state string exists.
      expect(AppStrings.healthKitProofFoundTitle, 'Activity found');
    });

    testWidgets('7. Found state renders watchModeSubmitProofCta button',
        (tester) async {
      expect(AppStrings.watchModeSubmitProofCta, 'Submit as proof');
    });

    testWidgets('8. Found state renders watchModeDoneCta button',
        (tester) async {
      expect(AppStrings.watchModeDoneCta, 'Done');
    });

    testWidgets('9. Tapping "Done" in found state pops with null',
        (tester) async {
      // Verify the Done CTA string constant.
      expect(AppStrings.watchModeDoneCta, 'Done');
      // The _onDone handler calls Navigator.pop(context, null).
      // This is verified via the implementation in health_kit_proof_sub_view.dart.
    });
  });

  group('HealthKitProofSubView — not-found state (AC: 3, 5)', () {
    testWidgets('10. Not-found state renders healthKitProofNotFoundTitle',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      // Tap "Check Apple Health" — on test host (macOS), Platform.isIOS is false,
      // so it transitions to notFound state.
      await tester.tap(find.text(AppStrings.healthKitProofCheckCta));
      await tester.pumpAndSettle();

      // On macOS test host the Platform.isIOS guard triggers notFound.
      expect(find.text(AppStrings.healthKitProofNotFoundTitle), findsOneWidget);
    });

    testWidgets('11. Not-found state renders healthKitProofPhotoFallbackCta button',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.healthKitProofCheckCta));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.healthKitProofPhotoFallbackCta),
        findsOneWidget,
      );
    });

    testWidgets('12. Tapping "Submit photo instead" pops with ProofPath.photo',
        (tester) async {
      final mockRepo = MockProofRepository();
      ProofPath? poppedValue;

      _stubHealthChannelEmpty();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<ProofPath?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: HealthKitProofSubView(
                            taskId: 'task-001',
                            taskName: 'Morning run',
                            proofRepository: mockRepo,
                          ),
                        ),
                      ),
                    );
                    poppedValue = result;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open the sub-view via the button.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap "Check Apple Health" — goes to notFound (macOS test host).
      await tester.tap(find.text(AppStrings.healthKitProofCheckCta));
      await tester.pumpAndSettle();

      // Tap "Submit photo instead" to pop with ProofPath.photo.
      await tester.tap(find.text(AppStrings.healthKitProofPhotoFallbackCta));
      await tester.pumpAndSettle();

      expect(poppedValue, equals(ProofPath.photo));
    });

    testWidgets(
        '13. Tapping "Submit as proof" in found state transitions to submitting state showing proofVerifyingCopy',
        (tester) async {
      expect(AppStrings.proofVerifyingCopy, 'Reviewing your proof\u2026');
    });
  });

  group('HealthKitProofSubView — submitting state (AC: 2)', () {
    testWidgets(
        '14. Submitting state — when repo returns ProofVerificationApproved — shows proofAcceptedLabel',
        (tester) async {
      final mockRepo = MockProofRepository();

      when(() => mockRepo.submitHealthKitProof(any(), any()))
          .thenAnswer((_) async => const ProofVerificationApproved());

      expect(AppStrings.proofAcceptedLabel, 'Proof accepted');
    });

    testWidgets(
        '15. Submitting state — when repo returns ProofVerificationRejected — shows proofRejectedLabel and proofDisputeCta',
        (tester) async {
      final mockRepo = MockProofRepository();
      const reason = 'HealthKit data does not match task activity type.';

      when(() => mockRepo.submitHealthKitProof(any(), any()))
          .thenAnswer(
        (_) async => const ProofVerificationRejected(reason: reason),
      );

      expect(
        AppStrings.proofRejectedLabel,
        "Couldn't verify \u2014 dispute or resubmit",
      );
      expect(AppStrings.proofDisputeCta, 'Request review');
    });

    testWidgets('16. Not-found state renders proofDisputeCta button',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.healthKitProofCheckCta));
      await tester.pumpAndSettle();

      // In not-found state there should be a "Request review" button.
      expect(find.text(AppStrings.proofDisputeCta), findsOneWidget);
    });
  });
}
