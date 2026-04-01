import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../now/presentation/widgets/commitment_row.dart';
import 'widgets/commitment_ceremony_card.dart';

/// Full-screen lock confirmation screen shown after the stake is set.
///
/// Presents the [CommitmentCeremonyCard] for the vault-close ceremony (UX-DR20).
/// Navigates to `/chapter-break` after the animation completes.
///
/// Back navigation is disabled via [PopScope] — the commitment ceremony is
/// a point of no return (UX spec line 842: "visual register shift that signals:
/// this is different").
///
/// Router note: accessed via [Navigator.push] from [StakeSheetScreen], not via
/// GoRouter deep link. GoRouter route registration deferred (consistent with
/// Story 6.7 group commitment screens pattern).
///
/// TODO(v2): When a dedicated POST /v1/tasks/:taskId/stake/lock endpoint is
/// added, call it here in [_performLock] before navigating to chapter-break.
class LockConfirmationScreen extends ConsumerStatefulWidget {
  const LockConfirmationScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.stakeAmountCents,
    required this.charityName,
    required this.charityId,
    required this.deadline,
  });

  final String taskId;
  final String taskTitle;
  final int stakeAmountCents;
  final String charityName;
  final String charityId;
  final DateTime deadline;

  @override
  ConsumerState<LockConfirmationScreen> createState() =>
      _LockConfirmationScreenState();
}

class _LockConfirmationScreenState
    extends ConsumerState<LockConfirmationScreen> {
  bool _isLoading = false;

  Future<void> _performLock() async {
    setState(() => _isLoading = true);
    try {
      // setTaskStake already called in StakeSheetScreen — the lock confirmation
      // screen's job is to show the ceremony and navigate to completion.
      // If a separate /lock endpoint is added in a future story, call it here.
      // For now: navigate to chapter-break screen after animation completes.
      if (mounted) {
        context.push('/chapter-break', extra: <String, dynamic>{
          'taskTitle': widget.taskTitle,
          'stakeAmount': CommitmentRow.formatAmount(widget.stakeAmountCents),
        });
      }
    } catch (e) {
      if (mounted) _showErrorDialog(AppStrings.lockConfirmError);
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

    return PopScope(
      canPop: false,
      child: CupertinoPageScaffold(
        backgroundColor: colors.accentCommitment,
        child: SafeArea(
          child: CommitmentCeremonyCard(
            taskTitle: widget.taskTitle,
            stakeAmountCents: widget.stakeAmountCents,
            charityName: widget.charityName,
            deadline: widget.deadline,
            onLock: _performLock,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}
