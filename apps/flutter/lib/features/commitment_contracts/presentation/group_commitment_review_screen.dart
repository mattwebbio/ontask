import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/group_commitment.dart';
import 'widgets/stake_slider_widget.dart';

/// Review screen for a group commitment arrangement.
///
/// Shows all members' approval statuses and stakes. The current user can
/// approve the commitment and set their individual stake amount.
/// After all members approve, shows the pool mode opt-in section (FR30).
///
/// Pool mode opt-in is separate from approval — a member must explicitly
/// opt in and is NOT automatically enrolled when they approve (FR30, Story 6.7).
class GroupCommitmentReviewScreen extends ConsumerStatefulWidget {
  const GroupCommitmentReviewScreen({
    super.key,
    required this.commitment,
  });

  final GroupCommitment commitment;

  @override
  ConsumerState<GroupCommitmentReviewScreen> createState() =>
      _GroupCommitmentReviewScreenState();
}

class _GroupCommitmentReviewScreenState
    extends ConsumerState<GroupCommitmentReviewScreen> {
  bool _isLoading = false;
  late GroupCommitment _commitment;
  int _stakeAmountCents = 500; // default minimum stake ($5)
  bool _poolModeOptIn = false;

  @override
  void initState() {
    super.initState();
    _commitment = widget.commitment;
  }

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.approveGroupCommitment(
        _commitment.id,
        stakeAmountCents: _stakeAmountCents,
      );
      if (!mounted) return;
      final refreshed = await repository.getGroupCommitment(_commitment.id);
      if (!mounted) return;
      setState(() {
        _commitment = refreshed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(AppStrings.dialogErrorTitle),
          content: const Text(AppStrings.groupCommitmentApproveError),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.actionOk),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _togglePoolMode(bool value) async {
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.setPoolModeOptIn(
        _commitment.id,
        optIn: value,
      );
      if (!mounted) return;
      setState(() => _poolModeOptIn = value);
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(AppStrings.dialogErrorTitle),
          content: const Text(AppStrings.poolModeOptInError),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.actionOk),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    final approvedCount =
        _commitment.members.where((m) => m.approved).length;
    final totalCount = _commitment.members.length;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(AppStrings.groupCommitmentReviewTitle),
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // ── Status header ─────────────────────────────────────
                  _StatusHeader(
                    status: _commitment.status,
                    approvedCount: approvedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Member list ───────────────────────────────────────
                  if (_commitment.members.isEmpty)
                    const Center(
                      child: Text(AppStrings.groupCommitmentPendingStatus),
                    )
                  else
                    ..._commitment.members.map(
                      (member) => _MemberRow(
                        member: member,
                        isActive: _commitment.isActive,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Current user approve section ──────────────────────
                  if (_commitment.isPending) ...[
                    StakeSliderWidget(
                      stakeAmountCents: _stakeAmountCents,
                      onChanged: (cents) =>
                          setState(() => _stakeAmountCents = cents ?? 500),
                      onConfirm: null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CupertinoButton.filled(
                      minimumSize: const Size(44, 44),
                      onPressed: _isLoading ? null : _approve,
                      child:
                          const Text(AppStrings.groupCommitmentApproveButton),
                    ),
                  ],

                  // ── Pool mode section (only when active) ──────────────
                  if (_commitment.isActive) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _PoolModeSection(
                      poolModeOptIn: _poolModeOptIn,
                      onToggle: _togglePoolMode,
                      members: _commitment.members,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Status Header ─────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.status,
    required this.approvedCount,
    required this.totalCount,
  });

  final String status;
  final int approvedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status == 'active'
        ? AppStrings.groupCommitmentActiveStatus
        : AppStrings.groupCommitmentPendingStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          statusLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (totalCount > 0)
          Text(
            '$approvedCount/$totalCount ${AppStrings.groupCommitmentMembersApprovedLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }
}

// ── Member Row ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isActive,
  });

  final GroupCommitmentMember member;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final stakeLabel = member.stakeAmountCents != null
        ? '\$${(member.stakeAmountCents! / 100).toStringAsFixed(2)}'
        : 'Not set';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Avatar initials placeholder
          CircleAvatar(
            radius: 18,
            child: Text(
              member.userId.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userId,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  stakeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (member.approved)
            const Icon(CupertinoIcons.checkmark_circle_fill, size: 20)
          else
            const Icon(CupertinoIcons.clock, size: 20),
          if (isActive) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              member.poolModeOptIn
                  ? CupertinoIcons.person_2_fill
                  : CupertinoIcons.person_2,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pool Mode Section ─────────────────────────────────────────────────────────

class _PoolModeSection extends StatelessWidget {
  const _PoolModeSection({
    required this.poolModeOptIn,
    required this.onToggle,
    required this.members,
  });

  final bool poolModeOptIn;
  final ValueChanged<bool> onToggle;
  final List<GroupCommitmentMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.poolModeSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Disclosure shown BEFORE the toggle (required by UX spec)
        Text(
          AppStrings.poolModeDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.poolModeToggleLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            CupertinoSwitch(
              value: poolModeOptIn,
              onChanged: onToggle,
            ),
          ],
        ),
      ],
    );
  }
}
