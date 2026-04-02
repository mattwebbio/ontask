import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import 'subscriptions_provider.dart';

/// Persistent trial countdown banner — shown in the final 3 days of trial.
/// AC: 2 — "in the final 3 days, a persistent trial countdown banner appears in the app"
///
/// Wrap around tab content in AppShell. Conditionally visible — renders
/// empty SizedBox when not in final 3-day window.
///
/// Tap navigates to Settings → Subscription (/settings/subscription).
class TrialCountdownBanner extends ConsumerWidget {
  const TrialCountdownBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        if (!status.showTrialCountdownBanner) return const SizedBox.shrink();
        final days = status.trialDaysRemaining ?? 0;
        return GestureDetector(
          onTap: () => context.push('/settings/subscription'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: CupertinoColors.systemYellow.withValues(alpha: 0.85),
            child: Text(
              AppStrings.trialCountdownBannerText(days),
              style: const TextStyle(
                color: CupertinoColors.black,
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
