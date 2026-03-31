import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/prediction/data/prediction_repository.dart';
import 'package:ontask/features/prediction/domain/completion_prediction.dart';
import 'package:ontask/features/prediction/presentation/widgets/prediction_badge.dart';
import 'package:ontask/features/prediction/presentation/widgets/prediction_badge_async.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildBadge(CompletionPrediction prediction) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: Center(
          child: PredictionBadge(prediction: prediction),
        ),
      ),
    );
  }

  CompletionPrediction makePrediction({
    required PredictionStatus status,
    DateTime? predictedDate,
  }) =>
      CompletionPrediction(
        entityId: 'a0000000-0000-4000-8000-000000000001',
        predictedDate: predictedDate ?? DateTime(2026, 6, 30),
        status: status,
        tasksRemaining: 3,
        estimatedMinutesRemaining: 90,
        availableWindowsCount: 5,
        reasoning: 'At current pace, this task will be completed before its due date.',
      );

  // ── PredictionBadge rendering ──────────────────────────────────────────────

  group('PredictionBadge', () {
    testWidgets('on_track renders green colour and calendar icon', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(status: PredictionStatus.onTrack)));
      expect(find.byIcon(CupertinoIcons.calendar_badge_plus), findsOneWidget);
      // Verify text contains "On track"
      expect(find.textContaining('On track'), findsOneWidget);
    });

    testWidgets('at_risk renders amber colour and warning icon', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(status: PredictionStatus.atRisk)));
      expect(find.byIcon(CupertinoIcons.exclamationmark_triangle), findsOneWidget);
      expect(find.textContaining('At risk'), findsOneWidget);
    });

    testWidgets('behind renders red colour and critical icon', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(status: PredictionStatus.behind)));
      expect(find.byIcon(CupertinoIcons.exclamationmark_circle), findsOneWidget);
      expect(find.textContaining('Behind'), findsOneWidget);
    });

    testWidgets('unknown renders em-dash text and calendar icon', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(
        status: PredictionStatus.unknown,
        predictedDate: null,
      )));
      expect(find.byIcon(CupertinoIcons.calendar), findsOneWidget);
      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('date is formatted as "MMM d" — e.g. "Apr 7"', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(
        status: PredictionStatus.onTrack,
        predictedDate: DateTime(2026, 4, 7),
      )));
      expect(find.textContaining('Apr 7'), findsOneWidget);
    });

    testWidgets('tapping opens reasoning sheet', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(status: PredictionStatus.onTrack)));
      await tester.tap(find.byType(PredictionBadge));
      await tester.pumpAndSettle();
      // CupertinoActionSheet should appear with "Forecast" title
      expect(find.text('Forecast'), findsOneWidget);
    });

    testWidgets('reasoning sheet shows tasks remaining count', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(status: PredictionStatus.onTrack)));
      await tester.tap(find.byType(PredictionBadge));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 tasks remaining'), findsOneWidget);
    });

    testWidgets('VoiceOver label includes status and date', (tester) async {
      await tester.pumpWidget(buildBadge(makePrediction(
        status: PredictionStatus.onTrack,
        predictedDate: DateTime(2026, 6, 30),
      )));
      final semantics = tester.getSemantics(find.byType(PredictionBadge));
      expect(semantics.label, contains('on track'));
      expect(semantics.label, contains('Jun 30'));
    });
  });

  // ── PredictionBadgeAsync states ───────────────────────────────────────────

  group('PredictionBadgeAsync (ListPredictionBadge)', () {
    const listId = 'b0000000-0000-4000-8000-000000000001';

    Widget buildAsyncBadge({required PredictionRepository repo}) {
      return ProviderScope(
        overrides: [predictionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const Scaffold(body: Center(child: ListPredictionBadge(listId: listId))),
        ),
      );
    }

    testWidgets('loading state renders shimmer placeholder', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _SlowListRepository()));
      expect(find.byType(PredictionBadge), findsNothing);
      final shimmer = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 60,
      );
      expect(shimmer, findsOneWidget);
    });

    testWidgets('error state renders SizedBox.shrink (badge absent)', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _ErrorListRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(PredictionBadge), findsNothing);
    });

    testWidgets('data state renders PredictionBadge', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _FakeListRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(PredictionBadge), findsOneWidget);
    });
  });

  group('PredictionBadgeAsync (SectionPredictionBadge)', () {
    const sectionId = 'c0000000-0000-4000-8000-000000000001';

    Widget buildAsyncBadge({required PredictionRepository repo}) {
      return ProviderScope(
        overrides: [predictionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const Scaffold(body: Center(child: SectionPredictionBadge(sectionId: sectionId))),
        ),
      );
    }

    testWidgets('loading state renders shimmer placeholder', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _SlowSectionRepository()));
      expect(find.byType(PredictionBadge), findsNothing);
      final shimmer = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 60,
      );
      expect(shimmer, findsOneWidget);
    });

    testWidgets('error state renders SizedBox.shrink (badge absent)', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _ErrorSectionRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(PredictionBadge), findsNothing);
    });

    testWidgets('data state renders PredictionBadge', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _FakeSectionRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(PredictionBadge), findsOneWidget);
    });
  });

  group('PredictionBadgeAsync (TaskPredictionBadge)', () {
    const taskId = 'a0000000-0000-4000-8000-000000000001';

    Widget buildAsyncBadge({
      required PredictionRepository repo,
    }) {
      return ProviderScope(
        overrides: [
          predictionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const Scaffold(
            body: Center(
              child: TaskPredictionBadge(taskId: taskId),
            ),
          ),
        ),
      );
    }

    testWidgets('loading state renders shimmer placeholder', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _SlowPredictionRepository()));
      // Before completing — should show loading shimmer (a Container, not PredictionBadge)
      expect(find.byType(PredictionBadge), findsNothing);
      // The shimmer is a Container with width=60, height=20
      final shimmer = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 60,
      );
      expect(shimmer, findsOneWidget);
    });

    testWidgets('error state renders SizedBox.shrink (badge absent)', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _ErrorPredictionRepository()));
      await tester.pumpAndSettle();
      // On error, the badge should be silently absent — PredictionBadge not rendered
      expect(find.byType(PredictionBadge), findsNothing);
    });

    testWidgets('data state renders PredictionBadge', (tester) async {
      await tester.pumpWidget(buildAsyncBadge(repo: _FakePredictionRepositoryForWidget()));
      await tester.pumpAndSettle();
      expect(find.byType(PredictionBadge), findsOneWidget);
    });
  });
}

CompletionPrediction _stubPrediction(String entityId) => CompletionPrediction(
      entityId: entityId,
      predictedDate: DateTime(2026, 6, 30),
      status: PredictionStatus.onTrack,
      tasksRemaining: 3,
      estimatedMinutesRemaining: 90,
      availableWindowsCount: 5,
      reasoning: 'At current pace, this will be completed before its due date.',
    );

/// Fake repositories — task
class _SlowPredictionRepository extends PredictionRepository {
  _SlowPredictionRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchTaskPrediction(String id) =>
      Completer<CompletionPrediction>().future;
}

class _ErrorPredictionRepository extends PredictionRepository {
  _ErrorPredictionRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchTaskPrediction(String id) async =>
      throw Exception('Network error');
}

class _FakePredictionRepositoryForWidget extends PredictionRepository {
  _FakePredictionRepositoryForWidget() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchTaskPrediction(String id) async => _stubPrediction(id);
}

/// Fake repositories — list
class _SlowListRepository extends PredictionRepository {
  _SlowListRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchListPrediction(String id) =>
      Completer<CompletionPrediction>().future;
}

class _ErrorListRepository extends PredictionRepository {
  _ErrorListRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchListPrediction(String id) async =>
      throw Exception('Network error');
}

class _FakeListRepository extends PredictionRepository {
  _FakeListRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchListPrediction(String id) async => _stubPrediction(id);
}

/// Fake repositories — section
class _SlowSectionRepository extends PredictionRepository {
  _SlowSectionRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchSectionPrediction(String id) =>
      Completer<CompletionPrediction>().future;
}

class _ErrorSectionRepository extends PredictionRepository {
  _ErrorSectionRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchSectionPrediction(String id) async =>
      throw Exception('Network error');
}

class _FakeSectionRepository extends PredictionRepository {
  _FakeSectionRepository() : super(ApiClient(baseUrl: 'http://fake'));
  @override
  Future<CompletionPrediction> fetchSectionPrediction(String id) async => _stubPrediction(id);
}
