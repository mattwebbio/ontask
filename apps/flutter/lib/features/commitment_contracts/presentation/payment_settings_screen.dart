import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/commitment_payment_status.dart';
import 'billing_history_screen.dart';

// Deep link handler note (Story 13.1):
// The Universal Link https://ontaskhq.com/payment-setup-complete?sessionToken=xxx is
// registered in AppRouter (/payment-setup-complete route → PaymentSetupCompleteScreen).
// When Stripe SetupIntent completes on web, iOS intercepts the Universal Link and
// the app navigates to PaymentSetupCompleteScreen, which calls confirmSetup(sessionToken)
// and then navigates back to /settings/payments.

/// Settings screen for managing the stored payment method.
///
/// Shown as Settings → Payments. Allows users to:
/// - Set up a payment method (opens ontaskhq.com/setup via url_launcher)
/// - View the stored method (last4 and brand)
/// - Update or remove the stored method
///
/// Removal is blocked if `hasActiveStakes == true` (FR64).
class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  bool _isLoading = false;
  CommitmentPaymentStatus? _status;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final status = await repository.getPaymentStatus();
      setState(() {
        _status = status;
      });
    } catch (_) {
      setState(() {
        _errorMessage = AppStrings.paymentSetupError;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openSetupFlow() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final session = await repository.createSetupSession();
      final setupUrl = session['setupUrl'] as String;
      // After Stripe SetupIntent completes on web, the AASA-registered Universal Link
      // https://ontaskhq.com/payment-setup-complete?sessionToken=xxx returns to the app.
      // AppRouter intercepts it → PaymentSetupCompleteScreen calls confirmSetup(sessionToken).
      await launchUrl(
        Uri.parse(setupUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePaymentMethod() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.paymentRemoveConfirmTitle),
        content: Text(AppStrings.paymentRemoveConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.removePaymentMethod();
      await _loadPaymentStatus();
    } catch (_) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.dialogErrorTitle),
        content: Text(AppStrings.paymentSetupError),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.actionOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.paymentSetupTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: _buildBody(colors),
      ),
    );
  }

  Widget _buildBody(OnTaskColors colors) {
    if (_isLoading && _status == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final status = _status;
    if (status == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: [
        if (!status.hasPaymentMethod) ...[

          // ── No payment method stored ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppStrings.paymentMethodDisplay,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.accentPrimary,
            onPressed: _isLoading ? null : _openSetupFlow,
            child: Text(AppStrings.paymentSetupButton),
          ),
        ] else ...[
          // ── Payment method stored ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppStrings.paymentMethodDisplay,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${status.brand?.toUpperCase() ?? 'Card'} ending in ${status.last4}',
              style: TextStyle(color: colors.textPrimary, fontSize: 17),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.accentPrimary,
            onPressed: _isLoading ? null : _openSetupFlow,
            child: Text(AppStrings.paymentUpdateButton),
          ),
          const SizedBox(height: 12),
          if (!status.hasActiveStakes)
            CupertinoButton(
              minimumSize: const Size(44, 44),
              color: CupertinoColors.destructiveRed,
              onPressed: _isLoading ? null : _removePaymentMethod,
              child: Text(AppStrings.paymentRemoveButton),
            )
          else ...[
            CupertinoButton(
              minimumSize: const Size(44, 44),
              color: CupertinoColors.destructiveRed.withValues(alpha: 0.4),
              onPressed: null,
              child: Text(AppStrings.paymentRemoveButton),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.paymentRemoveBlockedByStakes,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        // ── Billing History row — always visible ──────────────────────────────
        const SizedBox(height: 16),
        CupertinoButton(
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const BillingHistoryScreen(),
              ),
            );
          },
          child: Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                color: colors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.billingHistoryNavLabel,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: colors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
