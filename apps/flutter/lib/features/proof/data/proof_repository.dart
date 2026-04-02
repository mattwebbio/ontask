import 'dart:convert' show jsonEncode;

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/database.dart';
import '../../../features/watch_mode/domain/watch_mode_session.dart';
import '../domain/health_kit_verification_data.dart';
import '../domain/proof_verification_result.dart';

part 'proof_repository.g.dart';

/// Data layer for proof submission operations.
///
/// Constructor takes [ApiClient] and [AppDatabase] via injection — consistent
/// with [SharingRepository] and other data layer classes in this project.
/// (Epic 7, Stories 7.2–7.8, FR31-32, FR35-36, FR37, FR38, FR39, ARCH-26)
class ProofRepository {
  ProofRepository(this._client, this._db);

  final ApiClient _client;
  final AppDatabase _db;

  /// Submits a captured photo to the API for AI verification.
  ///
  /// Posts `multipart/form-data` with the media file to
  /// `POST /v1/tasks/{taskId}/proof`.
  ///
  /// Returns [ProofVerificationApproved] on success, [ProofVerificationRejected]
  /// with the API-provided reason on failure, or [ProofVerificationError]
  /// on network/unexpected errors.
  Future<ProofVerificationResult> submitPhotoProof(
    String taskId,
    XFile mediaFile,
  ) async {
    try {
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          mediaFile.path,
          filename: mediaFile.name,
        ),
      });

      final response = await _client.dio.post<Map<String, dynamic>>(
        '/v1/tasks/$taskId/proof',
        data: formData,
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final verified = data['verified'] as bool;
      final reason = data['reason'] as String?;

      if (verified) {
        return const ProofVerificationApproved();
      } else {
        return ProofVerificationRejected(
          reason: reason ?? 'Proof could not be verified.',
        );
      }
    } on DioException catch (e) {
      return ProofVerificationError(
        message: e.message ?? 'Network error during proof submission.',
      );
    } catch (e) {
      return ProofVerificationError(
        message: 'Unexpected error during proof submission.',
      );
    }
  }

  /// Submits Watch Mode session data to the API for verification.
  ///
  /// Posts a JSON body (NOT multipart) to `POST /v1/tasks/{taskId}/proof`
  /// with `proofType=watchMode` query param.
  ///
  /// Returns [ProofVerificationApproved] on success, [ProofVerificationRejected]
  /// with the API-provided reason on failure, or [ProofVerificationError]
  /// on network/unexpected errors.
  /// (Epic 7, Story 7.4, FR66-67)
  Future<ProofVerificationResult> submitWatchModeProof(
    String taskId,
    WatchModeSession session,
  ) async {
    try {
      final body = {
        'durationSeconds': session.elapsed.inSeconds,
        'activityPercentage': session.activityPercentage,
      };

      final response = await _client.dio.post<Map<String, dynamic>>(
        '/v1/tasks/$taskId/proof',
        data: body,
        queryParameters: {'proofType': 'watchMode'},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final verified = data['verified'] as bool;
      final reason = data['reason'] as String?;

      if (verified) {
        return const ProofVerificationApproved();
      } else {
        return ProofVerificationRejected(
          reason: reason ?? 'Session could not be verified.',
        );
      }
    } on DioException catch (e) {
      return ProofVerificationError(
        message: e.message ?? 'Network error during session submission.',
      );
    } catch (e) {
      return ProofVerificationError(
        message: 'Unexpected error during session submission.',
      );
    }
  }

  /// Submits HealthKit activity data to the API for auto-verification.
  ///
  /// Posts a JSON body to `POST /v1/tasks/{taskId}/proof` with
  /// `proofType=healthKit` query param.
  ///
  /// Returns [ProofVerificationApproved] on success, [ProofVerificationRejected]
  /// with the API-provided reason on failure, or [ProofVerificationError]
  /// on network/unexpected errors.
  /// (Epic 7, Story 7.5, FR35, FR47)
  Future<ProofVerificationResult> submitHealthKitProof(
    String taskId,
    HealthKitVerificationData data,
  ) async {
    try {
      final body = {
        'activityType': data.activityType,
        'durationSeconds': data.durationSeconds,
        'startedAt': data.startedAt.toIso8601String(),
        'endedAt': data.endedAt.toIso8601String(),
        'calorie': data.calories,
      };

      final response = await _client.dio.post<Map<String, dynamic>>(
        '/v1/tasks/$taskId/proof',
        data: body,
        queryParameters: {'proofType': 'healthKit'},
      );

      final responseData = response.data!['data'] as Map<String, dynamic>;
      final verified = responseData['verified'] as bool;
      final reason = responseData['reason'] as String?;

      if (verified) {
        return const ProofVerificationApproved();
      } else {
        return ProofVerificationRejected(
          reason: reason ?? 'HealthKit data could not be verified.',
        );
      }
    } on DioException catch (e) {
      return ProofVerificationError(
        message: e.message ?? 'Network error during HealthKit proof submission.',
      );
    } catch (e) {
      return ProofVerificationError(
        message: 'Unexpected error during HealthKit proof submission.',
      );
    }
  }

  /// Submits a screenshot or document file to the API for AI verification.
  ///
  /// Supports PNG, JPG, and PDF files up to 25 MB (FR36).
  /// Posts `multipart/form-data` with the media file to
  /// `POST /v1/tasks/{taskId}/proof` — same unified endpoint as photo proof.
  ///
  /// Returns [ProofVerificationApproved] on success, [ProofVerificationRejected]
  /// with the API-provided reason on failure, or [ProofVerificationError]
  /// on network/unexpected errors.
  /// (Epic 7, Story 7.3, FR36)
  Future<ProofVerificationResult> submitScreenshotProof(
    String taskId,
    XFile mediaFile,
  ) async {
    try {
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          mediaFile.path,
          filename: mediaFile.name,
        ),
      });

      final response = await _client.dio.post<Map<String, dynamic>>(
        '/v1/tasks/$taskId/proof',
        data: formData,
        queryParameters: {'proofType': 'screenshot'},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final verified = data['verified'] as bool;
      final reason = data['reason'] as String?;

      if (verified) {
        return const ProofVerificationApproved();
      } else {
        return ProofVerificationRejected(
          reason: reason ?? 'Proof could not be verified.',
        );
      }
    } on DioException catch (e) {
      return ProofVerificationError(
        message: e.message ?? 'Network error during proof submission.',
      );
    } catch (e) {
      return ProofVerificationError(
        message: 'Unexpected error during proof submission.',
      );
    }
  }

  /// Enqueues a proof submission for offline sync.
  ///
  /// Writes a 'SUBMIT_PROOF' pending operation to the local Drift database
  /// with [clientTimestamp] set at the moment of enqueueing — NEVER updated
  /// at sync time (ARCH-26, FR37).
  ///
  /// The [SyncManager] will pick up this operation on reconnect and call
  /// the API via [applyOperation] with the preserved [clientTimestamp].
  Future<void> enqueueOfflineProof(String taskId) async {
    final now = DateTime.now();
    final payload = jsonEncode({
      'taskId': taskId,
      'proofType': 'offline',
      'clientTimestamp': now.toIso8601String(),
    });

    await _db.into(_db.pendingOperations).insert(
      PendingOperationsCompanion.insert(
        type: 'SUBMIT_PROOF',
        payload: payload,
        createdAt: now,
        clientTimestamp: now,
        // status defaults to 'pending' via column default
      ),
    );
  }

  /// Files a dispute against a failed AI verification for the given task.
  ///
  /// Calls POST /v1/tasks/{taskId}/disputes — no-proof-required (FR39).
  /// The stake charge is placed on hold server-side immediately.
  /// On success, the task enters "Under review" state (FR40).
  ///
  /// Throws [DioException] on network failure — callers handle error state.
  Future<void> fileDispute(String taskId) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$taskId/disputes',
    );
  }

  /// Sets the proof retention preference for a submitted task.
  ///
  /// Calls PATCH /v1/tasks/{taskId}/proof-retention with `{ retain: bool }`.
  /// When retain=true, proof media is kept in B2 storage as a completion record (FR38, NFR-R8).
  /// When retain=false, media is scheduled for deletion within 24 hours (FR38).
  ///
  /// Sets proofRetained on the task record server-side.
  Future<void> setProofRetention(String taskId, {required bool retain}) async {
    await _client.dio.patch<void>(
      '/v1/tasks/$taskId/proof-retention',
      data: {'retain': retain},
    );
  }

  /// Submits a previously-queued offline proof to the API during sync.
  ///
  /// Called by [SyncManager.processQueue]'s [applyOperation] callback when
  /// the 'SUBMIT_PROOF' operation type is processed on reconnect.
  ///
  /// The [clientTimestamp] is the original capture time, preserved from the
  /// [PendingOperations] row — not the current time. This ensures the API
  /// receives the timestamp predating the task deadline for charge reversal.
  Future<void> submitOfflineProof(
    String taskId,
    DateTime clientTimestamp,
  ) async {
    final body = {
      'clientTimestamp': clientTimestamp.toIso8601String(),
    };

    await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$taskId/proof',
      data: body,
      queryParameters: {'proofType': 'offline'},
    );
    // Throws DioException on network/server failure — caller (SyncManager)
    // handles retry and status update.
  }
}

/// Provides [ProofRepository] with injected [ApiClient] and [AppDatabase].
///
/// keepAlive: true — proof repository must persist across route transitions.
@Riverpod(keepAlive: true)
ProofRepository proofRepository(Ref ref) {
  final client = ref.read(apiClientProvider);
  final db = ref.read(appDatabaseProvider);
  return ProofRepository(client, db);
}
