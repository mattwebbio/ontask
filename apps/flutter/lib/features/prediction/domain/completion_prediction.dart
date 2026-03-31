import 'package:freezed_annotation/freezed_annotation.dart';

part 'completion_prediction.freezed.dart';

/// Status of a predicted completion for a task, section, or list.
enum PredictionStatus { onTrack, atRisk, behind, unknown }

/// Domain model representing a predicted completion for a task, section, or list.
///
/// Returned by [PredictionRepository] and consumed by prediction badge widgets.
@freezed
abstract class CompletionPrediction with _$CompletionPrediction {
  const factory CompletionPrediction({
    required String entityId,
    required DateTime? predictedDate,
    required PredictionStatus status,
    required int tasksRemaining,
    required int estimatedMinutesRemaining,
    required int availableWindowsCount,
    required String reasoning,
  }) = _CompletionPrediction;
}
