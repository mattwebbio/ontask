import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// Represents a single authenticated session (device) for the current user.
///
/// [sessionId] — the unique identifier for this session / refresh token slot.
/// [deviceName] — human-readable device name derived from User-Agent.
/// [location] — approximate location string (e.g. "London, UK" or "Unknown location").
/// [lastActiveAt] — ISO 8601 timestamp of the most recent activity.
/// [isCurrentDevice] — `true` when this session matches the current access token.
@freezed
abstract class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String sessionId,
    required String deviceName,
    required String location,
    required DateTime lastActiveAt,
    required bool isCurrentDevice,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
