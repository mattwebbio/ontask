import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/prediction/data/completion_prediction_dto.dart';
import 'package:ontask/features/prediction/data/prediction_repository.dart';
import 'package:ontask/features/prediction/domain/completion_prediction.dart';
import 'package:ontask/features/prediction/presentation/prediction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ── CompletionPredictionDto status conversion ─────────────────────────────

  group('CompletionPredictionDto status conversion', () {
    CompletionPredictionDto _dto(String status) {
      return CompletionPredictionDto.fromJson({
        'taskId': 'a0000000-0000-4000-8000-000000000001',
        'predictedDate': '2026-04-07T12:00:00.000Z',
        'status': status,
        'tasksRemaining': 3,
        'estimatedMinutesRemaining': 90,
        'availableWindowsCount': 5,
        'reasoning': 'Test reasoning.',
      });
    }

    test("'on_track' maps to PredictionStatus.onTrack", () {
      final dto = _dto('on_track');
      expect(dto.toDomain().status, PredictionStatus.onTrack);
    });

    test("'at_risk' maps to PredictionStatus.atRisk", () {
      final dto = _dto('at_risk');
      expect(dto.toDomain().status, PredictionStatus.atRisk);
    });

    test("'behind' maps to PredictionStatus.behind", () {
      final dto = _dto('behind');
      expect(dto.toDomain().status, PredictionStatus.behind);
    });

    test('unknown status string maps to PredictionStatus.unknown', () {
      final dto = _dto('some_unknown_value');
      expect(dto.toDomain().status, PredictionStatus.unknown);
    });

    test('predictedDate is null when API returns null', () {
      final dto = CompletionPredictionDto.fromJson({
        'taskId': 'a0000000-0000-4000-8000-000000000001',
        'predictedDate': null,
        'status': 'unknown',
        'tasksRemaining': 0,
        'estimatedMinutesRemaining': 0,
        'availableWindowsCount': 0,
        'reasoning': 'No data.',
      });
      expect(dto.toDomain().predictedDate, isNull);
    });
  });

  // ── Provider calls repository correctly ────────────────────────────────────

  group('taskPredictionProvider', () {
    test('calls repository with correct taskId', () async {
      const taskId = 'a0000000-0000-4000-8000-000000000001';
      final repo = _FakePredictionRepository();
      final container = ProviderContainer(
        overrides: [
          predictionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskPredictionProvider(taskId).future);
      expect(repo.lastTaskId, taskId);
    });
  });

  group('listPredictionProvider', () {
    test('calls repository with correct listId', () async {
      const listId = 'b0000000-0000-4000-8000-000000000001';
      final repo = _FakePredictionRepository();
      final container = ProviderContainer(
        overrides: [
          predictionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(listPredictionProvider(listId).future);
      expect(repo.lastListId, listId);
    });
  });

  group('sectionPredictionProvider', () {
    test('calls repository with correct sectionId', () async {
      const sectionId = 'c0000000-0000-4000-8000-000000000001';
      final repo = _FakePredictionRepository();
      final container = ProviderContainer(
        overrides: [
          predictionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(sectionPredictionProvider(sectionId).future);
      expect(repo.lastSectionId, sectionId);
    });
  });
}

/// Fake repository that records which IDs were requested.
class _FakePredictionRepository extends PredictionRepository {
  String? lastTaskId;
  String? lastListId;
  String? lastSectionId;

  _FakePredictionRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<CompletionPrediction> fetchTaskPrediction(String taskId) async {
    lastTaskId = taskId;
    return _stubPrediction(taskId);
  }

  @override
  Future<CompletionPrediction> fetchListPrediction(String listId) async {
    lastListId = listId;
    return _stubPrediction(listId);
  }

  @override
  Future<CompletionPrediction> fetchSectionPrediction(String sectionId) async {
    lastSectionId = sectionId;
    return _stubPrediction(sectionId);
  }

  CompletionPrediction _stubPrediction(String entityId) => CompletionPrediction(
        entityId: entityId,
        predictedDate: DateTime(2026, 4, 7),
        status: PredictionStatus.onTrack,
        tasksRemaining: 3,
        estimatedMinutesRemaining: 90,
        availableWindowsCount: 5,
        reasoning: 'At current pace, this will be completed before its due date.',
      );
}
