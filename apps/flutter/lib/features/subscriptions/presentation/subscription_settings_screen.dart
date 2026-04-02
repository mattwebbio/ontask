import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/strings.dart';
import '../data/subscriptions_repository.dart';
import '../domain/subscription_status.dart';
import 'subscriptions_provider.dart';

/// Settings → Subscription screen.
/// Shows trial status or active subscription details.
/// AC: 2 — FR87: "X days remaining in your free trial"
class SubscriptionSettingsScreen extends ConsumerStatefulWidget {
  const SubscriptionSettingsScreen({super.key});
  @override
  ConsumerState<SubscriptionSettingsScreen> createState() =>
      _SubscriptionSettingsScreenState();
}

class _SubscriptionSettingsScreenState
    extends ConsumerState<SubscriptionSettingsScreen> {
  bool _isCancelling = false;

  Future<void> _onCancelSubscription() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppStrings.subscriptionCancelConfirmTitle),
        content: Text(AppStrings.subscriptionCancelConfirmBody),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.subscriptionCancelConfirmAction),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.subscriptionCancelConfirmDismiss),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      await repo.cancelSubscription();
      ref.invalidate(subscriptionStatusProvider);
    } catch (_) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(AppStrings.subscriptionCancelError),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (status.isExpired) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () async {
                        final uri = Uri.parse('https://ontaskhq.com/subscribe');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: Text(AppStrings.paywallSubscribeCta),
                    ),
                  ),
                ),
              ],
              if (status.isActive) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isCancelling ? null : _onCancelSubscription,
                      child: _isCancelling
                          ? const CupertinoActivityIndicator()
                          : Text(
                              AppStrings.subscriptionCancelConfirmAction,
                              style: const TextStyle(color: CupertinoColors.destructiveRed),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

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
    if (status.isActive) {
      final renewalDate = status.currentPeriodEnd != null
          ? _formatDate(status.currentPeriodEnd!)
          : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.subscriptionActiveStatusLabel,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            if (renewalDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(AppStrings.subscriptionRenewalDate(renewalDate)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () async {
                  final uri = Uri.parse('https://ontaskhq.com/account');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(AppStrings.subscriptionManageCta),
              ),
            ),
          ],
        ),
      );
    }
    if (status.isCancelled) {
      final accessUntilDate = status.currentPeriodEnd != null
          ? _formatDate(status.currentPeriodEnd!)
          : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.subscriptionCancelledStatusLabel,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            if (accessUntilDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(AppStrings.subscriptionActiveUntil(accessUntilDate)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () async {
                  final uri = Uri.parse('https://ontaskhq.com/account');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(AppStrings.subscriptionReactivateCta),
              ),
            ),
          ],
        ),
      );
    }
    if (status.isGracePeriod) {
      final accessUntilDate = status.currentPeriodEnd != null
          ? _formatDate(status.currentPeriodEnd!)
          : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.subscriptionGracePeriodStatusLabel,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(AppStrings.subscriptionGracePeriodBody),
            if (accessUntilDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(AppStrings.subscriptionGracePeriodAccessUntil(accessUntilDate)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () async {
                  final uri = Uri.parse('https://ontaskhq.com/account');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(AppStrings.subscriptionGracePeriodUpdateCta),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
