import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import 'subscriptions_provider.dart';

/// Persistent grace period banner — shown when subscription payment has failed.
/// AC: 1 — "Your payment didn't go through — update your payment method to keep access"
///
/// Wrap around tab content in AppShell alongside TrialCountdownBanner.
/// Tap navigates to Settings → Subscription (/settings/subscription).
class GracePeriodBanner extends ConsumerWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        if (!status.isGracePeriod) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/settings/subscription'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: CupertinoColors.systemOrange.withValues(alpha: 0.9),
            child: Text(
              AppStrings.gracePeriodBannerText,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
