import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/completion_prediction.dart';

part 'completion_prediction_dto.freezed.dart';

/// DTO for prediction API response.
///
/// Handles all three entity-specific ID keys: taskId, listId, sectionId.
/// The [entityId] field is mapped from whichever key is present.
@freezed
abstract class CompletionPredictionDto with _$CompletionPredictionDto {
  const CompletionPredictionDto._();

  const factory CompletionPredictionDto({
    required String entityId,
    String? predictedDate,
    required String status,
    required int tasksRemaining,
    required int estimatedMinutesRemaining,
    required int availableWindowsCount,
    required String reasoning,
  }) = _CompletionPredictionDto;

  /// Constructs a [CompletionPredictionDto] from JSON.
  ///
  /// Accepts any of the three entity ID keys (taskId, listId, sectionId)
  /// by normalising them to [entityId].
  factory CompletionPredictionDto.fromJson(Map<String, dynamic> json) {
    // Normalise entity-specific ID keys to a generic entityId
    final id = (json['taskId'] ?? json['listId'] ?? json['sectionId'] ?? '') as String;
    return CompletionPredictionDto(
      entityId: id,
      predictedDate: json['predictedDate'] as String?,
      status: (json['status'] as String?) ?? 'unknown',
      tasksRemaining: (json['tasksRemaining'] as num?)?.toInt() ?? 0,
      estimatedMinutesRemaining: (json['estimatedMinutesRemaining'] as num?)?.toInt() ?? 0,
      availableWindowsCount: (json['availableWindowsCount'] as num?)?.toInt() ?? 0,
      reasoning: (json['reasoning'] as String?) ?? '',
    );
  }

  /// Converts this DTO to a [CompletionPrediction] domain model.
  CompletionPrediction toDomain() {
    return CompletionPrediction(
      entityId: entityId,
      predictedDate: predictedDate != null ? DateTime.tryParse(predictedDate!) : null,
      status: _parseStatus(status),
      tasksRemaining: tasksRemaining,
      estimatedMinutesRemaining: estimatedMinutesRemaining,
      availableWindowsCount: availableWindowsCount,
      reasoning: reasoning,
    );
  }

  static PredictionStatus _parseStatus(String value) {
    switch (value) {
      case 'on_track':
        return PredictionStatus.onTrack;
      case 'at_risk':
        return PredictionStatus.atRisk;
      case 'behind':
        return PredictionStatus.behind;
      default:
        return PredictionStatus.unknown;
    }
  }
}
