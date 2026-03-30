import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'analytics_service.g.dart';

/// Thin wrapper over the PostHog Flutter SDK that enforces a PII-free event
/// contract (ARCH-30, NFR-S1, AC #3).
///
/// All methods are no-ops when [AppConfig.posthogApiKey] is empty — prevents
/// test pollution and local dev noise without requiring mock setup.
///
/// **PII prohibition**: PostHog events must NEVER carry user name, email,
/// phone number, Stripe customer ID, payment method details, or card
/// information. Allowed properties: anonymous user ID (UUID from users.id),
/// event-specific metadata (e.g. stake_amount_cents, task_id), app version,
/// platform.
class AnalyticsService {
  const AnalyticsService();

  /// Whether analytics calls are active. Exposed for testing only.
  @visibleForTesting
  bool get isEnabled => AppConfig.posthogApiKey.isNotEmpty;

  /// Capture a business event with optional PII-free properties.
  ///
  /// [event] — event name (e.g. 'task_completed', 'stake_set').
  /// [properties] — must not include name, email, or payment details.
  void track(String event, {Map<String, Object> properties = const {}}) {
    if (!isEnabled) return;
    Posthog().capture(eventName: event, properties: properties);
  }

  /// Associate the current session with a user UUID (no PII).
  ///
  /// [userId] — must be the UUID from users.id (never email or name).
  /// Call only after a successful login.
  void identify(String userId) {
    if (!isEnabled) return;
    // Pass only userId — no email, no name, no payment details.
    Posthog().identify(userId: userId);
  }

  /// Reset the current PostHog session. Call on sign-out so session data
  /// is not mixed across users.
  void reset() {
    if (!isEnabled) return;
    Posthog().reset();
  }
}

/// Singleton [AnalyticsService] provider.
///
/// Uses [keepAlive: true] so the service persists across navigation and
/// survives provider container refreshes triggered by auth state changes.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return const AnalyticsService();
}
