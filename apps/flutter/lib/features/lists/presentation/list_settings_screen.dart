import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/lists_repository.dart';
import '../data/sharing_repository.dart';
import 'lists_provider.dart';

/// List Settings screen — configure assignment strategy for a shared list.
///
/// Allows the list owner to select a task assignment strategy (FR17) and
/// trigger auto-assignment for all unassigned tasks (FR18).
class ListSettingsScreen extends ConsumerStatefulWidget {
  const ListSettingsScreen({required this.listId, super.key});

  final String listId;

  @override
  ConsumerState<ListSettingsScreen> createState() => _ListSettingsScreenState();
}

class _ListSettingsScreenState extends ConsumerState<ListSettingsScreen> {
  bool _isUpdatingStrategy = false;
  bool _isAutoAssigning = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final listsState = ref.watch(listsProvider);
    final list = listsState.value?.where((l) => l.id == widget.listId).firstOrNull;

    if (listsState.isLoading || list == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final currentStrategy = list.assignmentStrategy;

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
          ],
        ),
      ),
    );
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
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
