import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../tasks/presentation/widgets/task_edit_inline.dart';
import '../../tasks/presentation/widgets/task_row.dart';
import '../../prediction/presentation/widgets/prediction_badge_async.dart';
import '../../templates/presentation/templates_provider.dart';
import '../domain/section.dart';
import 'lists_provider.dart';
import 'sections_provider.dart';
import 'widgets/bulk_actions_bar.dart';
import 'widgets/section_widget.dart';
import 'widgets/share_list_sheet.dart';

/// Shows list title, sections (expandable, nested), and tasks.
///
/// Supports "Show archived" toggle, inline editing, and drag-to-reorder.
class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({required this.listId, super.key});

  final String listId;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  bool _showArchived = false;
  Task? _editingTask;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final listsState = ref.watch(listsProvider);
    final tasksState =
        ref.watch(tasksProvider(listId: widget.listId));
    final sectionsState =
        ref.watch(sectionsProvider(widget.listId));

    final list = listsState.value?.where((l) => l.id == widget.listId).firstOrNull;
    final allTasks = tasksState.value ?? [];
    final allSections = sectionsState.value ?? [];

    // Filter tasks based on archived toggle
    final visibleTasks = _showArchived
        ? allTasks
        : allTasks.where((t) => t.archivedAt == null).toList();

    // Root-level tasks (no section)
    final rootTasks =
        visibleTasks.where((t) => t.sectionId == null).toList();

    // Root-level sections (no parent)
    final rootSections =
        allSections.where((s) => s.parentSectionId == null).toList();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: _isMultiSelectMode
            ? Text(AppStrings.bulkSelectCount
                .replaceAll('{count}', '${_selectedTaskIds.length}'))
            : Text(list?.title ?? AppStrings.listDetailTitle),
        leading: _isMultiSelectMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedTaskIds.clear();
                  });
                },
                child: Text(
                  AppStrings.actionCancel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.accentPrimary,
                      ),
                ),
              )
            : null,
        trailing: _isMultiSelectMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() => _showArchived = !_showArchived);
                    },
                    child: Text(
                      _showArchived
                          ? AppStrings.hideArchived
                          : AppStrings.showArchived,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.accentPrimary,
                          ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showMoreActions(context, list),
                    child: Icon(
                      CupertinoIcons.ellipsis_circle,
                      color: colors.accentPrimary,
                    ),
                  ),
                ],
              ),
      ),
      child: SafeArea(
        child: _editingTask != null
            ? TaskEditInline(
                task: _editingTask!,
                onDone: () => setState(() => _editingTask = null),
              )
            : _buildListContent(
                context, rootTasks, rootSections, visibleTasks, allSections),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    List<Task> rootTasks,
    List<Section> rootSections,
    List<Task> allTasks,
    List<Section> allSections,
  ) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Column(
      children: [
        // List-level prediction badge — placed above sections/tasks content
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ListPredictionBadge(listId: widget.listId),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: _onReorder,
            children: [
              // Root tasks
              for (final task in rootTasks)
                GestureDetector(
                  key: ValueKey(task.id),
                  onLongPress: () => _enterMultiSelect(task.id),
                  child: TaskRow(
                    task: task,
                    isMultiSelectMode: _isMultiSelectMode,
                    isSelected: _selectedTaskIds.contains(task.id),
                    onSelectionToggle: () => _toggleSelection(task.id),
                    onTap: _isMultiSelectMode
                        ? () => _toggleSelection(task.id)
                        : () => _onTaskTap(task),
                    onArchive: () => _archiveTask(task.id),
                  ),
                ),

              // Sections with their tasks
              for (final section in rootSections)
                SectionWidget(
                  key: ValueKey('section-${section.id}'),
                  section: section,
                  tasks: allTasks
                      .where((t) => t.sectionId == section.id)
                      .toList(),
                  childSections: allSections
                      .where((s) => s.parentSectionId == section.id)
                      .toList(),
                  allTasks: allTasks,
                  allSections: allSections,
                  onTaskTap: (task) =>
                      setState(() => _editingTask = task),
                  onArchiveTask: (task) => _archiveTask(task.id),
                  onSaveAsTemplate: (section) =>
                      _showSaveTemplateDialog(
                        context,
                        section.title,
                        'section',
                        section.id,
                      ),
                ),
            ],
          ),
        ),

        // Bottom action bar — switches between add actions and bulk actions
        if (_isMultiSelectMode)
          BulkActionsBar(
            selectedCount: _selectedTaskIds.length,
            onReschedule: (dueDate) => _bulkReschedule(dueDate),
            onComplete: _bulkComplete,
            onDelete: _bulkDelete,
          )
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    onPressed: () {
                      // TODO: show add task form for this list
                    },
                    child: Text(
                      AppStrings.addTaskInList,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.accentPrimary,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    onPressed: () {
                      // TODO: show add section form
                    },
                    child: Text(
                      AppStrings.addSectionInList,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.accentPrimary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onTaskTap(Task task) {
    // macOS: Cmd+click toggles selection without entering a dedicated mode
    if (Platform.isMacOS &&
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta)) {
      if (!_isMultiSelectMode) {
        _enterMultiSelect(task.id);
      } else {
        _toggleSelection(task.id);
      }
      return;
    }
    setState(() => _editingTask = task);
  }

  void _enterMultiSelect(String taskId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTaskIds.add(taskId);
    });
  }

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  Future<void> _bulkReschedule(String dueDate) async {
    final ids = _selectedTaskIds.toList();
    try {
      await ref
          .read(tasksProvider(listId: widget.listId).notifier)
          .bulkReschedule(ids, dueDate);
    } catch (_) {
      // Error handling deferred to real implementation
    }
    setState(() {
      _isMultiSelectMode = false;
      _selectedTaskIds.clear();
    });
  }

  Future<void> _bulkComplete() async {
    final ids = _selectedTaskIds.toList();
    try {
      await ref
          .read(tasksProvider(listId: widget.listId).notifier)
          .bulkComplete(ids);
    } catch (_) {
      // Error handling deferred to real implementation
    }
    setState(() {
      _isMultiSelectMode = false;
      _selectedTaskIds.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedTaskIds.toList();
    try {
      await ref
          .read(tasksProvider(listId: widget.listId).notifier)
          .bulkDelete(ids);
    } catch (_) {
      // Error handling deferred to real implementation
    }
    setState(() {
      _isMultiSelectMode = false;
      _selectedTaskIds.clear();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    final tasksState =
        ref.read(tasksProvider(listId: widget.listId));
    final tasks = tasksState.value ?? [];
    if (oldIndex < tasks.length) {
      final task = tasks[oldIndex];
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      ref
          .read(tasksProvider(listId: widget.listId).notifier)
          .reorderTask(task.id, adjustedIndex);
    }
  }

  void _archiveTask(String taskId) {
    ref
        .read(tasksProvider(listId: widget.listId).notifier)
        .archiveTask(taskId);
  }

  void _showMoreActions(BuildContext context, dynamic list) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showShareSheet(context, list);
            },
            child: const Text(AppStrings.shareListAction),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showSaveTemplateDialog(
                context,
                list?.title ?? '',
                'list',
                widget.listId,
              );
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

  void _showShareSheet(BuildContext context, dynamic list) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareListSheet(
        listId: widget.listId,
        listTitle: list?.title ?? '',
      ),
    );
  }

  void _showSaveTemplateDialog(
    BuildContext context,
    String defaultName,
    String sourceType,
    String sourceId,
  ) {
    final controller = TextEditingController(
        text: '$defaultName${AppStrings.templateNameSuffix}');
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.templateSaveDialogTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: CupertinoTextField(
            controller: controller,
            placeholder: AppStrings.templateNamePlaceholder,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(templatesProvider.notifier).createTemplate(
                      title: controller.text.trim(),
                      sourceType: sourceType,
                      sourceId: sourceId,
                    );
              } catch (_) {
                // Error handling deferred to real implementation
              }
            },
            child: const Text(AppStrings.actionDone),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}
