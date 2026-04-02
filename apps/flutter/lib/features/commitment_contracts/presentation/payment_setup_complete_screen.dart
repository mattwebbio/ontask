import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../data/commitment_contracts_repository.dart';

/// Payment method setup callback handler screen.
///
/// Shown when GoRouter handles the Universal Link return from Stripe:
///   ontaskhq.com/payment-setup-complete?sessionToken=xxx
///
/// Registered as a top-level route (/payment-setup-complete) outside
/// [StatefulShellRoute] so no shell chrome renders during processing.
///
/// Flow:
/// 1. Validates [sessionToken] is non-empty (guard against malformed deep link)
/// 2. Calls [CommitmentContractsRepository.confirmSetup] with the session token
/// 3. On success: navigates back to Settings → Payments
/// 4. On error: shows error dialog with retry option
///
/// Story 13.1 — replaces the TODO(impl) stub from Story 6.1.
class PaymentSetupCompleteScreen extends ConsumerStatefulWidget {
  const PaymentSetupCompleteScreen({super.key, required this.sessionToken});

  final String sessionToken;

  @override
  ConsumerState<PaymentSetupCompleteScreen> createState() =>
      _PaymentSetupCompleteScreenState();
}

class _PaymentSetupCompleteScreenState
    extends ConsumerState<PaymentSetupCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // Guard against malformed deep link before attempting any API call.
    if (widget.sessionToken.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showError());
      return;
    }
    _confirm();
  }

  Future<void> _confirm() async {
    try {
      final repo = ref.read(commitmentContractsRepositoryProvider);
      await repo.confirmSetup(widget.sessionToken);
      if (mounted) {
        context.go('/settings/payments');
      }
    } catch (_) {
      if (mounted) {
        _showError();
      }
    }
  }

  void _showError() {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppStrings.dialogErrorTitle),
        content: Text(AppStrings.paymentSetupConfirmError),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.sessionToken.isNotEmpty) {
                _confirm();
              }
            },
            child: const Text('Retry'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/settings/payments');
            },
            child: Text(AppStrings.actionOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No CupertinoNavigationBar — transitional processing screen.
    return const CupertinoPageScaffold(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
