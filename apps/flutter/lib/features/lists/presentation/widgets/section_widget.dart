import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../prediction/presentation/widgets/prediction_badge_async.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/widgets/task_row.dart';
import '../../data/sections_repository.dart';
import '../../domain/section.dart';
import '../sections_provider.dart';

/// Renders a section header with its tasks.
///
/// Supports nested sub-sections rendered recursively.
/// Shows "Add task" and "Add section" affordances.
/// Long-press on the section header to save as template.
/// Tap the trailing settings icon to set the section-level proof requirement.
class SectionWidget extends ConsumerStatefulWidget {
  const SectionWidget({
    required this.section,
    required this.tasks,
    this.childSections = const [],
    this.allTasks = const [],
    this.allSections = const [],
    this.depth = 0,
    this.onAddTask,
    this.onAddSection,
    this.onTaskTap,
    this.onArchiveTask,
    this.onSaveAsTemplate,
    super.key,
  });

  final Section section;
  final List<Task> tasks;
  final List<Section> childSections;
  final List<Task> allTasks;
  final List<Section> allSections;
  final int depth;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddSection;
  final void Function(Task task)? onTaskTap;
  final void Function(Task task)? onArchiveTask;
  final void Function(Section section)? onSaveAsTemplate;

  @override
  ConsumerState<SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends ConsumerState<SectionWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          onLongPress: () => _showSectionActions(context),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg + (widget.depth * AppSpacing.lg),
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.section.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: SectionPredictionBadge(sectionId: widget.section.id),
                ),
                // Settings icon: opens section accountability / action sheet
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () => _showSectionSettings(context),
                  child: Icon(
                    CupertinoIcons.ellipsis_circle,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isExpanded) ...[
          // Tasks in this section
          ...widget.tasks.map(
            (task) => TaskRow(
              task: task,
              onTap: () => widget.onTaskTap?.call(task),
              onArchive: () => widget.onArchiveTask?.call(task),
            ),
          ),

          // Nested child sections (recursive)
          ...widget.childSections.map((childSection) {
            final childTasks = widget.allTasks
                .where((t) => t.sectionId == childSection.id)
                .toList();
            final grandchildSections = widget.allSections
                .where((s) => s.parentSectionId == childSection.id)
                .toList();
            return SectionWidget(
              section: childSection,
              tasks: childTasks,
              childSections: grandchildSections,
              allTasks: widget.allTasks,
              allSections: widget.allSections,
              depth: widget.depth + 1,
              onAddTask: widget.onAddTask,
              onAddSection: widget.onAddSection,
              onTaskTap: widget.onTaskTap,
              onArchiveTask: widget.onArchiveTask,
              onSaveAsTemplate: widget.onSaveAsTemplate,
            );
          }),

          // Action affordances
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl + (widget.depth * AppSpacing.lg),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  onPressed: widget.onAddTask,
                  child: Text(
                    AppStrings.addTaskInList,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.accentPrimary,
                        ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  onPressed: widget.onAddSection,
                  child: Text(
                    AppStrings.addSectionInList,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.accentPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showSectionActions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onSaveAsTemplate?.call(widget.section);
            },
            child: const Text(AppStrings.templateSaveAsTemplate),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  /// Opens the section settings action sheet with options for proof requirement,
  /// rename, and delete.
  void _showSectionSettings(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.section.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showProofRequirementPicker(context);
            },
            child: const Text(AppStrings.accountabilitySettingsLabel),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onSaveAsTemplate?.call(widget.section);
            },
            child: const Text(AppStrings.templateSaveAsTemplate),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  /// Shows a picker for setting the section-level proof requirement.
  void _showProofRequirementPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(AppStrings.accountabilitySettingsLabel),
        actions: [
          _buildProofRequirementOption(ctx, null, AppStrings.accountabilityNone),
          _buildProofRequirementOption(ctx, 'photo', AppStrings.accountabilityPhoto),
          _buildProofRequirementOption(ctx, 'watchMode', AppStrings.accountabilityWatchMode),
          _buildProofRequirementOption(ctx, 'healthKit', AppStrings.accountabilityHealthKit),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _buildProofRequirementOption(
    BuildContext ctx,
    String? value,
    String label,
  ) {
    final isSelected = widget.section.proofRequirement == value;
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.of(ctx).pop();
        _updateSectionAccountability(value);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.checkmark, size: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _updateSectionAccountability(String? proofRequirement) async {
    try {
      final repo = ref.read(sectionsRepositoryProvider);
      await repo.updateSectionAccountability(widget.section.id, proofRequirement);
      ref.invalidate(sectionsProvider(widget.section.listId));
    } catch (_) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text(AppStrings.accountabilityUpdateError),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
          ],
        ),
      );
    }
  }
}
