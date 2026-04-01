import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/nonprofit.dart';
import 'charity_sheet_screen.dart';
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

  // ── Charity selection (Epic 6, Story 6.3) ────────────────────────────────
  Nonprofit? _selectedCharity;

  // ── Stake modification window (FR63, Story 6.6) ───────────────────────────
  DateTime? _modificationDeadline;
  bool _canModify = false;

  @override
  void initState() {
    super.initState();
    _stakeAmountCents = widget.existingStakeAmountCents;
    _checkPaymentMethod();
    _loadDefaultCharity();
    if (widget.existingStakeAmountCents != null) {
      _loadModificationWindow();
    }
  }

  Future<void> _loadModificationWindow() async {
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final stake = await repository.getTaskStake(widget.taskId);
      if (!mounted) return;
      setState(() {
        _modificationDeadline = stake.stakeModificationDeadline;
        _canModify = stake.canModify;
      });
    } catch (e) {
      // Safe fallback: treat as locked on error — prevents accidental modification
      if (mounted) setState(() => _canModify = false);
    }
  }

  String _formatModificationDeadline(DateTime dt) {
    // Format: "Apr 2 at 3:00 PM" — use intl package DateFormat
    final datePart = DateFormat('MMM d').format(dt);
    final timePart = DateFormat('h:mm a').format(dt);
    return '${AppStrings.stakeModificationWindowPrefix} $datePart ${AppStrings.stakeModificationWindowAt} $timePart';
  }

  Future<void> _loadDefaultCharity() async {
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final selection = await repository.getDefaultCharity();
      if (!mounted) return;
      if (selection.charityId != null && selection.charityName != null) {
        setState(() {
          _selectedCharity = Nonprofit(
            id: selection.charityId!,
            name: selection.charityName!,
          );
        });
      }
    } catch (e) {
      // Non-blocking — charity selection is optional. Default to none.
    }
  }

  Future<void> _checkPaymentMethod() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final status = await repository.getPaymentStatus();
      setState(() {
        _hasPaymentMethod = status.hasPaymentMethod;
      });
    } catch (e) {
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
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AppStrings.stakeSetError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCancelStake() async {
    if (!_canModify) return; // Guard: should not be reachable if UI is correct
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(AppStrings.stakeRemoveConfirmTitle),
        content: const Text(AppStrings.stakeRemoveConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.cancelStake(widget.taskId);
      if (mounted) Navigator.pop(context, null);
    } on DioException catch (e) {
      if (!mounted) return;
      final errorCode = e.response?.data?['error']?['code'] as String?;
      final message = errorCode == 'STAKE_LOCKED'
          ? AppStrings.stakeLockedError
          : AppStrings.stakeCancelError;
      await showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text(AppStrings.dialogErrorTitle),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.actionOk),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text(AppStrings.dialogErrorTitle),
          content: const Text(AppStrings.stakeCancelError),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.actionOk),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    // ── Modification window label (FR63, Story 6.6) ──────
                    if (widget.existingStakeAmountCents != null &&
                        _modificationDeadline != null) ...[
                      Text(
                        _formatModificationDeadline(_modificationDeadline!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // ── Stake slider ─────────────────────────────────────
                    // When locked, wrap in IgnorePointer + Opacity
                    if (widget.existingStakeAmountCents != null && !_canModify)
                      IgnorePointer(
                        ignoring: true,
                        child: Opacity(
                          opacity: 0.5,
                          child: StakeSliderWidget(
                            stakeAmountCents: _stakeAmountCents,
                            onChanged: (cents) {
                              setState(() => _stakeAmountCents = cents);
                            },
                            onConfirm: null,
                          ),
                        ),
                      )
                    else
                      StakeSliderWidget(
                        stakeAmountCents: _stakeAmountCents,
                        onChanged: (cents) {
                          setState(() => _stakeAmountCents = cents);
                        },
                        onConfirm: _isLoading ? null : _onConfirm,
                      ),

                    // ── Locked message (FR63, Story 6.6) ─────────────────
                    if (widget.existingStakeAmountCents != null && !_canModify) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.stakeLockedMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                      ),
                    ],

                    // ── Charity selection (Epic 6, Story 6.3) ────────────
                    const SizedBox(height: AppSpacing.md),
                    _selectedCharity == null
                        ? CupertinoButton(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final selected =
                                  await showCupertinoModalPopup<Nonprofit?>(
                                context: context,
                                builder: (_) => CharitySheetScreen(
                                  currentCharityId: _selectedCharity?.id,
                                ),
                              );
                              if (selected != null) {
                                setState(() => _selectedCharity = selected);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.heart,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  AppStrings.charitySelectCta,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final selected =
                                  await showCupertinoModalPopup<Nonprofit?>(
                                context: context,
                                builder: (_) => CharitySheetScreen(
                                  currentCharityId: _selectedCharity?.id,
                                ),
                              );
                              if (selected != null) {
                                setState(() => _selectedCharity = selected);
                              }
                            },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    color: colors.accentPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      _selectedCharity!.name,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    AppStrings.charityChangeCta,
                                    style: TextStyle(
                                      color: colors.accentPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    // ── Remove stake (only if existing stake) ────────────
                    // When locked (!_canModify), show button disabled.
                    // When window open (_canModify), use cancelStake endpoint.
                    // Hide "Lock it in." confirm button when locked.
                    if (widget.existingStakeAmountCents != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      CupertinoButton(
                        minimumSize: const Size(44, 44),
                        color: _canModify
                            ? CupertinoColors.destructiveRed
                            : CupertinoColors.inactiveGray,
                        onPressed: (_isLoading || !_canModify)
                            ? null
                            : _handleCancelStake,
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
