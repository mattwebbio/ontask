import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/nudge_proposal.dart';
import '../domain/schedule_explanation.dart';
import 'nudge_proposal_dto.dart';
import 'schedule_explanation_dto.dart';

part 'scheduling_repository.g.dart';

/// Repository for scheduling-related API calls.
///
/// Provides scheduling explanations (FR13) and AI-powered nudge proposals (FR14).
/// Uses [ApiClient] injected via Riverpod — never constructs ApiClient directly.
class SchedulingRepository {
  SchedulingRepository(this._client);
  final ApiClient _client;

  /// Fetches the scheduling explanation for a task.
  ///
  /// Calls `GET /v1/tasks/:taskId/schedule` and extracts the
  /// `explanation` sub-object, mapping it to a [ScheduleExplanation].
  Future<ScheduleExplanation> getScheduleExplanation(String taskId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/$taskId/schedule',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No schedule data for task $taskId');
    }
    final explanationJson = data['explanation'] as Map<String, dynamic>?;
    if (explanationJson == null) {
      throw Exception('No explanation in schedule response for task $taskId');
    }
    return ScheduleExplanationDto.fromJson(explanationJson).toDomain();
  }

  /// Proposes a schedule change using a natural language utterance (FR14).
  ///
  /// Calls `POST /v1/tasks/:taskId/schedule/nudge` with the utterance and
  /// returns a [NudgeProposal] for user confirmation.
  ///
  /// Does NOT apply the change — call [confirmNudge] after user confirms.
  Future<NudgeProposal> proposeNudge(String taskId, String utterance) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$taskId/schedule/nudge',
      data: {'utterance': utterance},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No nudge proposal data for task $taskId');
    }
    return NudgeProposalDto.fromJson(data).toDomain();
  }

  /// Confirms and applies a proposed schedule nudge (FR14).
  ///
  /// Calls `POST /v1/tasks/:taskId/schedule/nudge/confirm` with the proposed
  /// start time, which sets lockedStartTime on the task, re-runs the full
  /// schedule, and syncs the updated block to Google Calendar.
  Future<void> confirmNudge(String taskId, DateTime proposedStartTime) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$taskId/schedule/nudge/confirm',
      data: {'proposedStartTime': proposedStartTime.toIso8601String()},
    );
  }
}

/// Riverpod provider for [SchedulingRepository].
@riverpod
SchedulingRepository schedulingRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SchedulingRepository(client);
}
