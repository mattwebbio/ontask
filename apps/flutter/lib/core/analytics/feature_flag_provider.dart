import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'feature_flag_provider.g.dart';

/// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
///
/// Returns [false] when:
///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
///   - PostHog has not yet evaluated the flag
///   - The flag evaluates to false
///
/// Usage by other features:
///   ```dart
///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
///   final enabled = flagAsync.value ?? false;
///   ```
@riverpod
Future<bool> featureFlag(Ref ref, String flagKey) async {
  if (AppConfig.posthogApiKey.isEmpty) return false;
  try {
    return await Posthog().isFeatureEnabled(flagKey);
  } catch (_) {
    // If PostHog is not initialized or evaluation fails, default to false.
    return false;
  }
}
