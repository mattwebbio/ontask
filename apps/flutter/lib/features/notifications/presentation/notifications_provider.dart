import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/notifications_repository.dart';

part 'notifications_provider.g.dart';

/// Triggers push permission request and device token registration.
/// Called once post-auth. Result is AsyncValue<void> — callers ignore the
/// value but can check for errors.
@riverpod
Future<void> registerDeviceToken(Ref ref) async {
  final repo = ref.read(notificationsRepositoryProvider);
  await repo.requestPermissionAndRegisterToken();
}
