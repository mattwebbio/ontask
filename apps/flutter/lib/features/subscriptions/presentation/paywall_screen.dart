import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import 'subscriptions_provider.dart';

/// Paywall Screen — full-screen route shown when a user's trial has expired.
///
/// Registered as a top-level route (/paywall) outside [StatefulShellRoute],
/// so no shell chrome or tab bar renders over it (FR88, Epic 9, Story 9.2).
///
/// Copy is benefit-focused — no countdown timers, no artificial urgency (FR88).
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read subscription status to confirm expired state (may be AsyncLoading on
    // first render — handled gracefully below).
    // impl(9.2): context.go('/now') after subscription activation — wired in Story 9.3.
    // ignore: unused_local_variable
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return CupertinoPageScaffold(
      // No CupertinoNavigationBar — full-screen standalone paywall experience.
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 24),
            // Headline — benefit-focused, not urgency-driven (FR88).
            Text(
              AppStrings.paywallHeadline,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Subheadline — value proposition.
            Text(
              AppStrings.paywallSubheadline,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Tier cards.
            _TierCard(tier: SubscriptionTier.individual),
            const SizedBox(height: 12),
            _TierCard(tier: SubscriptionTier.couple),
            const SizedBox(height: 12),
            _TierCard(tier: SubscriptionTier.familyAndFriends),
            const SizedBox(height: 24),
            // Restore purchase — plain/borderless style.
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // impl(9.2): Wire restore purchase — deferred to Story 9.3.
              },
              child: Text(
                AppStrings.paywallRestorePurchase,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            // Cancellation terms — honest and clearly readable (FR88).
            Text(
              AppStrings.paywallCancellationTerms,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Subscription tier — UI-only enum local to this file.
///
/// Not a domain model. Tier display data is UI-only until Story 9.3 wires
/// real Stripe Price IDs.
enum SubscriptionTier {
  individual,
  couple,
  familyAndFriends;
}

/// Private tier card widget displayed on the paywall screen.
///
/// Shows tier name, price, a one-line feature description, and a Subscribe CTA.
class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});

  final SubscriptionTier tier;

  String get _name {
    switch (tier) {
      case SubscriptionTier.individual:
        return AppStrings.paywallTierIndividualName;
      case SubscriptionTier.couple:
        return AppStrings.paywallTierCoupleName;
      case SubscriptionTier.familyAndFriends:
        return AppStrings.paywallTierFamilyName;
    }
  }

  String get _price {
    switch (tier) {
      case SubscriptionTier.individual:
        return AppStrings.paywallTierIndividualPrice;
      case SubscriptionTier.couple:
        return AppStrings.paywallTierCouplePrice;
      case SubscriptionTier.familyAndFriends:
        return AppStrings.paywallTierFamilyPrice;
    }
  }

  String get _feature {
    switch (tier) {
      case SubscriptionTier.individual:
        return AppStrings.paywallTierIndividualFeature;
      case SubscriptionTier.couple:
        return AppStrings.paywallTierCoupleFeature;
      case SubscriptionTier.familyAndFriends:
        return AppStrings.paywallTierFamilyFeature;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _price,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _feature,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                // impl(9.2): context.push to ontaskhq.com/subscribe?tier=... via
                //   url_launcher — wired in Story 9.3 when Universal Links are live
                //   (Epic 13 Story 13.1).
              },
              child: Text(AppStrings.paywallSubscribeCta),
            ),
          ),
        ],
      ),
    );
  }
}
