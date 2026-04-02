import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../domain/subscription_status.dart';
import 'subscriptions_provider.dart';

/// Settings → Subscription screen.
/// Shows trial status or active subscription details.
/// AC: 2 — FR87: "X days remaining in your free trial"
class SubscriptionSettingsScreen extends ConsumerWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.subscriptionSettingsTitle),
      ),
      child: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text(AppStrings.subscriptionSettingsLoadError),
          ),
          data: (status) => ListView(
            children: [
              const SizedBox(height: 16),
              _StatusSection(status: status),
              // impl(9.2): Add "Subscribe" CTA here (same tiers as PaywallScreen) — wire
              //   in Story 9.3 when ontaskhq.com/subscribe Universal Link is available.
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.isTrialing) {
      final days = status.trialDaysRemaining ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.subscriptionTrialStatusLabel,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(AppStrings.subscriptionTrialDaysRemaining(days)),
            const SizedBox(height: 4),
            // impl(9.1): Display trialEndsAt formatted date for clarity.
          ],
        ),
      );
    }
    if (status.isExpired) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(AppStrings.subscriptionExpiredLabel),
      );
    }
    // impl(9.1): active / grace_period states handled in Stories 9.3–9.5.
    return const SizedBox.shrink();
  }
}
