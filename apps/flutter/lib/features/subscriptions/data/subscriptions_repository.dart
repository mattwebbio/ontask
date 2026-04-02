import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/subscription_status.dart';

part 'subscriptions_repository.g.dart';

class SubscriptionsRepository {
  SubscriptionsRepository({required this.apiClient});
  final ApiClient apiClient;

  /// Activates a subscription from a Stripe Checkout session.
  /// Called when the Universal Link callback is received with session_id (Story 9.3, FR83).
  /// Invalidate [subscriptionStatusProvider] after calling this.
  Future<void> activateSubscription(String sessionId) async {
    await apiClient.dio.post<void>(
      '/v1/subscriptions/activate',
      data: {'sessionId': sessionId},
    );
  }

  /// Restores a previously purchased subscription.
  /// Called from the paywall "Restore purchase" CTA (Story 9.3).
  /// Invalidate [subscriptionStatusProvider] after calling this.
  Future<void> restoreSubscription() async {
    await apiClient.dio.post<void>(
      '/v1/subscriptions/restore',
    );
  }

  /// Cancels the user's subscription at end of the current billing period.
  /// Called from Settings → Subscription cancel CTA (Story 9.4, FR49, FR89).
  /// Access continues until [SubscriptionStatus.currentPeriodEnd].
  /// Invalidate [subscriptionStatusProvider] after calling this.
  Future<void> cancelSubscription() async {
    await apiClient.dio.post<void>(
      '/v1/subscriptions/cancel',
    );
  }

  /// Fetches the current user's subscription status.
  /// AC: 2 — feeds SubscriptionSettingsScreen and trial countdown banner.
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/v1/subscriptions/me',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return SubscriptionStatus(
      state: SubscriptionState.fromJson(data['status'] as String),
      trialStartedAt: data['trialStartedAt'] != null
          ? DateTime.parse(data['trialStartedAt'] as String)
          : null,
      trialEndsAt: data['trialEndsAt'] != null
          ? DateTime.parse(data['trialEndsAt'] as String)
          : null,
      trialDaysRemaining: data['trialDaysRemaining'] as int?,
      dataRetentionDeadline: data['dataRetentionDeadline'] != null
          ? DateTime.parse(data['dataRetentionDeadline'] as String)
          : null,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      currentPeriodEnd: data['currentPeriodEnd'] != null
          ? DateTime.parse(data['currentPeriodEnd'] as String)
          : null,
    );
  }
}

@riverpod
SubscriptionsRepository subscriptionsRepository(Ref ref) {
  return SubscriptionsRepository(apiClient: ref.read(apiClientProvider));
}
