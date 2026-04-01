import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import 'group_commitment_review_screen.dart';

/// Proposal screen for initiating a group commitment on a shared list task.
///
/// Shown when a list member proposes a group commitment (FR29, Story 6.7).
/// Immediately calls `POST /v1/group-commitments` on mount and navigates
/// to [GroupCommitmentReviewScreen] on success.
///
class GroupCommitmentProposalScreen extends ConsumerStatefulWidget {
  const GroupCommitmentProposalScreen({
    super.key,
    required this.listId,
    required this.taskId,
  });

  final String listId;
  final String taskId;

  @override
  ConsumerState<GroupCommitmentProposalScreen> createState() =>
      _GroupCommitmentProposalScreenState();
}

class _GroupCommitmentProposalScreenState
    extends ConsumerState<GroupCommitmentProposalScreen> {
  @override
  void initState() {
    super.initState();
    _proposeCommitment();
  }

  Future<void> _proposeCommitment() async {
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final commitment = await repository.proposeGroupCommitment(
        listId: widget.listId,
        taskId: widget.taskId,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CupertinoPageRoute<void>(
          builder: (_) => GroupCommitmentReviewScreen(commitment: commitment),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(AppStrings.dialogErrorTitle),
          content: const Text(AppStrings.groupCommitmentProposeError),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.actionOk),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(AppStrings.groupCommitmentProposalTitle),
      ),
      backgroundColor: colors.surfacePrimary,
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
