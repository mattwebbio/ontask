import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/subscriptions_repository.dart';
import '../domain/subscription_status.dart';

part 'subscriptions_provider.g.dart';

/// Fetches the current user's subscription status.
/// Async provider — callers use AsyncValue pattern.
/// Invalidate when subscription state might have changed (post-payment callback in Story 9.3).
@riverpod
Future<SubscriptionStatus> subscriptionStatus(Ref ref) async {
  final repo = ref.read(subscriptionsRepositoryProvider);
  return repo.getSubscriptionStatus();
}
