import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/subscription_status.dart';

part 'subscriptions_repository.g.dart';

class SubscriptionsRepository {
  SubscriptionsRepository({required this.apiClient});
  final ApiClient apiClient;

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
