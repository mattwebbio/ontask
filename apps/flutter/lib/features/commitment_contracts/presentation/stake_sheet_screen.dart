import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import 'payment_settings_screen.dart';
import 'widgets/stake_slider_widget.dart';

/// Modal bottom sheet for setting or removing a commitment stake on a task.
///
/// Presented via [showCupertinoModalPopup] from [TaskEditInline].
/// Returns the new stake amount in cents on confirm, or null on remove.
///
/// Payment method gate (AC4):
///   - If no payment method: collapses to inline prompt + "Set up payment" CTA.
///   - If payment method: shows [StakeSliderWidget].
class StakeSheetScreen extends ConsumerStatefulWidget {
  const StakeSheetScreen({
    super.key,
    required this.taskId,
    this.existingStakeAmountCents,
  });

  final String taskId;
  final int? existingStakeAmountCents;

  @override
  ConsumerState<StakeSheetScreen> createState() => _StakeSheetScreenState();
}

class _StakeSheetScreenState extends ConsumerState<StakeSheetScreen> {
  bool _isLoading = false;
  bool? _hasPaymentMethod;
  int? _stakeAmountCents;

  @override
  void initState() {
    super.initState();
    _stakeAmountCents = widget.existingStakeAmountCents;
    _checkPaymentMethod();
  }

  Future<void> _checkPaymentMethod() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final status = await repository.getPaymentStatus();
      setState(() {
        _hasPaymentMethod = status.hasPaymentMethod;
      });
    } catch (_) {
      // Default to showing payment gate on error — safe fallback.
      setState(() {
        _hasPaymentMethod = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onConfirm() async {
    final cents = _stakeAmountCents;
    if (cents == null || cents < 500) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.setTaskStake(widget.taskId, cents);
      if (mounted) {
        Navigator.of(context).pop(cents);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final isNoPaymentMethod = e.response?.statusCode == 422;
      _showErrorDialog(
        isNoPaymentMethod
            ? AppStrings.stakePaymentMethodRequired
            : AppStrings.stakeSetError,
      );
    } catch (_) {
      if (mounted) {
        _showErrorDialog(AppStrings.stakeSetError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRemove() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.stakeRemoveConfirmTitle),
        content: const Text(AppStrings.stakeRemoveConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.removeTaskStake(widget.taskId);
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } catch (_) {
      if (mounted) {
        _showErrorDialog(AppStrings.stakeSetError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.dialogErrorTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.actionOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: _isLoading && _hasPaymentMethod == null
            ? const SizedBox(
                height: 120,
                child: Center(child: CupertinoActivityIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sheet drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Sheet title
                  Text(
                    AppStrings.stakeSliderTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_hasPaymentMethod == false) ...[
                    // ── Payment gate ────────────────────────────────────
                    Text(
                      AppStrings.stakePaymentMethodRequired,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CupertinoButton(
                      minimumSize: const Size(44, 44),
                      color: colors.accentPrimary,
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const PaymentSettingsScreen(),
                          ),
                        );
                      },
                      child: const Text(AppStrings.stakeSetupPaymentCta),
                    ),
                  ] else ...[
                    // ── Stake slider ─────────────────────────────────────
                    StakeSliderWidget(
                      stakeAmountCents: _stakeAmountCents,
                      onChanged: (cents) {
                        setState(() => _stakeAmountCents = cents);
                      },
                      onConfirm: _isLoading ? () {} : _onConfirm,
                    ),

                    // ── Remove stake (only if existing stake) ────────────
                    if (widget.existingStakeAmountCents != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      CupertinoButton(
                        minimumSize: const Size(44, 44),
                        color: CupertinoColors.destructiveRed,
                        onPressed: _isLoading ? null : _onRemove,
                        child: const Text(
                          AppStrings.stakeRemoveConfirmTitle,
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                    ],

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
