import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/scheduling/data/scheduling_repository.dart';
import 'package:ontask/features/scheduling/domain/nudge_proposal.dart';
import 'package:ontask/features/scheduling/domain/schedule_explanation.dart';
import 'package:ontask/features/scheduling/presentation/widgets/nudge_input_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  const taskId = 'a0000000-0000-4000-8000-000000000001';
  const taskTitle = 'Gym session';

  Widget buildSheet({required SchedulingRepository repo}) {
    return ProviderScope(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: NudgeInputSheet(
            taskId: taskId,
            taskTitle: taskTitle,
          ),
        ),
      ),
    );
  }

  group('NudgeInputSheet', () {
    // ── Idle state ────────────────────────────────────────────────────────────

    testWidgets('renders nudge sheet title on initial load', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));
      expect(find.text(AppStrings.nudgeSheetTitle), findsOneWidget);
    });

    testWidgets('renders task title for context', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));
      expect(find.text(taskTitle), findsOneWidget);
    });

    testWidgets('renders text input field', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));
      expect(find.byType(CupertinoTextField), findsOneWidget);
    });

    testWidgets('renders Suggest button', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));
      expect(find.text('Suggest'), findsOneWidget);
    });

    // ── Loading state ─────────────────────────────────────────────────────────

    testWidgets('loading state renders CupertinoActivityIndicator', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SlowNudgeRepository()));

      // Enter some text and tap Suggest
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow');
      await tester.tap(find.text('Suggest'));
      await tester.pump(); // process the tap but not the async response

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNothing);
    });

    // ── Success state ─────────────────────────────────────────────────────────

    testWidgets('success state renders proposal card with interpretation', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNudgeRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow morning');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      expect(find.text('Tomorrow morning at 9 AM'), findsOneWidget);
    });

    testWidgets('success state renders Apply button', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNudgeRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('success state renders Cancel button', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNudgeRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.actionCancel), findsOneWidget);
    });

    testWidgets('Cancel in proposal state returns to input form', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNudgeRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      // In proposal state — tap Cancel
      await tester.tap(find.text(AppStrings.actionCancel));
      await tester.pumpAndSettle();

      // Back to input
      expect(find.byType(CupertinoTextField), findsOneWidget);
    });

    // ── Low confidence state ──────────────────────────────────────────────────

    testWidgets('low-confidence state renders inline warning', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _LowConfidenceRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'maybe sometime idk');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nudgeConfidenceLow), findsOneWidget);
      // Input field remains available for retry
      expect(find.byType(CupertinoTextField), findsOneWidget);
    });

    // ── Error state ───────────────────────────────────────────────────────────

    testWidgets('error state renders plain-language error message', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _ErrorNudgeRepository()));
      await tester.enterText(find.byType(CupertinoTextField), 'move to tomorrow');
      await tester.tap(find.text('Suggest'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nudgeError), findsOneWidget);
      // Input field remains for retry
      expect(find.byType(CupertinoTextField), findsOneWidget);
    });
  });
}

// ── Mock repositories ─────────────────────────────────────────────────────────

class _NeverResolvingRepository extends SchedulingRepository {
  _NeverResolvingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) =>
      Completer<ScheduleExplanation>().future;

  @override
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) =>
      Completer<NudgeProposal>().future;
}

class _SlowNudgeRepository extends SchedulingRepository {
  _SlowNudgeRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) =>
      Completer<NudgeProposal>().future; // never resolves during test
}

class _SuccessNudgeRepository extends SchedulingRepository {
  _SuccessNudgeRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) async =>
      NudgeProposal(
        taskId: taskId,
        proposedStartTime: DateTime(2026, 4, 2, 9, 0),
        proposedEndTime: DateTime(2026, 4, 2, 9, 30),
        interpretation: 'Tomorrow morning at 9 AM',
        confidence: 'high',
      );

  @override
  Future<void> confirmNudge(String taskId, DateTime proposedStartTime) async {}
}

class _LowConfidenceRepository extends SchedulingRepository {
  _LowConfidenceRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) async =>
      NudgeProposal(
        taskId: taskId,
        proposedStartTime: DateTime(2026, 4, 2, 9, 0),
        proposedEndTime: DateTime(2026, 4, 2, 9, 30),
        interpretation: 'Could not resolve clearly',
        confidence: 'low',
      );
}

class _ErrorNudgeRepository extends SchedulingRepository {
  _ErrorNudgeRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) async =>
      throw Exception('Network error');
}
