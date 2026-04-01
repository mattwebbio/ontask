import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, TextTheme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/scheduling_repository.dart';
import '../../domain/nudge_proposal.dart';

/// Bottom sheet for natural language rescheduling of a task (FR14).
///
/// Displays a text input for the user to type a scheduling utterance
/// (e.g. "move to tomorrow morning"). On submit, calls the nudge API
/// and shows a proposal card for confirmation.
///
/// States:
/// - Idle: [CupertinoTextField] + "Suggest" button
/// - Loading: [CupertinoActivityIndicator] centred
/// - Proposal: card with proposedStartTime, proposedEndTime, interpretation
///   → "Apply" (calls confirm endpoint) and "Cancel" (back to input)
/// - Low-confidence: inline warning — user can retry
/// - Error: plain-language error message
///
/// Presentation: use [showModalBottomSheet] with [backgroundColor: transparent]
/// and pass this widget as the builder.
class NudgeInputSheet extends ConsumerStatefulWidget {
  /// The ID of the task to reschedule.
  final String taskId;

  /// Human-readable task title — displayed in the sheet for context.
  final String taskTitle;

  /// Called after the user confirms the nudge and the change is applied.
  final VoidCallback? onApplied;

  const NudgeInputSheet({
    required this.taskId,
    required this.taskTitle,
    this.onApplied,
    super.key,
  });

  @override
  ConsumerState<NudgeInputSheet> createState() => _NudgeInputSheetState();
}

class _NudgeInputSheetState extends ConsumerState<NudgeInputSheet> {
  final _controller = TextEditingController();

  _SheetState _state = const _SheetIdle();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final utterance = _controller.text.trim();
    if (utterance.isEmpty) return;

    setState(() => _state = const _SheetLoading());

    try {
      final repo = ref.read(schedulingRepositoryProvider);
      final proposal = await repo.proposeNudge(widget.taskId, utterance);

      if (!mounted) return;

      // Low confidence → show inline warning, stay in sheet
      if (proposal.confidence == 'low') {
        setState(() => _state = const _SheetLowConfidence());
        return;
      }

      setState(() => _state = _SheetProposal(proposal));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _SheetError());
    }
  }

  Future<void> _onApply(NudgeProposal proposal) async {
    setState(() => _state = const _SheetLoading());

    try {
      final repo = ref.read(schedulingRepositoryProvider);
      await repo.confirmNudge(widget.taskId, proposal.proposedStartTime);

      if (!mounted) return;

      widget.onApplied?.call();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const _SheetError());
    }
  }

  void _onCancelProposal() {
    setState(() => _state = const _SheetIdle());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sheet handle ───────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Title ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                AppStrings.nudgeSheetTitle,
                style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
              ),
            ),
            // Task title for context
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                widget.taskTitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ── Content ────────────────────────────────────────────────────
            _buildContent(context, colors, textTheme),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OnTaskColors colors,
    TextTheme textTheme,
  ) {
    final state = _state;

    if (state is _SheetLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (state is _SheetProposal) {
      return _buildProposalCard(context, colors, textTheme, state.proposal);
    }

    // Idle, LowConfidence, or Error — show the input form
    return _buildInputForm(context, colors, textTheme, state);
  }

  Widget _buildInputForm(
    BuildContext context,
    OnTaskColors colors,
    TextTheme textTheme,
    _SheetState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            controller: _controller,
            placeholder: "e.g. move to tomorrow morning",
            placeholderStyle: TextStyle(color: colors.textSecondary),
            style: TextStyle(color: colors.textPrimary),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSubmit(),
          ),
          // Inline warning for low confidence
          if (state is _SheetLowConfidence) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.nudgeConfidenceLow,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          // Error message
          if (state is _SheetError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.nudgeError,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CupertinoButton.filled(
            onPressed: _onSubmit,
            child: const Text('Suggest'),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    BuildContext context,
    OnTaskColors colors,
    TextTheme textTheme,
    NudgeProposal proposal,
  ) {
    final startFormatted = _formatDateTime(proposal.proposedStartTime);
    final endFormatted = _formatDateTime(proposal.proposedEndTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Proposal details card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proposal.interpretation,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$startFormatted — $endFormatted',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Apply button
          CupertinoButton.filled(
            onPressed: () => _onApply(proposal),
            child: const Text('Apply'),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Cancel — goes back to input for re-entry
          CupertinoButton(
            onPressed: _onCancelProposal,
            child: Text(
              AppStrings.actionCancel,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? AppStrings.todayTimePm : AppStrings.todayTimeAm;
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    if (minute == 0) return '$displayHour$period';
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }
}

// ── Sheet state sealed classes ────────────────────────────────────────────────

sealed class _SheetState {
  const _SheetState();
}

class _SheetIdle extends _SheetState {
  const _SheetIdle();
}

class _SheetLoading extends _SheetState {
  const _SheetLoading();
}

class _SheetProposal extends _SheetState {
  final NudgeProposal proposal;
  const _SheetProposal(this.proposal);
}

class _SheetLowConfidence extends _SheetState {
  const _SheetLowConfidence();
}

class _SheetError extends _SheetState {
  const _SheetError();
}
