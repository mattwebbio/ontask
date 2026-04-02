import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../data/subscriptions_repository.dart';
import 'subscriptions_provider.dart';

/// Subscription activation callback handler screen.
///
/// Shown when GoRouter handles the Universal Link return from Stripe Checkout:
///   ontaskhq.com/subscribe/success?session_id=xxx
///
/// Registered as a top-level route (/subscribe/success) outside [StatefulShellRoute]
/// so no shell chrome renders during activation processing (Story 9.3, FR83).
class SubscribeSuccessScreen extends ConsumerStatefulWidget {
  const SubscribeSuccessScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SubscribeSuccessScreen> createState() =>
      _SubscribeSuccessScreenState();
}

class _SubscribeSuccessScreenState
    extends ConsumerState<SubscribeSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _activate();
  }

  Future<void> _activate() async {
    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      await repo.activateSubscription(widget.sessionId);
      ref.invalidate(subscriptionStatusProvider);
      if (mounted) context.go('/now');
    } catch (_) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Activation Failed'),
            content: Text(AppStrings.subscriptionActivationError),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  _activate();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      // No CupertinoNavigationBar — transient processing screen.
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
