import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/lists_repository.dart';
import '../data/sharing_repository.dart';
import '../domain/list_member.dart';
import 'list_members_provider.dart'; // exports listMembersProvider
import 'lists_provider.dart';

/// List Settings screen — configure assignment strategy for a shared list.
///
/// Allows the list owner to select a task assignment strategy (FR17) and
/// trigger auto-assignment for all unassigned tasks (FR18).
/// Also shows Members section for managing list membership (FR62, FR75).
class ListSettingsScreen extends ConsumerStatefulWidget {
  const ListSettingsScreen({required this.listId, super.key});

  final String listId;

  @override
  ConsumerState<ListSettingsScreen> createState() => _ListSettingsScreenState();
}

class _ListSettingsScreenState extends ConsumerState<ListSettingsScreen> {
  bool _isUpdatingStrategy = false;
  bool _isAutoAssigning = false;
  bool _isUpdatingAccountability = false;
  bool _isManagingMember = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final listsState = ref.watch(listsProvider);
    final list = listsState.value?.where((l) => l.id == widget.listId).firstOrNull;

    if (listsState.isLoading || list == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final currentStrategy = list.assignmentStrategy;
    final currentProofRequirement = list.proofRequirement;

    return CupertinoPageScaffold(
      backgroundColor: colors.surfacePrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: Text(AppStrings.listSettingsTitle),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.assignmentStrategyLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Strategy options
            _buildStrategyOption(
              value: null,
              label: AppStrings.assignmentStrategyNone,
              description: null,
              currentStrategy: currentStrategy,
              colors: colors,
            ),
            _buildStrategyOption(
              value: 'round-robin',
              label: AppStrings.assignmentStrategyRoundRobin,
              description: AppStrings.assignmentStrategyRoundRobinDesc,
              currentStrategy: currentStrategy,
              colors: colors,
            ),
            _buildStrategyOption(
              value: 'least-busy',
              label: AppStrings.assignmentStrategyLeastBusy,
              description: AppStrings.assignmentStrategyLeastBusyDesc,
              currentStrategy: currentStrategy,
              colors: colors,
            ),
            _buildStrategyOption(
              value: 'ai-assisted',
              label: AppStrings.assignmentStrategyAiAssisted,
              description: AppStrings.assignmentStrategyAiAssistedDesc,
              currentStrategy: currentStrategy,
              colors: colors,
            ),
            const SizedBox(height: 32),
            // Accountability section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.accountabilitySettingsLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Accountability options
            _buildAccountabilityOption(
              value: null,
              label: AppStrings.accountabilityNone,
              description: AppStrings.accountabilityNoneDesc,
              currentProofRequirement: currentProofRequirement,
              colors: colors,
            ),
            _buildAccountabilityOption(
              value: 'photo',
              label: AppStrings.accountabilityPhoto,
              description: AppStrings.accountabilityPhotoDesc,
              currentProofRequirement: currentProofRequirement,
              colors: colors,
            ),
            _buildAccountabilityOption(
              value: 'watchMode',
              label: AppStrings.accountabilityWatchMode,
              description: AppStrings.accountabilityWatchModeDesc,
              currentProofRequirement: currentProofRequirement,
              colors: colors,
            ),
            _buildAccountabilityOption(
              value: 'healthKit',
              label: AppStrings.accountabilityHealthKit,
              description: AppStrings.accountabilityHealthKitDesc,
              currentProofRequirement: currentProofRequirement,
              colors: colors,
            ),
            const SizedBox(height: 24),
            // Auto-assign button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoButton(
                minimumSize: const Size(44, 44),
                color: currentStrategy != null
                    ? colors.accentPrimary
                    : colors.surfaceSecondary,
                onPressed: currentStrategy != null && !_isAutoAssigning
                    ? () => _triggerAutoAssign(this.context)
                    : null,
                child: _isAutoAssigning
                    ? const CupertinoActivityIndicator()
                    : Text(
                        AppStrings.assignmentAutoAssignButton,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: currentStrategy != null
                                  ? CupertinoColors.white
                                  : colors.textSecondary,
                            ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            // Members section
            _buildMembersSection(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(OnTaskColors colors) {
    final membersAsync = ref.watch(listMembersProvider(widget.listId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.membersSettingsLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 8),
        membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CupertinoActivityIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (members) => _buildMemberList(members, colors),
        ),
      ],
    );
  }

  Widget _buildMemberList(List<ListMember> members, OnTaskColors colors) {
    // TODO(impl): replace with real JWT sub from auth provider
    const currentUserId = 'd0000000-0000-4000-8000-000000000001';
    final currentMember = members.where((m) => m.userId == currentUserId).firstOrNull;
    final isCurrentUserOwner = currentMember?.role == 'owner';
    final ownerCount = members.where((m) => m.role == 'owner').length;
    final isLastOwner = isCurrentUserOwner && ownerCount == 1;

    return Column(
      children: [
        ...members.map((member) => _buildMemberRow(
              member: member,
              isCurrentUserOwner: isCurrentUserOwner,
              ownerCount: ownerCount,
              colors: colors,
            )),
        const SizedBox(height: 16),
        // Leave list button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Opacity(
            opacity: isLastOwner ? 0.5 : 1.0,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: CupertinoColors.destructiveRed,
              onPressed: isLastOwner || _isManagingMember
                  ? null
                  : () => _confirmLeaveList(this.context),
              child: Text(
                AppStrings.leaveListButton,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CupertinoColors.white,
                    ),
              ),
            ),
          ),
        ),
        if (isLastOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppStrings.leaveListLastOwnerNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMemberRow({
    required ListMember member,
    required bool isCurrentUserOwner,
    required int ownerCount,
    required OnTaskColors colors,
  }) {
    final isOwner = member.role == 'owner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.avatarInitials,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and role badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOwner ? AppStrings.memberRoleOwner : AppStrings.memberRoleMember,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOwner ? colors.accentPrimary : colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          // Management actions — only visible when current user is owner
          if (isCurrentUserOwner)
            CupertinoButton(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              onPressed: _isManagingMember
                  ? null
                  : () => _showMemberActionSheet(
                        context: this.context,
                        member: member,
                        ownerCount: ownerCount,
                        colors: colors,
                      ),
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                color: colors.textSecondary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  void _showMemberActionSheet({
    required BuildContext context,
    required ListMember member,
    required int ownerCount,
    required OnTaskColors colors,
  }) {
    final isOwner = member.role == 'owner';
    final isLastOwner = isOwner && ownerCount == 1;
    final roleActionLabel =
        isOwner ? AppStrings.memberRevokeOwner : AppStrings.memberGrantOwner;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          // Role toggle — disabled if trying to revoke the last owner
          if (!isLastOwner)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _updateMemberRole(
                  this.context,
                  member,
                  isOwner ? 'member' : 'owner',
                );
              },
              child: Text(roleActionLabel),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmRemoveMember(this.context, member);
            },
            child: Text(AppStrings.memberRemoveFromList),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  Future<void> _updateMemberRole(
    BuildContext context,
    ListMember member,
    String newRole,
  ) async {
    if (_isManagingMember) return;
    setState(() => _isManagingMember = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.updateMemberRole(widget.listId, member.userId, newRole);
      ref.invalidate(listMembersProvider(widget.listId));
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.memberManagementError);
    } finally {
      if (mounted) setState(() => _isManagingMember = false);
    }
  }

  Future<void> _confirmRemoveMember(BuildContext context, ListMember member) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.removeMemberConfirmTitle),
        content: Text(AppStrings.removeMemberConfirmMessage),
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
    if (_isManagingMember) return;
    setState(() => _isManagingMember = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.removeMember(widget.listId, member.userId);
      ref.invalidate(listMembersProvider(widget.listId));
      ref.invalidate(listsProvider);
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.memberManagementError);
    } finally {
      if (mounted) setState(() => _isManagingMember = false);
    }
  }

  Future<void> _confirmLeaveList(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.leaveListConfirmTitle),
        content: Text(AppStrings.leaveListConfirmMessage),
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
    if (_isManagingMember) return;
    setState(() => _isManagingMember = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.leaveList(widget.listId);
      if (!mounted) return;
      context.go('/lists');
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.leaveListError);
      if (mounted) setState(() => _isManagingMember = false);
    }
  }

  Widget _buildStrategyOption({
    required String? value,
    required String label,
    required String? description,
    required String? currentStrategy,
    required OnTaskColors colors,
  }) {
    final isSelected = currentStrategy == value;

    return GestureDetector(
      onTap: _isUpdatingStrategy ? null : () => _updateStrategy(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isUpdatingStrategy && isSelected)
              const CupertinoActivityIndicator()
            else
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: isSelected ? colors.accentPrimary : colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountabilityOption({
    required String? value,
    required String label,
    required String? description,
    required String? currentProofRequirement,
    required OnTaskColors colors,
  }) {
    final isSelected = currentProofRequirement == value;

    return GestureDetector(
      onTap: _isUpdatingAccountability ? null : () => _updateAccountability(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isUpdatingAccountability && isSelected)
              const CupertinoActivityIndicator()
            else
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 22,
                color: isSelected ? colors.accentPrimary : colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAccountability(BuildContext context, String? proofRequirement) async {
    if (_isUpdatingAccountability) return;
    setState(() => _isUpdatingAccountability = true);
    try {
      final repo = ref.read(listsRepositoryProvider);
      await repo.updateListAccountability(widget.listId, proofRequirement);
      ref.invalidate(listsProvider);
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.accountabilityUpdateError);
    } finally {
      if (mounted) setState(() => _isUpdatingAccountability = false);
    }
  }

  Future<void> _updateStrategy(BuildContext context, String? strategy) async {
    if (_isUpdatingStrategy) return;
    setState(() => _isUpdatingStrategy = true);
    try {
      final repo = ref.read(listsRepositoryProvider);
      await repo.updateAssignmentStrategy(widget.listId, strategy);
      ref.invalidate(listsProvider);
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.assignmentStrategyUpdateError);
    } finally {
      if (mounted) setState(() => _isUpdatingStrategy = false);
    }
  }

  Future<void> _triggerAutoAssign(BuildContext context) async {
    if (_isAutoAssigning) return;
    setState(() => _isAutoAssigning = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      final result = await repo.autoAssign(widget.listId);
      final count = result['assigned'] as int? ?? 0;
      if (!mounted) return;
      _showSnackbar(
        this.context,
        AppStrings.assignmentAutoAssignSuccess.replaceAll('{count}', '$count'),
      );
    } catch (_) {
      if (!mounted) return;
      _showError(this.context, AppStrings.assignmentStrategyUpdateError);
    } finally {
      if (mounted) setState(() => _isAutoAssigning = false);
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.dialogErrorTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppStrings.actionOk),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
