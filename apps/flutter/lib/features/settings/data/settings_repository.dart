import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/session_model.dart';

part 'settings_repository.g.dart';

/// Repository for Settings-related API calls.
///
/// Covers FR91: active session listing and per-session revocation.
///
/// ARCH RULE: Always injected via Riverpod — never instantiated directly.
/// Use `ref.watch(settingsRepositoryProvider)` in providers.
class SettingsRepository {
  const SettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches the list of active sessions for the authenticated user.
  ///
  /// `GET /v1/auth/sessions`
  /// Returns each session with `sessionId`, `deviceName`, `location`,
  /// `lastActiveAt`, and `isCurrentDevice`.
  Future<List<SessionModel>> getSessions() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/v1/auth/sessions',
    );
    final data = response.data;
    if (data == null) return [];
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Revokes (deletes) the refresh token for the given [sessionId].
  ///
  /// `DELETE /v1/auth/sessions/:sessionId`
  /// Returns normally on success (204 No Content).
  /// Throws [DioException] on error (403 self-lockout, 404 not found).
  Future<void> deleteSession(String sessionId) async {
    await _apiClient.dio.delete<void>('/v1/auth/sessions/$sessionId');
  }
}

/// Riverpod provider for [SettingsRepository].
///
/// Every consumer must use this — never construct [SettingsRepository] directly.
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SettingsRepository(client);
}

/// Riverpod provider that loads the active sessions list.
///
/// Exposes `AsyncValue<List<SessionModel>>` — use `.when(...)` in widgets.
@riverpod
Future<List<SessionModel>> activeSessions(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSessions();
}
