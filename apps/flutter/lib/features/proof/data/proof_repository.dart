import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/proof_verification_result.dart';

/// Data layer for proof submission operations.
///
/// Constructor takes [ApiClient] via injection — consistent with
/// [SharingRepository] and other data layer classes in this project.
/// Do NOT use Riverpod code-gen for this repository (no generated
/// providers in the proof/ feature).
/// (Epic 7, Stories 7.2–7.3, FR31-32, FR36)
class ProofRepository {
  ProofRepository(this._client);

  final ApiClient _client;

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
}
