import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/scheduling/data/scheduling_repository.dart';
import 'package:ontask/features/scheduling/domain/schedule_explanation.dart';
import 'package:ontask/features/scheduling/presentation/widgets/schedule_explanation_sheet.dart';
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

  Widget buildSheet({required SchedulingRepository repo}) {
    return ProviderScope(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: ScheduleExplanationSheet(taskId: taskId),
        ),
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  group('ScheduleExplanationSheet', () {
    testWidgets('loading state renders CupertinoActivityIndicator', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SlowSchedulingRepository()));
      // Do not pump further — stays in loading state
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    // ── Error state ────────────────────────────────────────────────────────

    testWidgets('error state renders plain-language error message', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _ErrorSchedulingRepository()));
      await tester.pumpAndSettle();
      expect(find.textContaining("Couldn't load explanation"), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    // ── Success state ──────────────────────────────────────────────────────

    testWidgets('success state renders each reason as text', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _FakeSchedulingRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Placed before your due date on Mon, Apr 6'), findsOneWidget);
      expect(find.text('Matched your high-focus preference'), findsOneWidget);
    });

    testWidgets('success state shows sheet title "Why here?"', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _FakeSchedulingRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Why here?'), findsOneWidget);
    });

    testWidgets('success state with empty reasons shows fallback message', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _EmptyReasonsRepository()));
      await tester.pumpAndSettle();
      expect(find.textContaining('No explanation available'), findsOneWidget);
    });

    // ── No technical language ──────────────────────────────────────────────

    testWidgets('reason text uses plain language — no variable names exposed', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _FakeSchedulingRepository()));
      await tester.pumpAndSettle();
      // Verify reasons are plain English strings (no camelCase, no underscores)
      final reasonFinder = find.text('Placed before your due date on Mon, Apr 6');
      expect(reasonFinder, findsOneWidget);
      final text = (tester.widget(reasonFinder) as Text).data!;
      expect(text.contains('_'), isFalse);
      expect(text.contains('isAtRisk'), isFalse);
    });
  });
}

// ── Fake repositories ──────────────────────────────────────────────────────

class _SlowSchedulingRepository extends SchedulingRepository {
  _SlowSchedulingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) =>
      Completer<ScheduleExplanation>().future;
}

class _ErrorSchedulingRepository extends SchedulingRepository {
  _ErrorSchedulingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) async =>
      throw Exception('Network error');
}

class _FakeSchedulingRepository extends SchedulingRepository {
  _FakeSchedulingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) async =>
      const ScheduleExplanation(reasons: [
        'Placed before your due date on Mon, Apr 6',
        'Matched your high-focus preference',
      ]);
}

class _EmptyReasonsRepository extends SchedulingRepository {
  _EmptyReasonsRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) async =>
      const ScheduleExplanation(reasons: []);
}
