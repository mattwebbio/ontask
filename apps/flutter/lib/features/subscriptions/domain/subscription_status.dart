// Domain model for user subscription / trial status.
// Maps to GET /v1/subscriptions/me response.
// No freezed — plain immutable class (consistent with notification_item.dart,
// session_model.dart patterns for simple value objects).
enum SubscriptionState {
  trialing,
  active,
  cancelled,
  expired,
  gracePeriod; // maps to API 'grace_period'

  static SubscriptionState fromJson(String value) => switch (value) {
        'trialing' => trialing,
        'active' => active,
        'cancelled' => cancelled,
        'expired' => expired,
        'grace_period' => gracePeriod,
        _ => expired, // safe default — treat unknown as expired (no access assumption)
      };
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.state,
    this.trialStartedAt,
    this.trialEndsAt,
    this.trialDaysRemaining,
    this.dataRetentionDeadline,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
  });

  final SubscriptionState state;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final int? trialDaysRemaining; // null when not trialing; 0 = expires today
  final DateTime? dataRetentionDeadline; // set after trial expires (FR85)
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;

  bool get isTrialing => state == SubscriptionState.trialing;
  bool get isActive => state == SubscriptionState.active;
  bool get isExpired => state == SubscriptionState.expired;

  /// True when the trial countdown banner should be shown (final 3 days).
  bool get showTrialCountdownBanner =>
      isTrialing && trialDaysRemaining != null && trialDaysRemaining! <= 3;
}
